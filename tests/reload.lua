-- Real legacy lspconfig setup/reload regression; requires LSPCONFIG_PATH.
vim.opt.runtimepath:prepend(vim.fn.getcwd())
assert(vim.env.LSPCONFIG_PATH, "set LSPCONFIG_PATH to nvim-lspconfig v1.8.0")
vim.opt.runtimepath:prepend(vim.env.LSPCONFIG_PATH)
vim.cmd("runtime plugin/lspconfig.lua")
vim.cmd("filetype on")
local tmp = vim.fn.tempname()
local buffers = {}
for _, name in ipairs({ "one", "two" }) do
  local root = tmp .. "/" .. name
  vim.fn.mkdir(root, "p")
  vim.fn.writefile({ "[meta]", 'name = "Reload"' }, root .. "/info.toml")
  vim.fn.writefile({ "void Main() {}" }, root .. "/Main.as")
  vim.cmd("edit " .. vim.fn.fnameescape(root .. "/Main.as"))
  table.insert(buffers, { buffer = vim.api.nvim_get_current_buf(), root = root })
end
local function clients_ready()
  for _, item in ipairs(buffers) do
    local clients = vim.lsp.get_clients({ bufnr = item.buffer, name = "openplanet" })
    if #clients ~= 1 or not clients[1].initialized then return false end
  end
  return true
end
local setup = function() require("openplanet").setup({ server_path = vim.env.OPENPLANET_LSP }) end
setup()
assert(vim.wait(20000, clients_ready, 50), "initial clients")
local count = 0
for _, stop_first in ipairs({ false, true }) do
  if stop_first then
    for _, client in ipairs(vim.lsp.get_clients({ name = "openplanet" })) do client.stop(true) end
    assert(vim.wait(5000, function() return #vim.lsp.get_clients({ name = "openplanet" }) == 0 end, 20), "stopped clients")
  end
  setup()
  assert(vim.wait(20000, clients_ready, 50), "reload did not reattach both buffers")
  local ids = {}
  for _, item in ipairs(buffers) do
    local client = vim.lsp.get_clients({ bufnr = item.buffer, name = "openplanet" })[1]
    assert(client.config.root_dir == item.root, "reload reused wrong root")
    ids[client.id] = true
    count = count + 1
  end
  assert(vim.tbl_count(ids) == 2, "reload merged distinct roots")
  count = count + 1
end
for _, client in ipairs(vim.lsp.get_clients({ name = "openplanet" })) do client.stop(true) end
vim.fn.delete(tmp, "rf")
print("PASS " .. count .. " legacy setup/reload checks")
