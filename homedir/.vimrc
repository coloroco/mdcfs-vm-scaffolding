syntax off
set ai
set nohlsearch
" set number

" http://www.vex.net/~x/python_and_vim.html
autocmd BufRead *.py set smartindent cinwords=if,elif,else,for,while,try,except,finally,def,class 

" http://vim.sourceforge.net/tips/tip.php?tip_id=80
set viminfo='10,\"100,:20,%,n~/.viminfo
" When editing a file, always jump to the last known cursor position.
" Don't do it when the position is invalid or when inside an event handler
" (happens when dropping a file on gvim).
" DF - Also do not do this if the file resides in the $TEMP directory,
"      chances are it is a different file with the same name.
" This comes from the $VIMRUNTIME/vimrc_example.vim file
autocmd BufReadPost *
  \ if expand("<afile>:p:h") !=? $TEMP |
  \   if line("'\"") > 0 && line("'\"") <= line("$") |
  \     exe "normal g`\"" |
  \     let b:doopenfold = 1 |
  \   endif |
  \ endif
" Need to postpone using "zv" until after reading the modelines.
autocmd BufWinEnter *
  \ if exists("b:doopenfold") |
  \   unlet b:doopenfold |
  \   exe "normal zv" |
  \ endif 


" vimrc file for following the coding standards specified in PEP 7 & 8.
" To use this file, source it in your own personal .vimrc file (``source
" <filename>``) or, if you don't have a .vimrc file, you can just symlink to
" it
" (``ln -s <this file> ~/.vimrc``).  All options are protected by autocmds
" (read below for an explanation of the command) so blind sourcing of this
" file
" is safe and will not affect your settings for non-Python or non-C files.

" All setting are protected by 'au' ('autocmd') statements.  Only files
" ending
" in .py or .pyw will trigger the Python settings while files ending in *.c
" or
" *.h will trigger the C settings.  This makes the file "safe" in terms of
" only
" adjusting settings for Python and C files.

" Only basic settings needed to enforce the style guidelines are set.
" Some suggested options are listed but commented out at the end of this
" file.

" Number of spaces to use for an indent.
" This will affect Ctrl-T and 'autoindent'.
" Python: 4 spaces
" C: 8 spaces (pre-existing files) or 4 spaces (new files)
au BufRead,BufNewFile *.py,*pyw set shiftwidth=4
" au BufRead *.c,*.h set shiftwidth=8
" au BufNewFile *.c,*.h set shiftwidth=4

" Number of spaces that a pre-existing tab is equal to.
" For the amount of space used for a new tab use shiftwidth.
" Python: 8
" C: 8
au BufRead,BufNewFile *py,*pyw set tabstop=4

" Replace tabs with the equivalent number of spaces.
" Also have an autocmd for Makefiles since they require hard tabs.
" Python: yes
" C: no
" Makefile: no
au BufRead,BufNewFile *.py,*.pyw set expandtab
" au BufRead,BufNewFile *.c,*.h set noexpandtab
" au BufRead,BufNewFile Makefile* set noexpandtab

" Use the below highlight group when displaying bad whitespace is desired
highlight BadWhitespace ctermbg=red guibg=red

" Display tabs at the beginning of a line in Python mode as bad.
" au BufRead,BufNewFile *.py,*.pyw match BadWhitespace /^\t\+/
" Make trailing whitespace be flagged as bad.
au BufRead,BufNewFile *.py,*.pyw match BadWhitespace /\s\+$/

" Wrap text after a certain number of characters
" Python: 79 
" C: 79
au BufRead,BufNewFile *.py,*.pyw set textwidth=79

" Turn off settings in 'formatoptions' relating to comment formatting.
" - c : do not automatically insert the comment leader when wrapping based
" on
"    'textwidth'
" - o : do not insert the comment leader when using 'o' or 'O' from command
" mode
" - r : do not insert the comment leader when hitting <Enter> in insert mode
" Python: not needed
" C: prevents insertion of '*' at the beginning of every line in a comment
" au BufRead,BufNewFile *.c,*.h set formatoptions-=c formatoptions-=o
" formatoptions-=r

" Use UNIX (\n) line endings.
" Only used for new files so as to not force existing files to change their
" line endings.
" Python: yes
" C: yes
au BufNewFile *.py,*.pyw,*.c,*.h set fileformat=unix

" ----------------------------------------------------------------------------
" The following section contains suggested settings.  While in no way
" required
" to meet coding standards, they are helpful.

" Set the default file encoding to UTF-8: ``set encoding=utf-8``

" Puts a marker at the beginning of the file to differentiate between UTF
" and
" UCS encoding (WARNING: can trick shells into thinking a text file is
" actually a binary file when executing the text file): ``set bomb``

" For full syntax highlighting:
"``let python_highlight_all=1``
"``syntax on``

" Automatically indent based on file type: ``filetype indent on``
" Keep indentation level from previous line: ``set autoindent``

" Folding based on indentation: ``set foldmethod=indent``
