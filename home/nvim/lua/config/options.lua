local opt = vim.opt

-- Leader keys must be set before plugins load.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- UI
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.showmode = false -- statusline shows the mode
opt.pumheight = 12
opt.winborder = "rounded" -- rounded borders for floating windows
opt.fillchars = { eob = " " } -- hide ~ on empty lines

-- Indentation (4 spaces suits Rust; C/C++ styles often override via .clang-format)
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Files
opt.undofile = true
opt.swapfile = false
opt.updatetime = 250
opt.timeoutlen = 400

-- Use system clipboard
opt.clipboard = "unnamedplus"

-- Diagnostics appearance
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded", source = "if_many" },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
})
