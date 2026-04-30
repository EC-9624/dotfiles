local opt = vim.opt

-- Search behavior
opt.hlsearch = false
opt.ignorecase = true
opt.smartcase = true

-- Line numbers and interface
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.numberwidth = 4
opt.showtabline = 0
opt.laststatus = 3
opt.termguicolors = true
opt.fillchars:append({ eob = " " })

-- Mouse, timing, and undo history
opt.mouse = "a"
opt.updatetime = 250
opt.timeoutlen = 300
opt.undofile = true

-- Backup and swap files
opt.backup = false
opt.writebackup = false
opt.swapfile = false

-- Completion and cursor movement
opt.completeopt = { "menuone", "noselect" }
opt.whichwrap:append("<,>,[,],h,l")

-- Wrapping and scrolling
opt.wrap = false
opt.linebreak = true
opt.breakindent = true
opt.scrolloff = 10
opt.sidescrolloff = 10

-- Indentation and tabs
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

-- Window splitting
opt.splitbelow = true
opt.splitright = true

-- Editing behavior
opt.backspace = { "indent", "eol", "start" }
opt.iskeyword:append("-")
opt.showmatch = true

-- Popup menu and concealed text
opt.pumheight = 10
opt.conceallevel = 0

-- Clipboard integration
opt.clipboard = "unnamedplus"
