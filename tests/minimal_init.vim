set runtimepath+=.
set runtimepath+=../plenary.nvim

" Add the plugin path to package.path
lua << EOF
package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'
EOF

" Load the test helpers
runtime tests/init.lua

" Turn off swap files
set noswapfile