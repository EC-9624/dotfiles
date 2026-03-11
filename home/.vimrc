" ========================================
" Options
" ========================================

set encoding=UTF-8
set spelllang=en_us,de_de,es_es
set nohlsearch " Disable highlight on search
set number " Enable line numbers
set mouse=a " Enable mouse mode
set breakindent " Enable break indent
set undofile " Save undo history
set ignorecase " Case-insensitive searching unless \C or capital in search
set smartcase " Enable smart case
set signcolumn=yes " Keep signcolumn on by default
set updatetime=250 " Decrease update time
set timeoutlen=300 " Time to wait for a mapped sequence to complete (in milliseconds)
set nobackup " Don't create a backup file
set nowritebackup " Don't write backup before overwriting
set completeopt=menuone,noselect " Better completion experience
set whichwrap+=<,>,[,],h,l " Allow certain keys to move to the next line
set nowrap " Display long lines as one line
set linebreak " Don't break words when wrapping
set scrolloff=8 " Keep 8 lines above/below cursor
set sidescrolloff=8 " Keep 8 columns to the left/right of cursor
set relativenumber " Use relative line numbers
set numberwidth=4 " Number column width
set shiftwidth=4 " Spaces per indentation
set tabstop=4 " Spaces per tab
set softtabstop=4 " Spaces per tab during editing ops
set expandtab " Convert tabs to spaces
set nocursorline " Don't highlight the current line
set splitbelow " Horizontal splits below current window
set splitright " Vertical splits to the right
set noswapfile " Don't use a swap file
set smartindent " Smart indentation
set showtabline=2 " Always show tab line
set backspace=indent,eol,start " Configurable backspace behavior
set pumheight=10 " Popup menu height
set conceallevel=0 " Make `` visible in markdown
set fileencoding=utf-8 " File encoding
set cmdheight=1 " Command line height
set autoindent " Auto-indent new lines
set shortmess+=c " Don't show completion menu messages
set iskeyword+=- " Treat hyphenated words as whole words
set showmatch " show the matching part of pairs [] {} and ()
set laststatus=2 " Show status bar
set statusline=%f " Path to the file
set statusline+=%= " Switch to the right side
set statusline+=%l " Current line
set statusline+=/ " Separator
set statusline+=%L " Total lines


" ========================================
" Keymaps
" ========================================

" Set leader key
let mapleader = " "
let maplocalleader = " "

" Disable the spacebar key's default behavior in Normal and Visual modes
nnoremap <Space> <Nop>
vnoremap <Space> <Nop>

" Allow moving the cursor through wrapped lines with j, k
nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
nnoremap <expr> j v:count == 0 ? 'gj' : 'j'

" clear highlights
nnoremap <Esc> :noh<CR>

" save file
nnoremap <C-s> :w<CR>

" save file without auto-formatting
nnoremap <leader>sn :noautocmd w<CR>

" quit file
nnoremap <C-q> :q<CR>

" delete single character without copying into register
nnoremap x "_x

" Vertical scroll and center
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" Find and center
nnoremap n nzzzv
nnoremap N Nzzzv

" Resize with arrows
nnoremap <Up> :resize -2<CR>
nnoremap <Down> :resize +2<CR>
nnoremap <Left> :vertical resize -2<CR>
nnoremap <Right> :vertical resize +2<CR>

" Navigate buffers
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <leader>sb :buffers<CR>:buffer<Space>

" increment/decrement numbers
nnoremap <leader>+ <C-a>
nnoremap <leader>- <C-x>

" window management
nnoremap <leader>v <C-w>v
nnoremap <leader>h <C-w>s
nnoremap <leader>se <C-w>=
nnoremap <leader>xs :close<CR>

" Navigate between splits
nnoremap <C-k> :wincmd k<CR>
nnoremap <C-j> :wincmd j<CR>
nnoremap <C-h> :wincmd h<CR>
nnoremap <C-l> :wincmd l<CR>

" tabs
nnoremap <leader>to :tabnew<CR>
nnoremap <leader>tx :tabclose<CR>
nnoremap <leader>tn :tabn<CR>
nnoremap <leader>tp :tabp<CR>

nnoremap <leader>x :bdelete<CR>
nnoremap <leader>b :enew<CR>

" toggle line wrapping
nnoremap <leader>lw :set wrap!<CR>

" Press jk fast to exit insert mode
inoremap jk <ESC>
inoremap kj <ESC>

" Stay in indent mode
" vnoremap < <gv
" vnoremap > >gv

" Keep last yanked when pasting
vnoremap p "_dP

" Explicitly yank to system clipboard (highlighted and entire row)
noremap <leader>y "+y
noremap <leader>Y "+Y

