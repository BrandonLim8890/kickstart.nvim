return {
  'nvim-lualine/lualine.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons', 'linrongbin16/lsp-progress.nvim' },
  opts = {
    options = {
      theme = 'nordic',
    },
    sections = {
      lualine_c = {
        {
          'filename',
          file_status = true,
          newfile_status = false,
          path = 4,
          symbols = {
            modified = '[+]',
            readonly = '[-]',
          },
        },
      },
    },
  },
}
