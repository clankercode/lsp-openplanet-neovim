-- Run with: nvim --headless -u NONE -l tests/live.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())
if vim.env.LSPCONFIG_PATH then
  vim.opt.runtimepath:prepend(vim.env.LSPCONFIG_PATH)
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
vim.wait(400, function() return false end, 50)
check("ordinary TOML does not attach", #vim.lsp.get_clients({ bufnr = 0, name = "openplanet" }) == 0)
vim.fn.mkdir("artifacts", "p")
vim.fn.writefile({ vim.json.encode(report) }, "artifacts/live.json")
if vim.fn.has("nvim-0.11") == 1 then client:stop(true) else client.stop(true) end
wait_for("server stopped", function() return vim.fn.has("nvim-0.11") == 1 and client:is_stopped() or client.is_stopped() end)
print("PASS " .. #report.checks .. " live editor checks; artifacts/live.json")
