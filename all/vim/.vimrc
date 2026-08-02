set splitright
set cursorline
set cursorcolumn
set list
set listchars=tab:\ \ >,
autocmd BufWritePre * %s/\s\+$//e
autocmd BufWritePost * :redraw!
set number
filetype on
syntax on
map <F1> <Esc>
imap <F1> <Esc>
set mouse-=a
command! -bang W w<bang>
command! -bang Q q<bang>
command! -bang Wq wq<bang>
command! -bang WQ wq<bang>
command! -bang Qw wq<bang>
command! -bang QW wq<bang>
