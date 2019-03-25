" Main plugin logic

fun! vwm#close(name)
  let l:node_index = s:lookup_node(a:name)
  if l:node_index == -1
    return -1
  endif
  let g:vwm#layouts[l:node_index].active = 0
  let l:node = g:vwm#layouts[l:node_index]
  call s:close_main(l:node, l:node.cache, l:node.unlisted)
endfun

fun! s:close_main(node, cache, unlisted)
  if s:buf_active(a:node["bid"])
    if a:cache
      execute(bufwinnr(a:node.bid) . 'wincmd w')
      if a:unlisted
        execute('setlocal nobuflisted')
      endif
      execute('wincmd c')
    else
      execute(a:node.bid . 'bd')
    endif
  endif

  if s:node_has_child(a:node, 'left')
    call s:close_main(a:node.left, a:cache, a:unlisted)
  endif
  if s:node_has_child(a:node, 'right')
    call s:close_main(a:node.right, a:cache, a:unlisted)
  endif
  if s:node_has_child(a:node, 'top')
    call s:close_main(a:node.top, a:cache, a:unlisted)
  endif
  if s:node_has_child(a:node, 'bot')
    call s:close_main(a:node.bot, a:cache, a:unlisted)
  endif

endfun

fun! vwm#open(name)
  " Check if provided name is a defined layout
  let l:nodeIndex = s:lookup_node(a:name)
  if l:nodeIndex == -1
    return -1
  endif

  " Mark layout as active, save current buf id for returning to.
  let g:vwm#layouts[l:nodeIndex].active = 1
  let l:node = g:vwm#layouts[l:nodeIndex]
  call s:close_main(l:node, l:node.cache, l:node.unlisted)
  let l:bid = bufwinnr('%')

  " Begin recursive layout population
  if s:node_has_child(l:node, 'left')
    let l:mod = l:node.abs ? 'to' : ''
    execute('vert ' . l:mod . ' ' . 'new')
    let g:vwm#layouts[l:nodeIndex].left = s:open_main(l:node.left, l:node.unlisted, 1)
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
  if s:node_has_child(l:node, 'right')
    let l:mod = l:node.abs ? 'bo' : 'bel'
    execute('vert ' . l:mod . ' ' . 'new')
    let g:vwm#layouts[l:nodeIndex].right = s:open_main(l:node.right, l:node.unlisted, 1)
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
  if s:node_has_child(l:node, 'top')
    let l:mod = l:node.abs ? 'to' : ''
    execute(l:mod . ' ' . 'new')
    let g:vwm#layouts[l:nodeIndex].top = s:open_main(l:node.top, l:node.unlisted, 0)
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
  if s:node_has_child(l:node, 'bot')
    let l:mod = l:node.abs ? 'bo' : 'bel'
    execute(l:mod . ' ' . 'new')
    let g:vwm#layouts[l:nodeIndex].bot = s:open_main(l:node.bot, l:node.unlisted, 0)
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
endfun

fun! s:open_main(node, unlisted, isVert)
  let l:node = a:node
  let l:node.bid = s:place_content(a:node)

  if s:node_has_child(a:node, 'left')
    vert new
    let l:node.left = s:open_main(a:node.left, a:unlisted, 1)
  endif
  execute(bufwinnr(l:node.bid) . 'wincmd w')
  if s:node_has_child(a:node, 'right')
    vert belowright new
    let l:node.right = s:open_main(a:node.right, a:unlisted, 1)
  endif
  execute(bufwinnr(l:node.bid) . 'wincmd w')
  if s:node_has_child(a:node, 'top')
    new
    let l:node.top = s:open_main(a:node.top, a:unlisted, 0)
  endif
  execute(bufwinnr(l:node.bid) . 'wincmd w')
  if s:node_has_child(a:node, 'bot')
    belowright new
    let l:node.bot = s:open_main(a:node.bot, a:unlisted, 0)
  endif
  execute(bufwinnr(l:node.bid) . 'wincmd w')
  call s:format_winnode(a:node, a:unlisted, a:isVert) 
  return l:node
endfun

fun! vwm#toggle(name)
  let l:nodeIndex = s:lookup_node(a:name)
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

fun! s:place_content(node)
  let l:init_buf = bufnr('%')
  let l:init_wid = bufwinnr(l:init_buf)

  " If buf exists, place it in current window and kill tmp buff
  if s:buf_exists(a:node.bid)
    execute(a:node.bid . 'b')
    execute(l:init_buf . 'bw')
    execute_cmds(a:node.restore)
    return bufnr('%')
  endif

  " Otherwise create the buff and force it to be in the current window
  call s:execute_cmds(a:node.init)
  let l:final_buf = bufnr('$')
  let l:final_wid = bufwinnr(l:final_buf)
  if l:init_wid != l:final_wid
    execute(l:final_wid . 'wincmd w')
    wincmd c
    execute(l:init_wid . 'wincmd w')
    execute(l:final_buf . 'b')
    execute(l:init_buf . 'bw')
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

fun! s:buf_active(bid)
  return bufwinnr(a:bid) == -1 ? 0 : 1
endfun

fun! s:buf_exists(bid)
  return bufname(a:bid) =~ '^$' ? 0 : 1
endfun

fun! s:node_has_child(node, pos)
  if eval("exists('a:node." . a:pos . "')")
    return eval('len(a:node.' . a:pos . ')') ? 1 : 0
  endif
  return 0
endfun

fun! s:lookup_node(name)
  let l:i = 0
  for layout_root in g:vwm#layouts 
    let l:layout_name = layout_root.name
    if l:layout_name =~ a:name
      return l:i
    endif
    let l:i = l:i + 1
  endfor
  execute("echoerr '" . a:name . " not in list of root nodes'")
  return -1
endfun

" Apply layout window formattings based on node and root node configurations
fun! s:format_winnode(node, unlisted, isVert)
  if a:node.sz
    if a:isVert
      execute('vert resize ' . a:node.sz)
    else
      execute('resize ' . a:node.sz)
    endif
  endif
  if a:unlisted
    setlocal nobuflisted
  endif
  if a:node.fixed
    if a:isVert
      setlocal winfixwidth
    else
      setlocal winfixheight
    endif
  endif
endfun
