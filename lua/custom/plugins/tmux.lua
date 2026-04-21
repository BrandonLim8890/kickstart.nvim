return {
  'christoomey/vim-tmux-navigator',
  lazy = false,
  keys = {
    { '<C-h>', '<cmd>TmuxNavigateLeft<CR>', desc = 'window left' },
    { '<C-j>', '<cmd>TmuxNavigateDown<CR>', desc = 'window down' },
    { '<C-k>', '<cmd>TmuxNavigateUp<CR>', desc = 'window up' },
    { '<C-l>', '<cmd>TmuxNavigateRight<CR>', desc = 'window right' },
  },
}
