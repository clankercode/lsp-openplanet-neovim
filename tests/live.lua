-- Run with: nvim --headless -u NONE -l tests/live.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
if vim.env.LSPCONFIG_PATH then
  vim.opt.runtimepath:prepend(vim.env.LSPCONFIG_PATH)
  vim.cmd("runtime plugin/lspconfig.lua")
end
vim.cmd("filetype on")
vim.cmd("syntax enable")
local function wait_for(label, fn)
  assert(vim.wait(20000, fn, 50), "timeout: " .. label)
end
local report = { neovim = vim.version(), checks = {} }
local function check(label, value)
  assert(value, label)
  table.insert(report.checks, label)
end
require("openplanet").setup({ server_path = vim.env.OPENPLANET_LSP })
vim.cmd("edit tests/fixtures/demo/Main.as")
local source = vim.api.nvim_get_current_buf()
local client
wait_for("initialized client", function()
  client = vim.lsp.get_clients({ bufnr = source, name = "openplanet" })[1]
  return client and client.initialized
end)
check("real server attached to AngelScript", client ~= nil)
-- :LspStart installs lspconfig's cached-root BufReadPost path in 0.10.
if vim.fn.has("nvim-0.11") == 0 then
  vim.cmd("LspStart openplanet")
  vim.wait(100, function() return false end, 20)
end
report.command = client.config.cmd
report.server = client.server_info
report.root = client.config.root_dir
wait_for("server diagnostic", function() return #vim.diagnostic.get(source) > 0 end)
report.diagnostics = vim.diagnostic.get(source)
local mismatch = false
for _, d in ipairs(report.diagnostics) do
  if d.lnum == 4 and d.code == "unused-declaration" then mismatch = true end
end
check("published server diagnoses intentionally unused laps", mismatch)
local function request(method, line, character, extra)
  local params = { textDocument = { uri = vim.uri_from_bufnr(source) }, position = { line = line, character = character } }
  if extra then params = vim.tbl_extend("force", params, extra) end
  local response
  if vim.fn.has("nvim-0.11") == 1 then
    response = client:request_sync(method, params, 20000, source)
  else
    response = client.request_sync(method, params, 20000, source)
  end
  assert(response and not response.err, method .. ": " .. vim.inspect(response))
  return response.result
end
report.hover = request("textDocument/hover", 5, 12)
check("hover returns information for greeting", report.hover and report.hover.contents)
report.completion = request("textDocument/completion", 5, 12, { context = { triggerKind = 1 } })
local items = report.completion.items or report.completion
local found = false
for _, item in ipairs(items) do if item.label == "greeting" then found = true end end
check("completion includes local greeting", found)
report.definition = request("textDocument/definition", 5, 12) or vim.NIL
report.limits = { "Definition returned no location for this local variable in server 0.8.0." }
vim.cmd("edit tests/fixtures/demo/info.toml")
local manifest = vim.api.nvim_get_current_buf()
wait_for("manifest attachment", function() return #vim.lsp.get_clients({ bufnr = manifest, name = "openplanet" }) > 0 end)
check("manifest stays TOML", vim.bo.filetype == "toml")
check("manifest shares source client", vim.lsp.get_clients({ bufnr = manifest, name = "openplanet" })[1].id == client.id)
vim.cmd("edit tests/fixtures/demo/other.toml")
vim.cmd("doautocmd BufReadPost")
vim.wait(400, function() return false end, 50)
check("ordinary TOML does not attach", #vim.lsp.get_clients({ bufnr = 0, name = "openplanet" }) == 0)
-- Multiple roots must not share one server's initialization/configuration.
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/parent/nested", "p")
vim.fn.mkdir(tmp .. "/sibling", "p")
vim.fn.writefile({ "[meta]", 'name = "Parent"' }, tmp .. "/parent/info.toml")
vim.fn.writefile({ 'unused = "error"' }, tmp .. "/parent/.openplanet-lsp.toml")
vim.fn.writefile({ 'unused = "ignore"' }, tmp .. "/parent/nested/.openplanet-lsp.toml")
vim.fn.writefile({ "[meta]", 'name = "Sibling"' }, tmp .. "/sibling/info.toml")
local roots = {}
for _, directory in ipairs({ "parent", "parent/nested", "sibling" }) do
  local path = tmp .. "/" .. directory .. "/Main.as"
  vim.fn.writefile({ "void Main() { int unusedValue = 1; }" }, path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  local buffer = vim.api.nvim_get_current_buf()
  local attached
  wait_for("root " .. directory, function()
    attached = vim.lsp.get_clients({ bufnr = buffer, name = "openplanet" })[1]
    return attached and attached.initialized
  end)
  check("correct client root for " .. directory, attached.config.root_dir == tmp .. "/" .. directory)
  for _, previous in ipairs(roots) do
    check("independent client for " .. directory, previous.id ~= attached.id)
  end
  table.insert(roots, attached)
  if directory == "parent" then
    wait_for("parent unused error", function() return #vim.diagnostic.get(buffer) > 0 end)
    check("parent config sets unused error", vim.diagnostic.get(buffer)[1].severity == vim.diagnostic.severity.ERROR)
  elseif directory == "parent/nested" then
    vim.wait(600, function() return false end, 50)
    check("nested config suppresses unused", #vim.diagnostic.get(buffer) == 0)
  end
end
for _, c in ipairs(roots) do
  if vim.fn.has("nvim-0.11") == 1 then c:stop(true) else c.stop(true) end
end
vim.fn.delete(tmp, "rf")
vim.fn.mkdir("artifacts", "p")
vim.fn.writefile({ vim.json.encode(report) }, "artifacts/live.json")
if vim.fn.has("nvim-0.11") == 1 then client:stop(true) else client.stop(true) end
wait_for("server stopped", function() return vim.fn.has("nvim-0.11") == 1 and client:is_stopped() or client.is_stopped() end)
print("PASS " .. #report.checks .. " live editor checks; artifacts/live.json")
