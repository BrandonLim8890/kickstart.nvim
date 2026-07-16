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
-- BendCheck: run `bend check` and surface errors in Trouble qflist
-- ===========================================================================

-- Returns { workspace_root, packages[] } by scanning workspace_root one level
-- deep for subdirs containing static/static_conf.json. If none found, tries
-- treating each child of workspace_root as its own workspace root and prompts
-- to pick one.
local function find_bend_packages(workspace_root)
  local packages = {}
  local handle = vim.uv.fs_scandir(workspace_root)
  if not handle then
    return packages
  end
  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if type == 'directory' then
      local marker = workspace_root .. '/' .. name .. '/static/static_conf.json'
      if vim.uv.fs_stat(marker) then
        table.insert(packages, name)
      end
    end
  end
  return packages
end

-- Finds the workspace root and packages to check, starting from start_dir.
-- If start_dir has no bend packages, scans one level deeper and prompts to pick a workspace.
-- Calls cb(workspace_root, packages) when resolved.
local function resolve_workspace(start_dir, cb)
  local packages = find_bend_packages(start_dir)
  if #packages > 0 then
    cb(start_dir, packages)
    return
  end

  -- No packages at start_dir — scan children as potential workspace roots
  local workspaces = {}
  local handle = vim.uv.fs_scandir(start_dir)
  if handle then
    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then break end
      if type == 'directory' then
        local child = start_dir .. '/' .. name
        local pkgs = find_bend_packages(child)
        if #pkgs > 0 then
          table.insert(workspaces, child)
        end
      end
    end
  end

  if #workspaces == 0 then
    vim.notify('BendCheck: no bend packages found under ' .. start_dir, vim.log.levels.WARN)
    return
  end

  if #workspaces == 1 then
    cb(workspaces[1], find_bend_packages(workspaces[1]))
    return
  end

  local display = vim.tbl_map(function(ws)
    return vim.fn.fnamemodify(ws, ':t')
  end, workspaces)

  vim.ui.select(display, { prompt = 'BendCheck: pick workspace' }, function(choice)
    if not choice then return end
    for _, ws in ipairs(workspaces) do
      if vim.fn.fnamemodify(ws, ':t') == choice then
        cb(ws, find_bend_packages(ws))
        return
      end
    end
  end)
end

-- lualine polls this to show a spinner while bend check is running
local _bend_check = require 'bend_check_state'

