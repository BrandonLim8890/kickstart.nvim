return {
  {
    'AlexvZyl/nordic.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('nordic').setup {
        on_highlight = function(highlights, _)
          highlights.Visual = {
            bg = '#3B4252',
            bold = false,
          }
        end,
      }
      vim.cmd.colorscheme 'nordic'
    end,
  },
  -- Disable the upstream tokyonight that kickstart ships
  { 'folke/tokyonight.nvim', enabled = false },
}
