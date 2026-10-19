" SPDX-License-Identifier: Unlicense OR CC0-1.0
" Deliberately overrides Neovim's built-in Atlas association for .as.
augroup openplanet_filetype
  autocmd!
  autocmd BufRead,BufNewFile *.as setlocal filetype=angelscript
augroup END
