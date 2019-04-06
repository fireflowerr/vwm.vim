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
      execute('close')
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
  let l:focus = 0

  " Begin recursive layout population
  if s:node_has_child(l:node, 'left')
    let l:mod = l:node.abs ? 'to' : ''
    execute('vert ' . l:mod . ' ' . 'new')
    let l:res = s:open_main(l:node.left, l:node.unlisted, 1, 0)
    let g:vwm#layouts[l:nodeIndex].left = l:res[0]
    let l:focus = l:res[1]
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
  if s:node_has_child(l:node, 'right')
    let l:mod = l:node.abs ? 'bo' : 'bel'
    execute('vert ' . l:mod . ' ' . 'new')
    let l:res = s:open_main(l:node.right, l:node.unlisted, 1, 0)
    let g:vwm#layouts[l:nodeIndex].right = l:res[0]
    let l:focus = l:res[1]
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
  if s:node_has_child(l:node, 'top')
    let l:mod = l:node.abs ? 'to' : ''
    execute(l:mod . ' ' . 'new')
    let l:res = s:open_main(l:node.top, l:node.unlisted, 0, 0)
    let g:vwm#layouts[l:nodeIndex].top = l:res[0]
    let l:focus = l:res[1]
  endif
  execute(bufwinnr(l:bid) . 'wincmd w')
  if s:node_has_child(l:node, 'bot')
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

fun! s:open_main(node, unlisted, isVert, focus)
  let l:tmp_bid = bufnr('%')

  if s:node_has_child(a:node, 'left')
    vert new
    let l:res = s:open_main(a:node.left, a:unlisted, 1, a:node.focus)
    let a:node.left = l:res[0]
    let a:node.focus = l:res[1]
    execute(bufwinnr(l:tmp_bid) . 'wincmd w')
  endif

  if s:node_has_child(a:node, 'right')
    vert belowright new
    let l:res = s:open_main(a:node.right, a:unlisted, 1, a:node.focus)
    let a:node.right = l:res[0]
    let a:node.focus = l:res[1]
    execute(bufwinnr(l:tmp_bid) . 'wincmd w')
  endif

  if s:node_has_child(a:node, 'top')
    new
    let l:res = s:open_main(a:node.top, a:unlisted, 0, a:node.focus)
    let a:node.top = l:res[0]
    let a:node.focus = l:res[1]
    execute(bufwinnr(l:tmp_bid) . 'wincmd w')
  endif

  if s:node_has_child(a:node, 'bot')
    belowright new
    let l:res = s:open_main(a:node.bot, a:unlisted, 0, a:node.focus)
    let a:node.bot = l:res[0]
    let a:node.focus = l:res[1]
    execute(bufwinnr(l:tmp_bid) . 'wincmd w')
  endif

  call s:resz_winnode(a:node, a:isVert)
  let a:node.bid = s:place_content(a:node)
  call s:resz_winnode(a:node, a:isVert)
  call s:format_winnode(a:node, a:unlisted, a:isVert)
  let a:node.focus = a:node.focus == 0 ? a:focus : a:node.bid
  return [a:node, a:node.focus]
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

  let l:init_last = bufwinnr('$')

  " If buf exists, place it in current window and kill tmp buff
  if s:buf_exists(a:node.bid)
    execute(a:node.bid . 'b')
    execute(l:init_buf . 'bw')
    call s:execute_cmds(a:node.restore)
    return bufnr('%')
  endif

  " Otherwise create the buff and force it to be in the current window
  call s:execute_cmds(a:node.init)
  let l:final_last = bufwinnr('$')
  if l:init_last != l:final_last

    let l:final_buf = winbufnr(l:final_last)
    execute(l:final_last . 'wincmd w')
    close
    execute(l:init_wid . 'wincmd w')
    execute(l:final_buf . 'b')
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

fun! s:resz_winnode(node, isVert)
  if a:node.sz
    if a:isVert
      execute('vert resize ' . a:node.sz)
    else
      execute('resize ' . a:node.sz)
    endif
  endif
endfun
