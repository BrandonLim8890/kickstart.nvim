local env = require 'env'

-- ===========================================================================
-- Constants
-- ===========================================================================

-- `typescript-language-server` resolves from $PATH on both machines: bend
-- provides it on HubSpot, Mason's PATH shim (~/.local/share/nvim/mason/bin)
-- provides it on personal.
local TS_LS_BIN = 'typescript-language-server'

local ESLINT_LSP_BIN = vim.fn.expand '~/.local/share/nvim/mason/packages/eslint-lsp/node_modules/.bin/vscode-eslint-language-server'

local STYLED_PLUGIN_PATH = '/opt/homebrew/lib/node_modules/@styled/typescript-styled-plugin'

local FORCEABSOLUTE_SCRIPT = '/Users/blim/src/misc/code-utils-master/forceabsolute-stdin.sh'

-- ===========================================================================
-- Shared helpers (used by both HubSpot and personal setups)
-- ===========================================================================

local function organise_imports()
  local clients = vim.lsp.get_clients { bufnr = 0, name = 'ts_ls' }
  if clients[1] then
    clients[1]:exec_cmd {
      command = '_typescript.organizeImports',
      arguments = { vim.api.nvim_buf_get_name(0) },
    }
  end
end

---@param opts { tsserver_path?: string }
local function configure_ts_ls(opts)
  local plugins = {}
  if vim.uv.fs_stat(STYLED_PLUGIN_PATH) then
    table.insert(plugins, { name = '@styled/typescript-styled-plugin', location = STYLED_PLUGIN_PATH })
  end

  local init_options = { hostInfo = 'neovim', plugins = plugins }
  if opts.tsserver_path then
    init_options.tsserver = { path = opts.tsserver_path }
  end

  vim.lsp.config['ts_ls'] = {
    cmd = { 'bash', '-c', 'NODE_OPTIONS="--max-old-space-size=8192" exec ' .. TS_LS_BIN .. ' --stdio' },
    filetypes = {
      'javascript',
      'javascriptreact',
      'javascript.jsx',
      'typescript',
      'typescriptreact',
      'typescript.tsx',
    },
    root_markers = { '.git' },
    on_attach = function(client)
      -- disable formatting so we can have prettier do that stuff
      client.server_capabilities.documentFormattingProvider = false
      client.server_capabilities.documentRangeFormattingProvider = false
    end,
    init_options = init_options,
  }
  vim.lsp.enable 'ts_ls'
end

local function configure_eslint()
  vim.lsp.config['eslint'] = {
    cmd = { 'bash', '-c', 'NODE_OPTIONS="--max-old-space-size=8192" exec ' .. ESLINT_LSP_BIN .. ' --stdio' },
    root_dir = function(bufnr, on_dir)
      -- Stop at the individual package boundary (tsconfig.json sits at each
      -- HubSpot package root, not inside static/) rather than walking all
      -- the way up to the monorepo yarn.lock. This prevents one ESLint server
      -- instance from owning the entire monorepo.
      local fname = vim.api.nvim_buf_get_name(bufnr)
      -- tsconfig.json is at every package root; yarn.lock is only at the monorepo root.
      -- By preferring tsconfig.json we stop at the package level.
      local package_root = vim.fs.root(bufnr, { 'tsconfig.json' })
      if not package_root then
        -- fall back for non-HubSpot projects
        package_root = vim.fs.root(bufnr, { 'yarn.lock', 'package-lock.json', '.git' }) or vim.fn.getcwd()
      end
      -- only attach if the buffer actually has an eslint config in its tree
      local has_eslint_config = vim.fs.find(
        { '.eslintrc', '.eslintrc.js', '.eslintrc.cjs', '.eslintrc.json', '.eslintrc.yaml', '.eslintrc.yml', 'eslint.config.js', 'eslint.config.mjs' },
        { path = fname, upward = true, stop = vim.fs.dirname(package_root), limit = 1, type = 'file' }
      )[1]
      if not has_eslint_config then
        return
      end
      on_dir(package_root)
    end,
  }
  vim.lsp.enable 'eslint'
end

---@param opts { tsserver_path?: string }
local function configure_typescript_environment(opts)
  vim.lsp.log.set_level 'info'
  vim.keymap.set('n', '<leader>co', organise_imports, { desc = 'Organise Imports' })
  configure_ts_ls(opts)
  configure_eslint()
end

-- ===========================================================================
-- HubSpot setup — runs inside the bend.nvim plugin `config` hook
-- ===========================================================================

local function setup_hubspot()
  local bend = require 'bend'
  bend.setup { v2 = true }

  configure_typescript_environment {
    tsserver_path = bend.getTsServerPathForCurrentFile(),
  }

  vim.keymap.set('n', '<leader>lr', function()
    vim.cmd 'BendReset'
    vim.cmd 'lsp restart'
  end, { desc = 'Bend Restart' })

  vim.keymap.set('n', '<leader>la', function()
    local bufpath = vim.api.nvim_buf_get_name(0)
    local cwd = vim.fn.getcwd()
    local relative = string.sub(bufpath, #cwd + 2)
    local segment = relative:match '^([^/]+)'
    if not segment then
      vim.notify('[BendAddDir] buffer is directly in cwd, no subdirectory to add', vim.log.levels.WARN)
      return
    end
    local abs_dir = cwd .. '/' .. segment
    vim.cmd('BendAddDir ' .. abs_dir)
    vim.cmd 'BendReset'
    vim.cmd 'lsp restart'
  end, { desc = 'Bend Add Dir' })

  vim.keymap.set('n', '<leader>cp', function()
    local view = vim.fn.winsaveview()
    vim.cmd(string.format("%%!bash %s '%s'", FORCEABSOLUTE_SCRIPT, vim.fn.expand '%:p:h'))
    vim.schedule(function()
      pcall(vim.fn.winrestview, view)
    end)
  end, { desc = 'Absolute Path' })
end

-- ===========================================================================
-- Personal setup — runs eagerly at plugin-spec eval, no plugin to install
-- ===========================================================================

local function setup_personal()
  configure_typescript_environment {}
end

-- ===========================================================================
-- Dispatch
-- ===========================================================================

if env.is_hubspot then
  return {
    {
      url = 'git@github.com:HubSpotEngineering/bend.nvim.git',
      config = setup_hubspot,
    },
  }
end

setup_personal()
return {}
