" vwm.vim core

"----------------------------------------------Imports----------------------------------------------
" Imports from vwm#util. Can easliy generalize later if need be
fun! s:import(...)

    if a:000 != [v:null] && len(a:000)
      let l:util_snr = vwm#util#SID()

      for l:fname in a:000
        execute('let s:' . l:fname . ' = function("<SNR>' . l:util_snr . '_' . l:fname . '")')
      endfor

    endif
endfun

fun! vwm#init()
  call s:import('execute', 'get', 'buf_active', 'wipe_aux_bufs', 'get_active_bufs')
endfun

"------------------------------------------Command backers------------------------------------------
fun! vwm#close(...)
  for l:target in a:000
    call s:close(l:target)
  endfor
endfun

fun! vwm#open(...)
  if a:000 != [v:null] && len(a:000)
    call call('s:open', a:000)
  endif
endfun

fun! vwm#toggle(...)
  if a:000 != [v:null] && len(a:000)
    call call('s:toggle', a:000)
  endif
endfun

fun! vwm#resize(...)
  for l:target in a:000
    call s:resize(l:target)
  endfor
endfun

fun! vwm#refresh()
  let l:active = vwm#util#active()

  call call('vwm#close', l:active)
  call call('vwm#open', l:active)
endfun

"-----------------------------------------Layout population-----------------------------------------
" Target can be a root node or root node name
" TODO: Indictate the autocmd replacement available for safe_mode. QuitPre autocmd event
fun! s:close(target)
  let l:target = type(a:target) == 1 ? vwm#util#lookup(a:target) : a:target
  call vwm#util#traverse(l:target, l:target.clsBfr, function('s:close_helper')
        \, v:true, v:true, 0, {})

  let l:target.active = 0
endfun


" Because the originating buffer is considered a root node, closing it blindly is undesirable.
fun! s:close_helper(node, type, cache)
  if a:type == 0
    call s:execute(s:get(a:node.clsAftr))

  else
    if s:buf_active(a:node["bid"])
      execute(bufwinnr(a:node.bid) . 'wincmd w')
      close
    endif

  endif
endfun

" Opens layout node by name or by dictionary def. DIRECTLY MUTATES DICT
fun! s:open(...)

  let l:cache = {}
  if g:vwm#pop_order == 'both'
    for l:t in a:000

      let l:target = type(l:t) == 1 ? vwm#util#lookup(l:t) : l:t
      let l:target.active = 1

      call s:execute(s:get(l:target.opnBfr))
      " If both populate layout in one traversal. Else do either vert or horizontal before the other
      call vwm#util#traverse(l:target, function('s:open_helper_bfr'), function('s:open_helper_aftr')
            \, v:true, v:true, 0, l:cache)
      call s:execute(s:get(l:target.opnAftr))

    endfor

  else
    let l:vert = g:vwm#pop_order == 'vert'

    for l:t in a:000
      let l:target = type(l:t) == 1 ? vwm#util#lookup(l:t) : l:t
      call s:execute(s:get(l:target.opnBfr))
      call vwm#util#traverse(l:target, function('s:open_helper_bfr'), function('s:open_helper_aftr')
            \,!l:vert, l:vert, 0, l:cache)
    endfor

    for l:t in a:000
      let l:target = type(l:t) == 1 ? vwm#util#lookup(l:t) : l:t
      let l:target.active = 1
      call vwm#util#traverse(l:target, function('s:open_helper_bfr'), function('s:open_helper_aftr')
            \, l:vert, !l:vert, 0, l:cache)
      call s:execute(s:get(l:target.opnAftr))
    endfor

  endif

  if exists('l:cache.focus')
    execute(bufwinnr(l:cache.focus) . 'wincmd w')
  endif
endfun

fun! s:open_helper_bfr(node, type, cache)
  if a:type == 0
    let a:cache.set_all = a:node.set_all
  endif

  " Create new windows as needed. Float is a special case that cannot be handled here.
  if a:type >= 1 && a:type <= 4

    " If abs use absolute positioning else use relative
    if a:node.abs
      call s:new_abs_win(a:type)
    else
      call s:new_std_win(a:type)
    endif

    " Make window proper size
    call s:mk_tmp()
    call s:resize_node(a:node, a:type)
  endif

endfun

" Force the result of commands to go in to the desired window
fun! s:open_helper_aftr(node, type, cache)
  let l:init_buf = bufnr('%')

  " If buf exists, place it in current window and kill tmp buff
  if bufexists(a:node.bid)
    call s:restore_content(a:node)
  " Otherwise capture the buffer and move it to the current window
  else
    execute(bufwinnr(l:init_buf) . 'wincmd w')
    let a:node.bid = s:capture_buf(a:node, a:type)

    if !s:buf_active(a:node.bid)
      call s:place_buf(a:node, a:type)
    endif

  endif

  " apply node.set as setlocal
  if !empty(a:node.set)
    call s:set_buf(a:node.set)
  endif

  if !empty(a:cache.set_all)
    call s:set_buf(a:cache.set_all)
  endif

  " Whatever the last occurrence of focus is will be focused
  if s:get(a:node.focus)
    let a:cache.focus = a:node.bid
  endif

  if a:type == 0 && g:vwm#eager_render
    redraw
  endif

  return bufnr('%')
