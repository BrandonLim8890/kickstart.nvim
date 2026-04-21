return {
  'olimorris/persisted.nvim',
  event = 'BufReadPre',
  opts = {
    use_git_branch = true,
  },
  keys = {
    {
      '<leader>Sl',
      '<cmd>Persisted load<cr>',
      desc = 'Load session (current dir)',
    },
    {
      '<leader>SL',
      '<cmd>Persisted load_last<cr>',
      desc = 'Load last session',
    },
    {
      '<leader>Ss',
      '<cmd>Persisted save<cr>',
      desc = 'Save session',
    },
    {
      '<leader>St',
      '<cmd>Persisted toggle<cr>',
      desc = 'Toggle session persistence',
    },
    {
      '<leader>sp',
      '<cmd>Telescope persisted<cr>',
      desc = 'Find session',
    },
    {
      '<leader>Sd',
      '<cmd>Persisted delete<cr>',
      desc = 'Delete session',
    },
    {
      '<leader>SD',
      '<cmd>Persisted delete_current<cr>',
      desc = 'Delete current session',
    },
  },
}
