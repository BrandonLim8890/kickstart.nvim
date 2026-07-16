return {
  -- Disable the kickstart default colorscheme so it doesn't fight nordic
  { 'folke/tokyonight.nvim', enabled = false },

  -- Colorscheme
  {
    'AlexvZyl/nordic.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('nordic').setup {
        on_highlight = function(highlights, _)
          highlights.Visual = { bg = '#3B4252', bold = false }
        end,
      }
      vim.cmd.colorscheme 'nordic'
    end,
  },

  -- Statusline
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons', 'linrongbin16/lsp-progress.nvim' },
    opts = {
      options = {
        theme = 'nordic',
        component_separators = '',
        section_separators = { left = "\xee\x82\xb4", right = "\xee\x82\xb6" },
        disabled_filetypes = { 'alpha', 'Outline' },
      },
      tabline = {
        lualine_b = {
          { 'filetype', icon_only = true, padding = { left = 1, right = 0 } },
        },
        lualine_c = {
          { 'filename', path = 1, shorting_target = 0 },
        },
      },
      inactive_sections = {
        lualine_b = {
          { 'filetype', icon_only = true, padding = { left = 1, right = 0 } },
          'filename',
        },
        lualine_c = {},
      },
      sections = {
        lualine_a = {
          function()
            local reg = vim.fn.reg_recording()
            if reg ~= '' then
              return 'Recording @' .. reg
            end
            local mode = vim.api.nvim_get_mode().mode
            local mode_map = {
              n = 'NORMAL', i = 'INSERT', v = 'VISUAL', V = 'V-LINE',
              ['^V'] = 'V-BLOCK', c = 'COMMAND', R = 'REPLACE',
              s = 'SELECT', S = 'S-LINE', ['^S'] = 'S-BLOCK', t = 'TERMINAL',
            }
            return mode_map[mode] or mode:upper()
          end,
        },
        lualine_b = {
          { 'filetype', icon_only = true, padding = { left = 1, right = 0 } },
          'filename',
        },
        lualine_c = {
          { 'branch', icon = '' },
        },
        lualine_x = {
          {
            function()
              local s = require 'bend_check_state'
              if not s.running or not s.start_time then
                return ''
              end
              local elapsed_ms = (vim.uv.hrtime() - s.start_time) / 1e6
              local frame = math.floor(elapsed_ms / 200) % #s.chars + 1
              return s.chars[frame] .. ' bend check'
            end,
            color = { fg = '#88C0D0' },
          },
          {
            'diagnostics',
            symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
            update_in_insert = true,
          },
        },
        lualine_y = {
          {
            'diff',
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if not gitsigns then return nil end
              return { added = gitsigns.added, modified = gitsigns.changed, removed = gitsigns.removed }
            end,
          },
        },
        lualine_z = {
          { 'location', separator = { left = "\xee\x82\xb6", right = "\xee\x82\xb4 " } },
        },
      },
    },
  },

  -- Command palette / UI enhancements
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    opts = {
      lsp = {
        override = {
          ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
          ['cmp.entry.get_documentation'] = true,
        },
      },
      presets = {
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = false,
      },
      views = {
        cmdline_popup = {
          position = { row = 5, col = '50%' },
          size = { width = 60, height = 'auto' },
        },
        popupmenu = {
          relative = 'editor',
          position = { row = 8, col = '50%' },
          size = { width = 60, height = 10 },
          border = { style = 'rounded', padding = { 0, 1 } },
          win_options = { winhighlight = { Normal = 'Normal', FloatBorder = 'DiagnosticInfo' } },
        },
      },
    },
    dependencies = {
      'MunifTanjim/nui.nvim',
      {
        'rcarriga/nvim-notify',
        name = 'notify',
        opts = {
          top_down = false,
          stages = 'static',
          max_height = function() return math.floor(vim.o.lines * 0.75) end,
          max_width = function() return math.floor(vim.o.columns * 0.75) end,
          -- nvim-notify has a treesitter crash in nvim 0.12 (TSNode:range() nil).
          -- Detaching treesitter from the notification buffer on open is the workaround.
          on_open = function(win)
            local buf = vim.api.nvim_win_get_buf(win)
            pcall(vim.treesitter.stop, buf)
          end,
        },
      },
    },
  },

  -- todo-comments
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
}