endfun

fun! s:toggle(...)
  let l:on = []
  let l:off = []

  for l:entry in a:000

    let l:target = type(l:entry) == 1 ? vwm#util#lookup(l:entry) : l:entry
    if l:target.active
      let l:on += [l:target]
    else
      let l:off += [l:target]
    endif

  endfor

  if !empty(l:on)
    call call('vwm#close', l:on)
  endif

  if !empty(l:off)
    call call('vwm#open', l:off)
  endif

endfun

" Resize a root node and all of its children
fun! s:resize(target)
  let l:target = type(a:target) == 1 ? vwm#util#lookup(a:target) : a:target
  call vwm#util#traverse(l:target, function('s:resize_helper'), v:null, v:true, v:true, 0, {})
endfun

"---------------------------------------------Auxiliary---------------------------------------------
fun! s:new_abs_win(type)
  if a:type == 1
    vert to new
  elseif a:type == 2
    vert bo new
  elseif a:type == 3
    to new
  elseif a:type == 4
    bo new
  else
    echoerr "unexpected val passed to vwm#open"
    return -1
  endif
endfun

fun! s:new_std_win(type)
  if a:type == 1
    vert abo new
  elseif a:type == 2
    vert bel new
  elseif a:type == 3
    abo new
  elseif a:type == 4
    bel new
  else
    echoerr "unexpected val passed to vwm#open"
    return -1
  endif
endfun

fun! s:restore_content(node)
  execute(a:node.bid . 'b')
  call s:execute(s:get(a:node.restore))
endfun

" Create the buffer, close it's window, and capture it!
" Using tabnew prevents unwanted resizing
fun! s:capture_buf(node, type)
  "If there are no commands to run, stop
  if !len(a:node.init)
    return bufnr('%')
  endif

  let l:init_bufs = s:get_active_bufs()

  tabnew
  let l:tmp_bid = bufnr('%')

  let l:init_win = winnr()
  let l:init_last = bufwinnr('$')
  call s:execute(s:get(a:node.init))

  let l:final_last = bufwinnr('$')

  if l:init_last != l:final_last
    let l:ret = winbufnr(l:final_last)
    execute(l:tmp_bid . 'bw')
  else
    let l:ret = winbufnr(l:init_win)
  endif

  let l:t_v = s:get_tab_vars()

  set ei=BufDelete
  let l:ei = &ei
  call s:close_tab()
  call s:wipe_aux_bufs(l:init_bufs, l:ret)
  execute('set ei=' . l:ei)

  call s:apply_tab_vars(l:t_v)

  return l:ret

endfun

" Places the target node buffer in the current window
fun! s:place_buf(node, type)
  if a:type == 5
    call nvim_open_win(a:node.bid, s:get(a:node.focus),
          \   { 'relative': s:get(a:node.relative)
          \   , 'row': s:get(a:node.y)
          \   , 'col': s:get(a:node.x)
          \   , 'width': s:get(a:node.width)
          \   , 'height': s:get(a:node.height)
          \   , 'focusable': s:get(a:node.focusable)
          \   , 'anchor': s:get(a:node.anchor)
          \   }
          \ )
  else
    execute(a:node.bid . 'b')
  endif
endfun

fun! s:mk_tmp()
  setlocal bt=nofile bh=wipe noswapfile
endfun

" Apply setlocal entries
fun! s:set_buf(set)
  let l:set_cmd = 'setlocal'
  for val in s:get(a:set)
    let l:set_cmd = l:set_cmd . ' ' . val
  endfor
  execute(l:set_cmd)
endfun

" Resize some or all nodes.
fun! s:resize_node(node, type)

  if s:get(a:node.v_sz)
    execute('vert resize ' . s:get(a:node.v_sz))
  endif
  if s:get(a:node.h_sz)
    execute('resize ' . s:get(a:node.h_sz))
  endif

endfun

" Resize as the driving traverse and do
fun! s:resize_helper(node, type, cache)

  if  a:type >= 1 && a:type <= 4

    if s:buf_active(a:node.bid)
      execute(bufwinnr(a:node.bid) . 'wincmd w')
      call s:resize_node(a:node, a:type)
    endif

  endif
endfun

fun! s:get_tab_vars()
  let l:tab_raw = execute('let t:')
  let l:tab_vars = split(l:tab_raw, '\n')

  let l:ret = {}
  for l:v in l:tab_vars
    let l:v_name = substitute(l:v, '\(\S\+\).*', '\1', 'g')
    execute('let l:tmp = ' . l:v_name)
    let l:ret[l:v_name] = l:tmp
  endfor

  return l:ret
endfun

fun! s:apply_tab_vars(vars)
  for l:v in keys(a:vars)
    execute('let ' . l:v . ' = a:vars[l:v]')
  endfor
endfun

fun! s:close_tab()
  let l:tid = tabpagenr()
  for l:bid in tabpagebuflist()
    execute(bufwinnr(l:bid) . 'hide')
  endfor
endfun
