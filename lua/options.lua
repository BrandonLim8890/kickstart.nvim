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

--  Apperance
opt.termguicolors = true

-- Backspace
opt.backspace = 'indent,eol,start'

-- SplitWindow
opt.splitright = true

-- Fast update
opt.updatetime = 50

-- Incremental search
opt.incsearch = true


-- Autosave
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost" }, {
  callback = function()
    if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" and vim.bo.buftype == "" then
      vim.api.nvim_command('silent update')
    end
  end,
})
