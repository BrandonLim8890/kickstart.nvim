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

      -- Upstream kickstart keymaps (reproduced here because our config replaces upstream's)
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
      vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
      vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
      end, { desc = '[/] Fuzzily search in current buffer' })
      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
      end, { desc = '[S]earch [/] in Open Files' })
      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })

      -- LSP keymaps via LspAttach (mirrors upstream telescope config)
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
        callback = function(event)
          local buf = event.buf
          vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })
          vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })
          vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })
          vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })
          vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })
          vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
        end,
      })

      -- Custom keymaps
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
