" Portable, plugin-free keybindings for a minimal Vim or Neovim setup.

let mapleader = " "
let maplocalleader = " "

" Disable the spacebar key's default behavior in Normal and Visual modes.
nnoremap <Space> <Nop>
vnoremap <Space> <Nop>

" Move through displayed lines when no count is given.
nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
nnoremap <expr> j v:count == 0 ? 'gj' : 'j'

" Search and scrolling.
nnoremap <Esc> :nohlsearch<CR>
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap J mzJ`z
vnoremap J :move '>+1<CR>gv=gv
vnoremap K :move '<-2<CR>gv=gv
vnoremap < <gv
vnoremap > >gv

" Files and editing.
nnoremap <C-s> :write<CR>
nnoremap <leader>sn :noautocmd write<CR>
nnoremap <C-q> :quit<CR>
nnoremap U <C-r>
nnoremap H ^
nnoremap L $
nnoremap x "_x

" Resize windows.
nnoremap <Up> :resize -2<CR>
nnoremap <Down> :resize +2<CR>
nnoremap <Left> :vertical resize -2<CR>
nnoremap <Right> :vertical resize +2<CR>

" Navigate buffers.
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <leader>sb :buffers<CR>:buffer<Space>
nnoremap <leader>x :bdelete<CR>
nnoremap <leader>b :enew<CR>

" Increment and decrement numbers.
nnoremap <leader>+ <C-a>
nnoremap <leader>_ <C-x>

" Manage windows.
nnoremap <leader>v <C-w>v
nnoremap <leader>h <C-w>s
nnoremap <leader>se <C-w>=
nnoremap <leader>xs :close<CR>
nnoremap <C-k> <C-w>k
nnoremap <C-j> <C-w>j
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l

" Manage tabs.
nnoremap <leader>to :tabnew<CR>
nnoremap <leader>tx :tabclose<CR>
nnoremap <leader>tn :tabnext<CR>
nnoremap <leader>tp :tabprevious<CR>

" Toggle line wrapping.
nnoremap <leader>lw :set wrap!<CR>

" Leave Insert mode quickly.
inoremap jk <Esc>
inoremap kj <Esc>

" Preserve the last yank when pasting over a selection.
vnoremap p "_dP

" Explicitly yank to the system clipboard.
noremap <leader>y "+y
noremap <leader>Y "+Y

" Open the built-in file explorer.
nnoremap <silent> <leader>e :Lexplore<CR>
