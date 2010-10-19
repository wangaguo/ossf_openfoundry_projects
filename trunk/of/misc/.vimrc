set nocp
syntax on
set background=dark

set hidden

set tags=tags,~/tags/0.1,~/tags/ruby_c,~/tags/ruby_gems,~/tags/ruby_ruby


filetype plugin indent on " Enable filetype-specific indenting and plugins

" Load matchit (% to bounce from do to end, etc.)
runtime! macros/matchit.vim

augroup myfiletypes
  " Clear old autocmds in group
  autocmd!
  " autoindent with two spaces, always expand tabs
  autocmd FileType ruby,eruby,yaml set ai sw=2 sts=2 et
augroup END