" Open file explorer
noremap <silent> <leader>e :Lex<CR>


" ========================================
" Other
" ========================================

" Syntax highlighting
syntax on

" Sync clipboard with OS
if system('uname -s') == "Darwin\n"
  set clipboard=unnamed "OSX
else
  set clipboard=unnamedplus "Linux
endif

" True colors
if !has('gui_running') && &term =~ '\%(screen\|tmux\)'
  let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
  let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
endif
set termguicolors

" Rose Pine
set background=dark
highlight clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "rosepine_local"

highlight Normal guifg=#e0def4 guibg=#191724 ctermfg=255 ctermbg=234
highlight NormalNC guifg=#e0def4 guibg=#191724 ctermfg=255 ctermbg=234
highlight CursorLine guibg=#1f1d2e ctermbg=235
highlight CursorLineNr guifg=#f6c177 guibg=#1f1d2e ctermfg=223 ctermbg=235
highlight LineNr guifg=#6e6a86 guibg=#191724 ctermfg=242 ctermbg=234
highlight SignColumn guifg=#908caa guibg=#191724 ctermfg=246 ctermbg=234
highlight EndOfBuffer guifg=#26233a guibg=#191724 ctermfg=235 ctermbg=234
highlight VertSplit guifg=#524f67 guibg=#191724 ctermfg=240 ctermbg=234
highlight WinSeparator guifg=#524f67 guibg=#191724 ctermfg=240 ctermbg=234
highlight StatusLine guifg=#e0def4 guibg=#26233a ctermfg=255 ctermbg=235
highlight StatusLineNC guifg=#908caa guibg=#1f1d2e ctermfg=246 ctermbg=235
highlight Pmenu guifg=#e0def4 guibg=#26233a ctermfg=255 ctermbg=235
highlight PmenuSel guifg=#191724 guibg=#9ccfd8 ctermfg=234 ctermbg=152
highlight Visual guifg=NONE guibg=#403d52 ctermfg=NONE ctermbg=238
highlight Search guifg=#191724 guibg=#f6c177 ctermfg=234 ctermbg=223
highlight IncSearch guifg=#191724 guibg=#ebbcba ctermfg=234 ctermbg=224
highlight MatchParen guifg=#f6c177 guibg=#26233a ctermfg=223 ctermbg=235
highlight Directory guifg=#9ccfd8 guibg=NONE ctermfg=152 ctermbg=NONE

highlight Comment guifg=#6e6a86 gui=italic ctermfg=242 cterm=italic
highlight Constant guifg=#eb6f92 ctermfg=204
highlight String guifg=#f6c177 ctermfg=223
highlight Character guifg=#f6c177 ctermfg=223
highlight Number guifg=#ebbcba ctermfg=224
highlight Boolean guifg=#ebbcba ctermfg=224
highlight Identifier guifg=#9ccfd8 ctermfg=152
highlight Function guifg=#c4a7e7 ctermfg=182
highlight Statement guifg=#eb6f92 ctermfg=204
highlight Conditional guifg=#eb6f92 ctermfg=204
highlight Repeat guifg=#eb6f92 ctermfg=204
highlight Operator guifg=#908caa ctermfg=246
highlight Keyword guifg=#eb6f92 ctermfg=204
highlight PreProc guifg=#31748f ctermfg=67
highlight Type guifg=#9ccfd8 ctermfg=152
highlight Special guifg=#c4a7e7 ctermfg=182
highlight Todo guifg=#191724 guibg=#f6c177 ctermfg=234 ctermbg=223
highlight Error guifg=#eb6f92 guibg=#26233a ctermfg=204 ctermbg=235
highlight ErrorMsg guifg=#eb6f92 guibg=#26233a ctermfg=204 ctermbg=235
highlight WarningMsg guifg=#f6c177 guibg=#191724 ctermfg=223 ctermbg=234

highlight DiffAdd guifg=#9ccfd8 guibg=#1f3d44 ctermfg=152 ctermbg=23
highlight DiffChange guifg=#f6c177 guibg=#3b315d ctermfg=223 ctermbg=54
highlight DiffDelete guifg=#eb6f92 guibg=#3d1f2b ctermfg=204 ctermbg=52
highlight DiffText guifg=#e0def4 guibg=#524f67 ctermfg=255 ctermbg=240

" Use a line cursor within insert mode and a block cursor everywhere else.
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" Netrw
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_altv = 1
let g:netrw_winsize = 25 
" Use 'l' instead of <CR> to open files
augroup netrw_setup | au!
    au FileType netrw nmap <buffer> l <CR>
augroup END
