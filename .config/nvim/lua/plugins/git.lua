return {
  -- Gitsigns: gutter indicators + hunk keymaps
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gitsigns.nav_hunk 'next'
          end
        end, { desc = 'Jump to next git [c]hange' })
        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gitsigns.nav_hunk 'prev'
          end
        end, { desc = 'Jump to previous git [c]hange' })

        map('v', '<leader>hs', function()
          gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'git [s]tage hunk' })
        map('v', '<leader>hr', function()
          gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'git [r]eset hunk' })
        map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
        map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
        map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
        map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
        map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
        map('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'git preview hunk [i]nline' })
        map('n', '<leader>hb', function()
          gitsigns.blame_line { full = true }
        end, { desc = 'git [b]lame line' })
        map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
        map('n', '<leader>hD', function()
          gitsigns.diffthis '@'
        end, { desc = 'git [D]iff against last commit' })
        map('n', '<leader>hQ', function()
          gitsigns.setqflist 'all'
        end, { desc = 'git hunk [Q]uickfix (all files)' })
        map('n', '<leader>hq', gitsigns.setqflist, { desc = 'git hunk [q]uickfix (this file)' })
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git [b]lame line' })
        map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = '[T]oggle git [w]ord diff' })
        map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
      end,
    },
  },

  -- Neogit: Magit-style git UI
  {
    'NeogitOrg/neogit',
    commit = '5a7fca17', -- pinned: commits after this break nvim 0.12 (E474 on 'modified')
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'sindrets/diffview.nvim',
        opts = {
          default_args = { DiffviewOpen = { '--imply-local' } },
          keymaps = {
            view = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } } },
            file_panel = { { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } } },
            file_history_panel = {
              { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
              {
                'n',
                'vc',
                function()
                  local lib = require 'diffview.lib'
                  local view = lib.get_current_view()
                  if view then
                    local entry = view.panel:get_item_at_cursor()
                    if entry and entry.commit then
                      local hash = entry.commit.hash
                      vim.cmd('DiffviewOpen ' .. hash .. '^!')
                      vim.notify('Opening full diff for commit: ' .. hash:sub(1, 7), vim.log.levels.INFO)
                    else
                      vim.notify('No commit found at cursor', vim.log.levels.WARN)
                    end
                  end
                end,
                { desc = 'View full commit diff (all files)' },
              },
            },
          },
        },
      },
      'nvim-telescope/telescope.nvim',
    },
    config = function()
      local lspconfig_util = require 'lspconfig.util'
      local get_git_root = lspconfig_util.root_pattern '.git'

      vim.keymap.set('n', '<leader>gs', function()
        local buffer_path = vim.api.nvim_buf_get_name(0)
        local git_root = get_git_root(buffer_path)
        require('neogit').open { cwd = git_root, kind = 'split_below_all' }
      end)
      vim.keymap.set('n', 'gh', '<cmd>diffget //2<CR>')
      vim.keymap.set('n', 'gl', '<cmd>diffget //3<CR>')
      vim.keymap.set('n', '<leader>hh', '<cmd>DiffviewFileHistory --follow %<cr>', { desc = 'Git File History' })

      require('neogit').setup {
        auto_refresh = true,
        auto_show_console_on = 'error',
        highlight = {
          italic = true,
          bold = true,
          underline = true,
          red = '#BF616A',
          orange = '#D08770',
          yellow = '#EBCB8B',
          green = '#A3BE8C',
          cyan = '#8FBCBB',
          blue = '#81A1C1',
          purple = '#88C0D0',
          bg0 = '#1E222A',
          bg1 = '#242933',
          bg2 = '#2E3440',
          bg3 = '#3B4252',
        },
      }
    end,
  },

  -- gh.nvim: GitHub PR/issue integration
  {
    'ldelossa/gh.nvim',
    dependencies = {
      {
        'ldelossa/litee.nvim',
        config = function()
          require('litee.lib').setup()
        end,
      },
    },
    config = function()
      require('litee.gh').setup()

      local lspconfig_util = require 'lspconfig.util'
      local get_git_root = lspconfig_util.root_pattern '.git'
      local Path = require 'plenary.path'

      local function resolve_repo_context()
        local filepath = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ':p')
        if filepath == '' then
          vim.notify('Buffer has no file path', vim.log.levels.WARN)
          return nil, nil
        end
        local git_root = get_git_root(filepath)
        if not git_root then
          vim.notify('Current buffer is not inside a git repo', vim.log.levels.WARN)
          return nil, nil
        end
        local rel_path = Path:new(filepath):make_relative(git_root)
        return git_root, rel_path
      end

      local function resolve_repo_root()
        local git_root, _ = resolve_repo_context()
        return git_root
      end

      local function go_to_github(path, cwd)
        vim.fn.jobstart({ 'gh', 'browse', path }, { cwd = cwd })
      end

      local function copy_github_url(path, cwd)
        local result = vim.system({ 'gh', 'browse', '--no-browser', path }, { cwd = cwd }):wait()
        local url = (result.stdout or ''):gsub('%s+$', '')
        vim.fn.setreg('+', url)
        vim.notify('Copied to clipboard: ' .. url, vim.log.levels.INFO)
      end

      local function with_context(fn)
        return function()
          local git_root, rel_path = resolve_repo_context()
          if git_root then
            fn(git_root, rel_path)
          end
        end
      end

      local function with_visual_lines(fn)
        return function()
          local git_root, rel_path = resolve_repo_context()
          if not git_root then
            return
          end
          local cursor_line = vim.fn.getpos('.')[2]
          local other_end = vim.fn.getpos('v')[2]
          if cursor_line > other_end then
            rel_path = rel_path .. ':' .. other_end .. '-' .. cursor_line
          elseif cursor_line < other_end then
            rel_path = rel_path .. ':' .. cursor_line .. '-' .. other_end
          else
            rel_path = rel_path .. ':' .. other_end
          end
          fn(git_root, rel_path)
        end
      end

      vim.keymap.set('n', '<leader>ghb', with_context(go_to_github), { desc = 'Go to file in GitHub' })
      vim.keymap.set('v', '<leader>ghb', with_visual_lines(go_to_github), { desc = 'Go to selection in GitHub' })
      vim.keymap.set('n', '<leader>ghy', with_context(copy_github_url), { desc = 'Copy GitHub link to file' })
      vim.keymap.set('v', '<leader>ghy', with_visual_lines(copy_github_url), { desc = 'Copy GitHub link to selection' })

      vim.keymap.set('n', '<leader>ghp', function()
        local git_root = resolve_repo_root()
        if not git_root then
          return
        end
        vim.fn.jobstart({ 'gh', 'pr', 'view', '--web' }, {
          cwd = git_root,
          on_exit = function(_, exit_code)
            if exit_code ~= 0 then
              vim.fn.jobstart({ 'gh', 'pr', 'create', '--web' }, { cwd = git_root })
            end
          end,
        })
      end, { desc = 'Create or view PR on GitHub' })
    end,
  },
}
