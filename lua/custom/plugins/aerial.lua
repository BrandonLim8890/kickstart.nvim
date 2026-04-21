return {
  'stevearc/aerial.nvim',
  event = 'VeryLazy',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    local function opts(desc)
      return { desc = desc, noremap = true, silent = true, nowait = true }
    end

    vim.keymap.set('n', '<leader>vo', '<cmd>AerialToggle float<CR>', opts 'View Outline')

    require('aerial').setup {
      backends = { 'treesitter', 'lsp' },
      layout = {
        default_direction = 'float',
        max_width = { 80, 0.8 },
        min_width = 40,
      },
      float = {
        relative = 'editor',
        max_height = 0.8,
        min_height = 20,
      },
    }
  end,
}
