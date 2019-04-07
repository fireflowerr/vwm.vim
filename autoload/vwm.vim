" Main plugin logic

fun! vwm#close(name)
  let l:node_index = util#lookup_node(a:name)
  if l:node_index == -1
    return -1
  endif
  let g:vwm#layouts[l:node_index].active = 0
  let l:node = g:vwm#layouts[l:node_index]

  let l:Funcr = function('s:close_helper', [l:node.cache])
  call util#traverse(l:node, v:null, v:null, l:Funcr, v:null)
endfun

fun! s:close_helper(cache, node, ori)
  if util#buf_active(a:node["bid"])
    if a:cache
      execute(bufwinnr(a:node.bid) . 'wincmd w')
      close
    else
      execute(a:node.bid . 'bw')
    endif
  endif
endfun

fun! vwm#open(name)
  " Check if provided name is a defined layout
  let l:nodeIndex = util#lookup_node(a:name)
  if l:nodeIndex == -1
    return -1
  endif

  " Mark layout as active, save current buf id for returning to.
  let g:vwm#layouts[l:nodeIndex].active = 1
  let l:node = g:vwm#layouts[l:nodeIndex]

  let l:Funcr = function('s:close_helper', [l:node.cache])
  call util#traverse(l:node, v:null, v:null, l:Funcr, v:null)

  let l:bid = bufwinnr('%')
  let l:focus = 0

  " Begin recursive layout population
  if util#node_has_child(l:node, 'left')
    let l:mod = l:node.abs ? 'to' : ''
    execute('vert ' . l:mod . ' ' . 'new')
    let l:res = s:open_main(l:node.left, l:node.unlisted, 1, 0)
    let g:vwm#layouts[l:nodeIndex].left = l:res[0]
    let l:focus = l:res[1]
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
  if util#node_has_child(l:node, 'right')
    let l:mod = l:node.abs ? 'bo' : 'bel'
    execute('vert ' . l:mod . ' ' . 'new')
    let l:res = s:open_main(l:node.right, l:node.unlisted, 1, 0)
    let g:vwm#layouts[l:nodeIndex].right = l:res[0]
    let l:focus = l:res[1]
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
  if util#node_has_child(l:node, 'top')
    let l:mod = l:node.abs ? 'to' : ''
    execute(l:mod . ' ' . 'new')
    let l:res = s:open_main(l:node.top, l:node.unlisted, 0, 0)
    let g:vwm#layouts[l:nodeIndex].top = l:res[0]
    let l:focus = l:res[1]
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
  if util#node_has_child(l:node, 'bot')
    let l:mod = l:node.abs ? 'bo' : 'bel'
    execute(l:mod . ' ' . 'new')
    let l:res = s:open_main(l:node.bot, l:node.unlisted, 0, 0)
    let g:vwm#layouts[l:nodeIndex].bot = l:res[0]
    let l:focus = l:res[1]
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')

  "Focus the specified node, otherwise leave focus at origin
  if l:focus
    execute(bufwinnr(l:focus) . 'wincmd w')
  endif
endfun

fun! s:update_node(node, ori, val)
  if a:ori == 1
    let a:node.left = a:val
  elseif a:ori == 2
    let a:node.right = a:val
  elseif a:ori == 3
    let a:node.top = a:val
  elseif a:ori == 4
    let a:node.bot = a:val
  else
    echoerr "unexpected val passed to s:update_node(...)"
  endif
endfun

fun! s:populate_root(node, ori)
  if l:node.abs

    if a:ori == 1
      vert to new
    elseif a:ori == 2
      vert bo new
    elseif a:ori == 3
      to new
    elseif a:ori == 4
      bo new
    else
      echoerr "unexpected val passed to s:populate_root(...)"
    endif

  else
    call s:populate_child(a:node, a:ori)
  endif
endfun

fun! s:populate_child(node, ori)
  if a:ori == 1
    vert abo new
  elseif a:ori == 2
    vert bel new
  elseif a:ori == 3
    abo new
  elseif a:ori == 4
    bel new
  else
    echoerr "unexpected val passed to s:populate_root(...)"
  endif
endfun

fun! s:open_main(node, unlisted, isVert, focus)
  call util#tmp_setlocal()
  let l:tmp_bid = bufnr('%')

  if util#node_has_child(a:node, 'left')
    vert new
    let l:res = s:open_main(a:node.left, a:unlisted, 1, a:node.focus)
    let a:node.left = l:res[0]
    let a:node.focus = l:res[1]
    execute(bufwinnr(l:tmp_bid) . 'wincmd w')
  endif

  if util#node_has_child(a:node, 'right')
    vert belowright new
    let l:res = s:open_main(a:node.right, a:unlisted, 1, a:node.focus)
    let a:node.right = l:res[0]
    let a:node.focus = l:res[1]
    execute(bufwinnr(l:tmp_bid) . 'wincmd w')
  endif
  if util#node_has_child(a:node, 'top')
    new
    let l:res = s:open_main(a:node.top, a:unlisted, 0, a:node.focus)
    let a:node.top = l:res[0]
    let a:node.focus = l:res[1]
    execute(bufwinnr(l:tmp_bid) . 'wincmd w')
  endif

  if util#node_has_child(a:node, 'bot')
    belowright new
    let l:res = s:open_main(a:node.bot, a:unlisted, 0, a:node.focus)
    let a:node.bot = l:res[0]
    let a:node.focus = l:res[1]
    execute(bufwinnr(l:tmp_bid) . 'wincmd w')
  endif

  call util#resz_winnode(a:node, a:isVert)
  let a:node.bid = s:place_content(a:node)
  call util#resz_winnode(a:node, a:isVert)
  call util#format_winnode(a:node, a:unlisted, a:isVert)
  let a:node.focus = a:node.focus == 0 ? a:focus : a:node.bid
  return [a:node, a:node.focus]
endfun

fun! vwm#toggle(name)
  let l:nodeIndex = util#lookup_node(a:name)
  if l:nodeIndex == -1
    return -1
  endif
  let l:node = g:vwm#layouts[l:nodeIndex]

  if l:node.active
    call vwm#close(a:name)
  else
    call vwm#open(a:name)
  endif
endfun

fun! vwm#close_all()
  for node in util#active_nodes()
    call s:close_main(node, node.cache)
  endfor
endfun

fun! s:place_content(node)
  let l:init_buf = bufnr('%')
  let l:init_wid = bufwinnr(l:init_buf)

  let l:init_last = bufwinnr('$')

  " If buf exists, place it in current window and kill tmp buff
  if util#buf_exists(a:node.bid)
    execute(a:node.bid . 'b')
    call s:execute_cmds(a:node.restore)
    return bufnr('%')
  endif

  " Otherwise create the buff and force it to be in the current window
  call s:execute_cmds(a:node.init)
  let l:final_last = bufwinnr('$')
  if l:init_last != l:final_last

    echoerr l:init_last
    echoerr l:final_last

    " let l:final_buf = winbufnr(l:final_last)
    " execute(l:final_last . 'wincmd w')
    " close
    " execute(l:init_wid . 'wincmd w')
    " execute(l:final_buf . 'b')
  endif
  return bufnr('%')
endfun

" Execute layout defined commands. Accept funcrefs and Strings
fun! s:execute_cmds(cmds)
  for Cmd in a:cmds
    if type(Cmd) == 2
      call Cmd()
    else
      execute(Cmd)
    endif
  endfor
endfun

