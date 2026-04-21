-- Overrides for plugins defined in init.lua (kickstart base config).
-- These specs are merged by lazy.nvim with the base specs via the plugin name key.

return {
  -- ── Conform: restore your formatter list ─────────────────────────────
  {
    'stevearc/conform.nvim',
    opts = {
      formatters_by_ft = {
        python = { 'black' },
        lua = { 'stylua' },
        javascript = { 'prettierd' },
        typescript = { 'prettierd' },
        javascriptreact = { 'prettierd' },
        typescriptreact = { 'prettierd' },
        html = { 'prettierd' },
        css = { 'prettierd' },
        java = { 'prettierd' },
      },
      format_on_save = function(bufnr)
        local enabled = {
          python = true,
          lua = true,
          javascript = true,
          typescript = true,
          javascriptreact = true,
          typescriptreact = true,
          html = true,
          css = true,
          java = true,
        }
        if enabled[vim.bo[bufnr].filetype] then
          return { timeout_ms = 500 }
        end
      end,
    },
  },

  -- ── Telescope: custom pickers / mappings ─────────────────────────────
  {
    'nvim-telescope/telescope.nvim',
    opts = {
      defaults = {
        path_display = {
          filename_first = { reverse_directories = false },
        },
        mappings = {
          i = {
            ['<C-q>'] = function(...)
              require('trouble.sources.telescope').open(...)
            end,
          },
          n = {
            ['<C-q>'] = function(...)
              require('trouble.sources.telescope').open(...)
            end,
          },
        },
      },
      pickers = {
        live_grep = {
          file_ignore_patterns = { 'node_modules', '.git', '^build/' },
          additional_args = function(_)
            return { '--hidden' }
          end,
        },
        find_files = {
          file_ignore_patterns = { 'node_modules', '.git', '^build/' },
          hidden = true,
        },
      },
    },
    config = function(_, opts)
      require('telescope').setup(opts)
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')
      pcall(require('telescope').load_extension, 'persisted')

      local builtin = require 'telescope.builtin'

      -- Extra keymaps on top of kickstart defaults
      vim.keymap.set('n', '<leader>shf', '<cmd>Telescope find_files no_ignore=true<CR>', { desc = '[S]earch [H]idden [F]iles' })
      vim.keymap.set('n', '<leader>si', '<cmd>I18nPicker<CR>', { desc = '[S]earch [I]18n translations' })
      vim.keymap.set('n', '<leader>st', function()
        local dirs = require 'custom.bend_dirs'
        if #dirs == 0 then
          builtin.git_status()
        elseif #dirs == 1 then
          builtin.git_status { cwd = dirs[1] }
        else
          vim.ui.select(dirs, { prompt = 'Git status for repo:' }, function(choice)
            if choice then
              builtin.git_status { cwd = choice }
            end
          end)
        end
      end, { desc = '[S]earch by Git S[T]atus' })
    end,
  },

  -- ── blink.cmp: restore your preferred preset + lazydev source ────────
  {
    'saghen/blink.cmp',
    dependencies = { 'folke/lazydev.nvim' },
    opts = {
      keymap = { preset = 'enter' },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        accept = { auto_brackets = { enabled = false } },
      },
      sources = {
        default = { 'lsp', 'path', 'lazydev', 'snippets' },
        providers = {
          lazydev = {
            min_keyword_length = 2,
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            score_offset = 5,
          },
          path = { min_keyword_length = 0, score_offset = 10 },
          lsp = { score_offset = 1000 },
          snippets = { min_keyword_length = 2, score_offset = -100 },
        },
      },
      signature = { enabled = true },
    },
  },

  -- ── lazydev: re-add since blink depends on it ────────────────────────
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
}
