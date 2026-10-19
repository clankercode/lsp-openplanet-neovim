vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd("filetype on")
vim.cmd("syntax enable")
local checks = 0
local function eq(expected, actual, label)
  checks = checks + 1
  assert(vim.deep_equal(expected, actual), label .. ": " .. vim.inspect(actual))
end
local function edit(path)
  vim.cmd("edit " .. vim.fn.fnameescape(path))
end
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/plugin/src", "p")
vim.fn.writefile({ "[meta]", 'name = "Unit"' }, tmp .. "/plugin/info.toml")
vim.fn.writefile({ "void Main() {}" }, tmp .. "/plugin/src/Main.as")
edit(tmp .. "/plugin/src/Main.as")
eq("angelscript", vim.bo.filetype, ".as detection")
local config = require("openplanet").config()
eq({ "openplanet-lsp", "--lsp" }, config.cmd, "stdio command")
eq({}, config.init_options, "do not override server configuration")
local root
config.root_dir(0, function(value) root = value end)
eq(tmp .. "/plugin", root, "nearest plugin root")
edit(tmp .. "/plugin/info.toml")
eq("toml", vim.bo.filetype, "manifest keeps TOML")
root = nil
config.root_dir(0, function(value) root = value end)
eq(tmp .. "/plugin", root, "manifest attaches")
edit(tmp .. "/plugin/other.toml")
root = nil
config.root_dir(0, function(value) root = value end)
eq(nil, root, "ordinary TOML never attaches")
edit(tmp .. "/single.as")
root = nil
config.root_dir(0, function(value) root = value end)
eq(tmp, root, "single-file fallback")
local explicit = require("openplanet").config({ server_path = vim.v.progpath, init_options = { defines = { "TEST" } } })
eq({ vim.v.progpath, "--lsp" }, explicit.cmd, "authoritative executable override")
eq({ defines = { "TEST" } }, explicit.init_options, "explicit snake_case options")
local ok, err = pcall(require("openplanet").config, { server_path = tmp .. "/missing" })
eq(false, ok, "invalid override fails")
assert(tostring(err):find("not executable", 1, true), tostring(err))
-- A marked parent workspace and a nearer plugin root are both supported.
vim.fn.writefile({ "" }, tmp .. "/.openplanet-lsp.toml")
vim.fn.mkdir(tmp .. "/loose/src", "p")
edit(tmp .. "/loose/src/Loose.as")
root = nil
config.root_dir(0, function(value) root = value end)
eq(tmp, root, "workspace config root")
edit(tmp .. "/plugin/src/Main.as")
root = nil
config.root_dir(0, function(value) root = value end)
eq(tmp .. "/plugin", root, "nearer plugin wins over workspace")
for _, path in ipairs({ tmp .. "/info.toml.bak", tmp .. "/config.toml", tmp .. "/foo.lua" }) do
  edit(path)
  root = nil
  config.root_dir(0, function(value) root = value end)
  eq(nil, root, "reject " .. path)
end
for _, path in ipairs({ "", tmp, tmp .. "/missing", vim.v.progpath .. "/missing" }) do
  local valid = pcall(require("openplanet").config, { server_path = path })
  eq(false, valid, "bad executable " .. path)
end
vim.fn.mkdir(tmp .. "/plugin/nested", "p")
vim.fn.writefile({ "" }, tmp .. "/plugin/nested/.openplanet-lsp.toml")
edit(tmp .. "/plugin/nested/Example.as")
root = nil
config.root_dir(0, function(value) root = value end)
eq(tmp .. "/plugin/nested", root, "nearer config wins over distant manifest")
local options = { init_options = { defines = { "ORIGINAL" } } }
local isolated = require("openplanet").config(options)
isolated.init_options.defines[1] = "CHANGED"
eq("ORIGINAL", options.init_options.defines[1], "options do not mutate caller")
edit(tmp .. "/plugin/src/Main.as")
eq("angelscript", vim.b.current_syntax, "AngelScript syntax loaded")
vim.fn.delete(tmp, "rf")
print("PASS " .. checks .. " unit checks")