-- Returns the longest common directory path shared by all entries in dirs.
local function common_parent(dirs)
  if #dirs == 0 then return vim.uv.cwd() end
  if #dirs == 1 then return vim.fn.fnamemodify(dirs[1], ':h') end
  local parts = vim.split(dirs[1], '/')
  for i = 2, #dirs do
    local other = vim.split(dirs[i], '/')
    local new_len = 0
    for j = 1, math.min(#parts, #other) do
      if parts[j] == other[j] then
        new_len = j
      else
        break
      end
    end
    parts = vim.list_slice(parts, 1, new_len)
  end
  return table.concat(parts, '/')
end

-- Runs `bend fmt .` in each workspace root in parallel, calls cb when all done.
local function run_bend_fmt(workspaces, cb)
  if #workspaces == 0 then
    cb()
    return
  end
  local pending = #workspaces
  for _, ws in ipairs(workspaces) do
    vim.system({ 'bend', 'fmt', '.' }, { cwd = ws.root, text = true }, function()
      pending = pending - 1
      if pending == 0 then
        cb()
      end
    end)
  end
end

-- workspaces: list of { root: string, packages: string[] }
-- filter_workspace: only surface qflist errors from this workspace root (nil = all)
local function run_bend_check(workspaces, filter_workspace)
  local filter_name = vim.fn.fnamemodify(filter_workspace or (workspaces[1] and workspaces[1].root) or '', ':t')

  _bend_check.running = true
  _bend_check.start_time = vim.uv.hrtime()

  local function tick()
    if not _bend_check.running then
      return
    end
    require('lualine').refresh { place = { 'statusline' } }
    vim.defer_fn(tick, 200)
  end
  vim.defer_fn(tick, 200)

  -- build a map from package name -> workspace root so we can reconstruct
  -- absolute paths from the "[pkg] FAILURE" lines in bend's output
  local pkg_to_ws = {}
  local cwd = common_parent(vim.tbl_map(function(ws) return ws.root end, workspaces))
  local cmd = { 'bend', 'check' }
  for _, ws in ipairs(workspaces) do
    local ws_rel = vim.fn.fnamemodify(ws.root, ':t')
    for _, pkg in ipairs(ws.packages) do
      pkg_to_ws[pkg] = ws.root
      -- pass as repo/package so bend can find it from the common parent cwd
      table.insert(cmd, ws_rel .. '/' .. pkg)
    end
  end

  vim.system(cmd, { cwd = cwd, text = true }, function(result)
    local output = (result.stdout or '') .. (result.stderr or '')
    local items = {}
    local current_pkg = nil
    local pkg_error_count = {}
    local eslint_file = nil

    for line in output:gmatch '[^\n]+' do
      -- TypeScript errors: track which package's recap block we're in
      local pkg = line:match '^%[([^%]]+)%] FAILURE in validate%-typescript'
      if pkg then
        pkg_error_count[pkg] = (pkg_error_count[pkg] or 0) + 1
        -- errors follow the second occurrence (the recap block)
        if pkg_error_count[pkg] >= 2 then
          current_pkg = pkg
        end
      end

      -- parse: static/path/to/file.tsx(30,7): error TS2741: message
      local rel, lnum, col, msg = line:match '^(.-)%((%d+),(%d+)%): %a+ TS%d+: (.+)$'
      if rel and current_pkg then
        local ws_root = pkg_to_ws[current_pkg]
        if ws_root and (not filter_workspace or ws_root == filter_workspace) then
          table.insert(items, {
            filename = ws_root .. '/' .. current_pkg .. '/' .. rel,
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = msg,
            type = 'E',
          })
        end
      end

      -- ESLint inline lines: [~/repo run-eslint] <content>
      local eslint_content = line:match '^%[.+ run%-eslint%] ?(.*)$'
      if eslint_content then
        if eslint_content:sub(1, 1) == '/' then
          -- absolute path = new file context
          eslint_file = eslint_content
        elseif eslint_file then
          -- error detail:   line:col  error  message  rule
          local elnum, ecol, emsg = eslint_content:match '^%s+(%d+):(%d+)%s+error%s+(.-)%s+%S+%s*$'
          if elnum and (not filter_workspace or vim.startswith(eslint_file, filter_workspace)) then
            table.insert(items, {
              filename = eslint_file,
              lnum = tonumber(elnum),
              col = tonumber(ecol),
              text = emsg,
              type = 'E',
            })
          end
        end
      end
    end

    vim.schedule(function()
      _bend_check.running = false
      _bend_check.start_time = nil

      vim.fn.setqflist({}, 'r', { title = 'BendCheck', items = items })
      if #items > 0 then
        vim.notify('✗ ' .. #items .. ' error(s) in ' .. filter_name, vim.log.levels.ERROR, { title = 'BendCheck' })
        require('trouble').open 'qflist'
      else
        vim.notify('✓ No errors in ' .. filter_name, vim.log.levels.INFO, { title = 'BendCheck' })
      end
    end)
  end)
end

-- Resolves all bend_dirs into { root, packages } entries, then calls cb with the list.
local function resolve_all_workspaces(dirs, cb)
  local results = {}
  local pending = #dirs
  if pending == 0 then
    cb(results)
    return
  end
  for _, dir in ipairs(dirs) do
    resolve_workspace(dir, function(ws_root, pkgs)
      table.insert(results, { root = ws_root, packages = pkgs })
      pending = pending - 1
      if pending == 0 then
        cb(results)
      end
    end)
  end
end

local function bend_check_command()
  local bend_dirs = require 'bend_dirs'

  -- no bend_dirs configured: fall back to cwd, check everything, no filter
  if #bend_dirs == 0 then
    resolve_workspace(vim.uv.cwd(), function(ws_root, pkgs)
      local workspaces = { { root = ws_root, packages = pkgs } }
      run_bend_fmt(workspaces, function()
        run_bend_check(workspaces, ws_root)
      end)
    end)
    return
  end

  -- single repo: check it, surface all errors
  if #bend_dirs == 1 then
    resolve_workspace(bend_dirs[1], function(ws_root, pkgs)
      local workspaces = { { root = ws_root, packages = pkgs } }
      run_bend_fmt(workspaces, function()
        run_bend_check(workspaces, ws_root)
      end)
    end)
    return
  end

  -- multiple repos: resolve all workspaces, then prompt which repo's errors to show.
  -- bend check runs across ALL repos (they depend on each other), but qflist only
  -- shows errors from the selected one.
  resolve_all_workspaces(bend_dirs, function(all_workspaces)
    local buf_path = vim.api.nvim_buf_get_name(0)
    local current_workspace = nil
    for _, ws in ipairs(all_workspaces) do
      if vim.startswith(buf_path, ws.root) then
        current_workspace = ws.root
        break
      end
    end

    local display = {}
    local seen = {}
    if current_workspace then
      table.insert(display, current_workspace .. ' (current)')
      seen[current_workspace] = true
    end
    for _, ws in ipairs(all_workspaces) do
      if not seen[ws.root] then
        table.insert(display, ws.root)
        seen[ws.root] = true
      end
    end

    vim.ui.select(display, { prompt = 'BendCheck: show errors for repo' }, function(choice)
      if not choice then return end
      local filter_ws = choice:gsub(' %(current%)$', '')
      run_bend_fmt(all_workspaces, function()
        run_bend_check(all_workspaces, filter_ws)
      end)
    end)
  end)
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

  vim.lsp.enable 'bend-lsp'

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

  vim.api.nvim_create_user_command('BendCheck', bend_check_command, {})
  vim.keymap.set('n', '<leader>lc', '<cmd>BendCheck<cr>', { desc = 'Bend Check (Trouble)' })
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
