local opt = vim.opt

-- Tabs & Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.autoindent = true
opt.expandtab = true
opt.smarttab = true

-- Cursor Line
opt.cursorline = true

-- Padding top and bottom
opt.scrolloff = 8

--  Appearance
opt.termguicolors = true

-- Backspace
opt.backspace = 'indent,eol,start'

-- SplitWindow
opt.splitright = true

-- Fast update
opt.updatetime = 200

-- Incremental search
opt.incsearch = true

-- Enable better refresh
opt.autoread = true
opt.swapfile = false
vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold', 'CursorHoldI', 'FocusGained' }, {
  command = "if mode() != 'c' | checktime | endif",
  pattern = { '*' },
})

-- Autosave
vim.api.nvim_create_autocmd({ 'BufLeave', 'FocusLost' }, {
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand '%' ~= '' and vim.bo.buftype == '' then
      vim.api.nvim_command 'silent update'
    end
  end,
})

-- Override diagnostic config with nerd-font icons (runs after init.lua sets basics)
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = true,
  virtual_lines = false,
  jump = { float = true },
}

-- Suppress "No information available" hover notifications from LSP.
vim.lsp.config('*', {
  handlers = {
    ['textDocument/hover'] = function(err, result, ctx, config)
      if err or (not result) or (not result.contents) then
        return
      end
      vim.lsp.handlers.hover(err, result, ctx, config)
    end,
  },
})

-- Suppress E490 "No fold found" from nvim 0.12's built-in LSP fold range handler.
local ok, fold_range_mod = pcall(require, 'vim.lsp._folding_range')
if ok and fold_range_mod and fold_range_mod.foldclose then
  local orig_foldclose = fold_range_mod.foldclose
  fold_range_mod.foldclose = function(kind, winid)
    pcall(orig_foldclose, kind, winid)
  end
end
