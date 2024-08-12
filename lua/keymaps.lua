-- Custom keymaps for movement
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('x', '<leader>p', [["_dP]])
vim.keymap.set('n', '<leader>Y', [["+Y]])
vim.keymap.set({ 'n', 'v' }, '<leader>y', [["+y]])
vim.keymap.set({ 'n', 'v' }, '<leader>d', [["_d]])
vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { desc = '[f]ormat the file' })
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
vim.keymap.set('n', '<leader>z', '<cmd>Centerpad<cr>', { silent = true, noremap = true })

-- Save
vim.keymap.set({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })


-- Buffer movemnt
vim.keymap.set('n', '<leader>bd', ':bdel<Return>')

-- Window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set('n', '<leader>wv', '<C-w>v', { desc = 'Split window vertically' })
vim.keymap.set('n', '<leader>wh', '<C-w>s', { desc = 'Split window horizontally' })
vim.keymap.set('n', '<leader>we', '<C-w>=', { desc = 'Make splits equal size' })
vim.keymap.set('n', '<leader>wq', '<C-w>q', { desc = 'Close current window' })
vim.keymap.set('n', '<leader>wo', '<C-w>o', { desc = 'Close all other windows' })


-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- -- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- -- is not what someone will guess without a bit more experience.
-- --
-- -- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- -- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

if vim.g.neovide then
  local keymapOpts = {
    silent = true,
    noremap = true,
  }
  vim.keymap.set({ 'n', 'v' }, '<D-v>', '"*p', keymapOpts)
  vim.keymap.set({ 'n', 'v' }, '<D-c>', '"*y', keymapOpts)
  vim.keymap.set({ 'n', 'v' }, '<D-x>', '"*x', keymapOpts)
  vim.keymap.set({ 'i' }, '<D-v>', '<C-r>+', keymapOpts)
end
