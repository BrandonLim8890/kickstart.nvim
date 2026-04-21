return {
  {
    'NeogitOrg/neogit',
    commit = '5a7fca17', -- pinned: commits after this break nvim 0.12 (E474 on 'modified' via nvim_set_option_value with scope=local)
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      {
        'sindrets/diffview.nvim', -- optional - Diff integration
        opts = {
          default_args = {
            DiffviewOpen = { '--imply-local' },
          },
          keymaps = {
            view = {
              { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
            },
            file_panel = {
              { 'n', 'q', '<cmd>DiffviewClose<cr>', { desc = 'Close diffview' } },
            },
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
      'nvim-telescope/telescope.nvim', -- optional
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
      local function go_to_github(path)
        vim.fn.jobstart { 'gh', 'browse', path }
      end

      local function copy_github_url(path)
        local url = vim.fn.system({ 'gh', 'browse', '--no-browser', path })
        url = url:gsub('%s+$', '')
        vim.fn.setreg('+', url)
        vim.notify('Copied to clipboard: ' .. url, vim.log.levels.INFO)
      end

      vim.keymap.set('n', '<leader>ghb', function()
        local filepath = vim.api.nvim_buf_get_name(0)
        local relative_path = vim.fn.fnamemodify(filepath, ':~:.')
        go_to_github(relative_path)
      end, { desc = 'Go to this file in github' })

      vim.keymap.set('v', '<leader>ghb', function()
        local filepath = vim.api.nvim_buf_get_name(0)
        local relative_path = vim.fn.fnamemodify(filepath, ':~:.')
        local cursor_line = vim.fn.getpos('.')[2]
        local other_end = vim.fn.getpos('v')[2]

        -- get line numbers
        if cursor_line > other_end then
          relative_path = relative_path .. ':' .. other_end .. '-' .. cursor_line
        elseif cursor_line < other_end then
          relative_path = relative_path .. ':' .. cursor_line .. '-' .. other_end
        else
          relative_path = relative_path .. ':' .. other_end
        end

        go_to_github(relative_path)
      end, { desc = 'Go to this visual selection in github' })

      vim.keymap.set('n', '<leader>ghy', function()
        local filepath = vim.api.nvim_buf_get_name(0)
        local relative_path = vim.fn.fnamemodify(filepath, ':~:.')
        copy_github_url(relative_path)
      end, { desc = 'Copy github link to file' })

      vim.keymap.set('v', '<leader>ghy', function()
        local filepath = vim.api.nvim_buf_get_name(0)
        local relative_path = vim.fn.fnamemodify(filepath, ':~:.')
        local cursor_line = vim.fn.getpos('.')[2]
        local other_end = vim.fn.getpos('v')[2]

        -- get line numbers
        if cursor_line > other_end then
          relative_path = relative_path .. ':' .. other_end .. '-' .. cursor_line
        elseif cursor_line < other_end then
          relative_path = relative_path .. ':' .. cursor_line .. '-' .. other_end
        else
          relative_path = relative_path .. ':' .. other_end
        end

        copy_github_url(relative_path)
      end, { desc = 'Copy github link to visual selection' })

      vim.keymap.set('n', '<leader>ghp', function()
        -- Check if PR exists for current branch
        vim.fn.jobstart({
          'gh',
          'pr',
          'view',
          '--web',
        }, {
          on_exit = function(_, exit_code)
            if exit_code ~= 0 then
              -- No PR exists, create one
              vim.fn.jobstart { 'gh', 'pr', 'create', '--web' }
            end
          end,
        })
      end, { desc = 'Create or view PR on github' })

      vim.keymap.set('n', '<leader>ghr', function()
        vim.fn.jobstart({ 'gh', 'pr', 'checks', '--watch', '--fail-fast' }, {
          on_exit = function(_, exit_code)
            if exit_code == 0 then
              vim.notify('PR checks passed! Press <leader>ghy (yes) or <leader>ghn (no)', vim.log.levels.INFO)

              -- Create temporary keymap to mark PR as ready
              vim.keymap.set('n', '<leader>ghy', function()
                vim.fn.jobstart { 'gh', 'pr', 'ready' }
                vim.notify('PR marked as ready', vim.log.levels.INFO)
                -- Remove both keymaps after use
                vim.keymap.del('n', '<leader>ghy')
                vim.keymap.del('n', '<leader>ghn')
              end, { desc = 'Mark PR as ready (temporary)' })

              -- Create temporary keymap to decline marking as ready
              vim.keymap.set('n', '<leader>ghn', function()
                vim.notify('PR not marked as ready', vim.log.levels.INFO)
                -- Remove both keymaps
                vim.keymap.del('n', '<leader>ghy')
                vim.keymap.del('n', '<leader>ghn')
              end, { desc = 'Do not mark PR as ready (temporary)' })
            else
              vim.notify('PR checks failed', vim.log.levels.ERROR)
            end
          end,
        })
      end, { desc = 'Mark pr as ready when checks pass' })
    end,
  },
}
