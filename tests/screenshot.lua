vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd("filetype on")
vim.cmd("syntax enable")
vim.o.termguicolors = true
vim.o.number = true
vim.o.signcolumn = "yes"
vim.o.laststatus = 2
vim.o.statusline = "  Openplanet / Neovim   %f %= %l:%c  "
vim.cmd("colorscheme habamax")
vim.diagnostic.config({ virtual_text = false, underline = true, signs = true })
require("openplanet").setup()
vim.cmd("edit tests/fixtures/demo/Main.as")
assert(vim.wait(20000, function() return #vim.diagnostic.get(0) > 0 end, 50), "No real diagnostics received")
vim.api.nvim_win_set_cursor(0, { 5, 8 })
local _, float = vim.diagnostic.open_float(0, { scope = "line", focus = false, border = "rounded", header = "openplanet-lsp · live diagnostic", max_width = 90 })
vim.api.nvim_win_set_config(float, { relative = "editor", row = 9, col = 4 })
vim.cmd("redraw!")
vim.fn.writefile({ vim.json.encode({ diagnostics = vim.diagnostic.get(0), clients = vim.tbl_map(function(c) return { name = c.name, cmd = c.config.cmd, server = c.server_info } end, vim.lsp.get_clients({ bufnr = 0 })) }) }, "artifacts/screenshot-evidence.json")
vim.fn.writefile({ "ready" }, "artifacts/screenshot-ready")
