
" TODO: let server port be global var

let g:server_reachable = 0
let g:loaded_fireplace = 1
let g:parinfer_server_pid = 0
let g:parinfer_mode = "indent"

" not currently used 
function! PingServer()
  let cmd = 'curl -sw "%{http_code}" localhost:8088 -o /dev/null'
  return system(cmd)
endfunction

function! SendStr()
  
  if !g:parinfer_server_pid
    echo "parinfer server not started"
    return 0
  endif
  
  let page = join(getline(1,'$'), "\n")
  let body = substitute(page, '\n', '\\n', 'g')
  let pos = getpos(".")
  let cursor = pos[0]
  let line = pos[1]
  let jsonbody = '{"text": "' . body . '", "cursor":' . cursor . ', "line":' . line . '}'
  let cmd = "curl -s -X POST -d '" . jsonbody . "' localhost:8088/indent" 
  let res = system(cmd)
  redraw!
  " this makes handling \n chars much more sane
  " as opppsed to append()
  let save_cursor = getpos(".")
  normal! ggdG
  let @a = res
  execute "put a"
  normal ggdd
  call setpos('.', save_cursor)
endfunction

function! StartServer()
  let cmd = "node server.js > /tmp/parinfer.log & echo $!"
  let pid = system(cmd)
  let g:parinfer_server_pid = pid
  return pid
endfunction

function! StopServer()
  let cmd = "kill -9 " . g:parinfer_server_pid
  let res = system(cmd)
endfunction

function! DoIndent()
  normal >>
  call SendStr()
endfunction

function! Undent()
  normal <<
  call SendStr()
endfunction

augroup parinfer
  autocmd!
  autocmd BufNewFile,BufReadPost *.clj setfiletype clojure
  nnoremap <buffer> <leader>bb :call SendStr()<cr>
  au InsertLeave *.clj call SendStr()
  au VimLeavePre * call StopServer()
  au FileType clojure nnoremap <Tab> :call DoIndent()<cr>
  au FileType clojure nnoremap <S-Tab> :call Undent()<cr>
  au FileType clojure nnoremap w :call DoIndent()<cr>
  au FileType clojure nnoremap q :call Undent()<cr>
augroup END

function! SetupParinfer()
  let g:parinfer_setup = 1
  call StartServer()
endfunction

if !exists("g:parinfer_setup")
  call SetupParinfer()
endif
