set tabstop=4 shiftwidth=4 expandtab
set cursorline
set cursorcolumn
autocmd BufWritePre * %s/\s\+$//e
set number
syntax on
map <F1> <Esc>
imap <F1> <Esc>
set mouse-=a
