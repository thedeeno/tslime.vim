" Tslime.vim. Send portion of buffer to tmux instance
" Maintainer: C.Coutinho <kikijump [at] gmail [dot] com>
" Licence:    DWTFYWTPL

if exists("g:loaded_tslime") && g:loaded_tslime
  finish
endif

let g:loaded_tslime = 1

" Function to send keys to tmux
" useful if you want to stop some command with <c-c> in tmux.
function! SendKeysToTmux(keys)
  if !exists("g:tslime")
    call <SID>TmuxVars()
  end

  call <SID>ExecuteKeys(k)
endfunction

function! s:ExecuteKeys(keys)
  call system("tmux send-keys -t " . s:tmuxTarget() . " " . a:keys)
endfunction

" Main function.
" Use it in your script if you want to send text to a tmux session.
function! SendToTmux(text)
  if !exists("g:tslime")
    call <SID>TmuxVars()
  end

  let oldbuffer = system(shellescape("tmux show-buffer"))
  call <SID>setTmuxBuffer(a:text)
  call system("tmux paste-buffer -t " . s:tmuxTarget())
  call <SID>setTmuxBuffer(oldbuffer)
endfunction

function! s:tmuxTarget()
  return '"' . g:tslime['session'] . '":' . g:tslime['window'] . "." . g:tslime['pane']
endfunction

function! s:setTmuxBuffer(text)
  let buf = substitute(a:text, "'", "\\'", 'g')
  call system("tmux load-buffer -", buf)
endfunction

" Session completion
function! TmuxSessionNames(A,L,P)
  return <SID>TmuxSessions()
endfunction

" Window completion
function! TmuxWindowNames(A,L,P)
  return <SID>TmuxWindows()
endfunction

" Pane completion
function! TmuxPaneNumbers(A,L,P)
  return <SID>TmuxPanes()
endfunction

function! s:TmuxSessions()
  return system("tmux list-sessions | sed -e 's/:.*$//'")
endfunction

function! s:TmuxWindows()
  return system('tmux list-windows -t "' . g:tslime['session'] . '" | grep -e "^\w:" | sed -e "s/\s*([0-9].*//g"')
endfunction

function! s:TmuxPanes()
  return system('tmux list-panes -t "' . g:tslime['session'] . '":' . g:tslime['window'] . " | sed -e 's/:.*$//'")
endfunction

" set tslime.vim variables
function! s:TmuxVars()
  let names = split(s:TmuxSessions(), "\n")
  let g:tslime = {}
  if len(names) == 1
    let g:tslime['session'] = names[0]
  else
    let g:tslime['session'] = ''
  endif
  while g:tslime['session'] == ''
    let g:tslime['session'] = input("session name: ", "", "custom,TmuxSessionNames")
  endwhile

  let windows = split(s:TmuxWindows(), "\n")
  if len(windows) == 1
    let window = windows[0]
  else
    let window = input("window name: ", "", "custom,TmuxWindowNames")
    if window == ''
      let window = windows[0]
    endif
  endif

  let g:tslime['window'] =  substitute(window, ":.*$" , '', 'g')

  let panes = split(s:TmuxPanes(), "\n")
  if len(panes) == 1
    let g:tslime['pane'] = panes[0]
  else
    let g:tslime['pane'] = input("pane number: ", "", "custom,TmuxPaneNumbers")
    if g:tslime['pane'] == ''
      let g:tslime['pane'] = panes[0]
    endif
  endif
endfunction

vmap <unique> <Plug>SendSelectionToTmux "ry :call SendToTmux(@r)<CR>
nmap <unique> <Plug>NormalModeSendToTmux vip <Plug>SendSelectionToTmux

nmap <unique> <Plug>SetTmuxVars :call <SID>TmuxVars()<CR>

command! -nargs=* Tmux call SendToTmux('<Args><CR>')
command! -nargs=* TmuxKeys call SendKsysToTmux('<Args>')
