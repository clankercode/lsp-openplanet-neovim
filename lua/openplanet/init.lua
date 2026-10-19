-- SPDX-License-Identifier: Unlicense OR CC0-1.0
local M = {}

local function root_for(path)
  if path == "" then
    return nil
  end
  local name = vim.fs.basename(path)
  if name ~= "info.toml" and not path:match("%.as$") then
    return nil
  end
  -- Walk explicitly: Neovim 0.11+ treats a flat marker list as priority
  -- tiers rather than equal-priority markers at each ancestor.
  local dir = vim.fs.dirname(path)
  while dir do
    if (vim.uv or vim.loop).fs_stat(dir .. "/info.toml")
      or (vim.uv or vim.loop).fs_stat(dir .. "/.openplanet-lsp.toml") then
      return dir
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then break end
    dir = parent
  end
  return vim.fs.dirname(path)
end

---Build a native vim.lsp configuration without starting a server.
---@param opts? table
---@return table
function M.config(opts)
  opts = opts or {}
  local executable = opts.server_path and vim.fn.expand(opts.server_path) or "openplanet-lsp"
  if opts.server_path and (executable == "" or vim.fn.executable(executable) ~= 1) then
    error("openplanet: server_path is not executable: " .. executable)
  end
  return {
    cmd = { executable, "--lsp" },
    filetypes = { "angelscript", "toml" },
    root_dir = function(bufnr, on_dir)
      local root = root_for(vim.api.nvim_buf_get_name(bufnr))
      if root then
        on_dir(root)
      end
    end,
    init_options = vim.deepcopy(opts.init_options or {}),
    capabilities = opts.capabilities,
    on_attach = opts.on_attach,
    settings = opts.settings,
  }
end

---Register and enable Openplanet (Neovim 0.11+, or 0.10 with nvim-lspconfig).
---@param opts? table
function M.setup(opts)
  if vim.fn.has("nvim-0.10") ~= 1 then
    error("openplanet requires Neovim 0.10 or newer")
  end
  local config = M.config(opts)
  if vim.fn.executable(config.cmd[1]) ~= 1 then
    error("openplanet: install openplanet-lsp (npm install -g openplanet-lsp), or set server_path")
  end
  if vim.lsp.config and vim.lsp.enable then
    vim.lsp.config("openplanet", config)
    vim.lsp.enable("openplanet")
  else
    local ok, configs = pcall(require, "lspconfig.configs")
    if not ok then
      error("openplanet: Neovim 0.10 requires nvim-lspconfig (use its v1.8.0 tag)")
    end
    -- Every eligible source has a root, including standalone files. Disabling
    -- rootless startup prevents attachment to other TOML files.
    config.root_dir = root_for
    config.single_file_support = false
    configs.openplanet = configs.openplanet or { default_config = config }
    require("lspconfig").openplanet.setup(config)
    -- Legacy :LspStart installs a BufReadPost callback with a cached root,
    -- bypassing root_dir. Guard this server's manager before any attachment.
    local manager = configs.openplanet.manager
    -- v1.8.0 otherwise reuses any server with the same name across all
    -- roots. Openplanet initialization and config discovery are per-root.
    manager._start_client = function(self, bufnr, new_config, root, _, silent)
      if new_config.enabled == false then return end
      new_config.cmd_cwd = new_config.cmd_cwd or root
      local on_exit = new_config.on_exit
      new_config.on_exit = function(...)
        if self._clients[root] then self._clients[root][new_config.name] = nil end
        if on_exit then on_exit(...) end
      end
      local id = vim.lsp.start(new_config, {
        bufnr = bufnr,
        silent = silent,
        reuse_client = function(client)
          return client.name == new_config.name and client.config.root_dir == root
        end,
      })
      if id then self:_cache_client(root, vim.lsp.get_client_by_id(id)) end
    end
    local try_add = manager.try_add
    manager.try_add = function(self, bufnr, _, silent)
      bufnr = bufnr or vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_is_valid(bufnr) then
        local root = root_for(vim.api.nvim_buf_get_name(bufnr))
        if root then return try_add(self, bufnr, root, silent) end
      end
    end
  end
end

return M
