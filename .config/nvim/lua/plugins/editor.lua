return {
  -- Tmux/window navigation
  {
    'christoomey/vim-tmux-navigator',
    lazy = false,
    keys = {
      { '<C-h>', '<cmd>TmuxNavigateLeft<CR>', desc = 'window left' },
      { '<C-j>', '<cmd>TmuxNavigateDown<CR>', desc = 'window down' },
      { '<C-k>', '<cmd>TmuxNavigateUp<CR>', desc = 'window up' },
      { '<C-l>', '<cmd>TmuxNavigateRight<CR>', desc = 'window right' },
    },
  },

  -- Harpoon: quick file marks
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    opts = {
      menu = { width = vim.api.nvim_win_get_width(0) - 4 },
      settings = { save_on_toggle = true },
    },
    keys = {
      {
        '<leader>ma',
        function()
          require('harpoon'):list():add()
        end,
        desc = 'Harpoon File',
      },
      {
        '<leader>sm',
        function()
          local h = require 'harpoon'
          h.ui:toggle_quick_menu(h:list())
        end,
        desc = '[S]earch Harpoon [M]arks',
      },
      {
        '<leader>H',
        function()
          require('harpoon'):list():select(1)
        end,
        desc = 'Harpoon mark 1',
      },
      {
        '<leader>J',
        function()
          require('harpoon'):list():select(2)
        end,
        desc = 'Harpoon mark 2',
      },
      {
        '<leader>K',
        function()
          require('harpoon'):list():select(3)
        end,
        desc = 'Harpoon mark 3',
      },
      {
        '<leader>L',
        function()
          require('harpoon'):list():select(4)
        end,
        desc = 'Harpoon mark 4',
      },
      {
        '<leader>:',
        function()
          require('harpoon'):list():select(5)
        end,
        desc = 'Harpoon mark 5',
      },
    },
  },

  -- Flash: fast motions
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
      modes = { char = { highlight = { backdrop = false } } },
    },
  },

  -- Undotree
  {
    'mbbill/undotree',
    keys = {
      { '<leader>u', '<cmd>UndotreeToggle<CR>', desc = 'Toggle Undo Tree' },
    },
  },

  -- Fold management
  {
    'chrisgrieser/nvim-origami',
    event = 'VeryLazy',
    opts = {},
    init = function()
      vim.opt.foldlevel = 99
      vim.opt.foldlevelstart = 99
    end,
  },

  -- Symbol outline
  {
    'stevearc/aerial.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      vim.keymap.set('n', '<leader>vo', '<cmd>AerialToggle float<CR>', { desc = 'View Outline', noremap = true, silent = true, nowait = true })
      require('aerial').setup {
        backends = { 'treesitter', 'lsp' },
        layout = {
          default_direction = 'float',
          max_width = { 80, 0.8 },
          min_width = 40,
        },
        float = { relative = 'editor', max_height = 0.8, min_height = 20 },
      }
    end,
  },

  -- Peek definition in floating window
  {
    'WilliamHsieh/overlook.nvim',
    opts = {},
    keys = {
      {
        '<leader>pd',
        function()
          require('overlook.api').peek_definition()
        end,
        desc = 'Overlook: Peek definition',
      },
      {
        '<leader>pc',
        function()
          require('overlook.api').close_all()
        end,
        desc = 'Overlook: Close all popup',
      },
      {
        '<leader>pu',
        function()
          require('overlook.api').restore_popup()
        end,
        desc = 'Overlook: Restore popup',
      },
      {
        '<leader>pU',
        function()
          require('overlook.api').restore_all_popups()
        end,
        desc = 'Overlook: Restore all popups',
      },
      {
        '<leader>ps',
        function()
          require('overlook.api').open_in_split()
        end,
        desc = 'Overlook: Open in split',
      },
      {
        '<leader>pv',
        function()
          require('overlook.api').open_in_vsplit()
        end,
        desc = 'Overlook: Open in vsplit',
      },
      {
        '<leader>po',
        function()
          require('overlook.api').open_in_original_window()
        end,
        desc = 'Overlook: Open in original window',
      },
      {
        '<leader>pp',
        function()
          require('overlook.api').peek_cursor()
        end,
        desc = 'Overlook: Peek cursor',
      },
      {
        '<leader>pf',
        function()
          require('overlook.api').switch_focus()
        end,
        desc = 'Overlook: Switch focus',
      },
    },
  },

  -- mini.nvim: text objects, surround, commenting, cursor word highlight
  {
    'nvim-mini/mini.nvim',
    dependencies = { 'JoosepAlviste/nvim-ts-context-commentstring' },
    config = function()
      require('mini.ai').setup {
        mappings = { around_next = 'aa', inside_next = 'ii' },
        n_lines = 500,
      }
      require('mini.surround').setup()
      require('mini.comment').setup {
        options = {
          custom_commentstring = function()
            return require('ts_context_commentstring.internal').calculate_commentstring() or vim.bo.commentstring
          end,
        },
      }
      require('mini.cursorword').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  -- Indent guides
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {},
  },

  -- Autopairs
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },

  -- Indentation detection
  { 'NMAC427/guess-indent.nvim', opts = {} },
}
