set tabstop=4 shiftwidth=4
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
