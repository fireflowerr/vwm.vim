" Main plugin logic
fun! vwm#close(...)
  for name in a:000
    call s:close(name)
  endfor
endfun

fun! vwm#open(...)
  for name in a:000
    call s:open(name)
  endfor
endfun

fun! vwm#toggle(...)
  for name in a:000
    call s:toggle(name)
  endfor
endfun

fun! s:close(name)
  let l:node = s:getNode(a:name)

  if util#node_has_child(l:node, 'float')
    call s:close_helper(l:node.cache, l:node.float, v:null, v:null)
    let l:node.active = 0
    return 0
  endif

  call util#execute_cmds(l:node.clsBfr)
  let l:Funcr = function('s:close_helper', [l:node.cache])
  call util#traverse(l:node, v:null, v:null, v:null, l:Funcr, 1, 1)
  call s:deactivate(l:node)

  call util#execute_cmds(l:node.clsAftr)

  if g:vwm#safe_mode
    call vwm#resize()
  endif
endfun

fun! s:close_helper(cache, node, t1, t2)
  if util#buf_active(a:node["bid"])
    if a:cache
      execute(bufwinnr(a:node.bid) . 'wincmd w')
      close
    else
      execute(a:node.bid . 'bw!')
    endif
  endif
endfun

fun! s:deactivate(node)
  let a:node['active'] = 0
endfun

fun! s:getNode(node)
  if type(a:node) == 1
    let l:nodeIndex = util#lookup_node(a:node)
    if l:nodeIndex == -1
      return -1
    endif
    return g:vwm#layouts[l:nodeIndex]
  elseif type(a:node) == 4
    return a:node
  else
    let l:err = 'unsupported type ' . type(a:node)
    echoerr l:err
    return -1
  endif
  return -1
endfun

fun! s:open(name)
  let l:node = s:getNode(a:name)

  call util#execute_cmds(l:node.opnBfr)

  let l:node.bid = bufnr('%')
  let l:node.active = 1

  if g:vwm#safe_mode
    call vwm#repop_active()
  else
    call vwm#repop_active(l:node)
  endif

  if util#node_has_child(l:node, 'float')
    call s:pop_float(l:node)
  endif

  call util#execute_cmds(l:node.opnAftr)

endfun

fun! s:pop_float(node)
  tabnew
  call s:buf_mktmp()
  let a:node.float.bid = s:place_content(a:node.float)
  tabclose

  call nvim_open_win(a:node.float.bid, a:node.float.focus,
        \   { 'relative': util#get_lazy(a:node.float.relative)
        \   , 'row': util#get_lazy(a:node.float.y)
        \   , 'col': util#get_lazy(a:node.float.x)
        \   , 'width': util#get_lazy(a:node.float.width)
        \   , 'height': util#get_lazy(a:node.float.height)
        \   , 'focusable': util#get_lazy(a:node.float.focusable)
        \   , 'anchor': util#get_lazy(a:node.float.anchor)
        \   }
        \ )
endfun

fun! vwm#resize(...)
  let l:Fbfr = function('s:resz_wrap')
  if a:000 != [v:null] && len(a:000)
    let l:active = a:000
  else
    let l:active = util#active_nodes()
  endif
  for anode in l:active
    call util#traverse(anode, v:null, v:null, l:Fbfr, v:null, 1, 1)
  endfor

endfun

fun! s:resz_wrap(node, ori, fromRoot)
  if util#buf_active(a:node["bid"])
    execute(bufwinnr(a:node.bid) . 'wincmd w')
    call util#resz_winnode(a:node, a:ori)
  endif
endfun


" Closes the target node
fun! vwm#repop_active(...)
  let l:FClose = function('s:close_helper', [1])
  let l:FDct = function('s:deactivate')

  if a:000 != [v:null] && len(a:000)
    let l:active = a:000
  else
    let l:active = util#active_nodes()
  endif
  for anode in l:active
    call util#traverse(anode, v:null, v:null, v:null, l:FClose, 1, 1)
  endfor

  let l:Primer = function('s:populate_root')
  let l:FBfr = function('s:populate_child')
  let l:FAftr = function('s:fill_winnode')
  let l:FRAftr = function('s:update_node')


  let l:p = g:vwm#force_vert_first && g:vwm#safe_mode
  " Restore vsplits
  for vnode in l:active
    call util#traverse(vnode, l:Primer, l:FRAftr, l:FBfr, l:FAftr, !l:p, l:p)
  endfor

  " Restore hsplits
  for hnode in l:active
    call util#traverse(hnode, l:Primer, l:FRAftr, l:FBfr, l:FAftr, l:p, !l:p)
  endfor

  if l:p
    for anode in l:active
      call util#traverse(anode, v:null, v:null, v:null, l:FClose, !l:p, l:p)
    endfor

    for hnode in l:active
      call util#traverse(hnode, l:Primer, l:FRAftr, l:FBfr, l:FAftr, !l:p, l:p)
    endfor
  endif

endfun

fun! s:update_node(node, def)
  for ori in keys(a:def)
    let a:node[ori] = a:def[ori]

    " Put the bid of the buffer to be focused into its parent.
    if a:def[ori].focus > 0
      let a:node['fid'] = a:def[ori].bid
    elseif exists('a:def[' . ori . '].fid')
      let a:node['fid'] = a:def[ori].fid
    endif
  endfor

  if a:node.root
    if exists('a:node.fid')
      execute(bufwinnr(a:node.fid) . 'wincmd w')
    endif
  endif
endfun

fun! s:populate_root(node, ori)
  if a:node.abs

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
      return -1
    endif

    call s:buf_mktmp()
  else
    call s:populate_child(a:node, a:ori)
  endif

endfun

fun! s:populate_child(node, ori, fromRoot)
  if a:fromRoot
    return 0
  endif

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
    return -1
  endif

  call s:buf_mktmp()
endfun

fun! s:buf_mktmp()
  setlocal nobl bh=wipe bt=nofile noswapfile
endfun

fun! s:fill_winnode(node, def, ori)
  call util#resz_winnode(a:node, a:ori)
  let a:node.bid = s:place_content(a:node)
  call util#resz_winnode(a:node, a:ori)
  execute(bufwinnr(a:node.bid) . 'wincmd w')

  call s:update_node(a:node, a:def)
endfun

fun! s:toggle(name)
  let l:nodeIndex = util#lookup_node(a:name)
  if l:nodeIndex == -1
    return -1
  endif
  let l:node = g:vwm#layouts[l:nodeIndex]

  if l:node.active
    call s:close(a:name)
  else
    call s:open(a:name)
  endif
endfun

fun! vwm#close_all()
  for node in util#active_nodes()
    call s:close(node)
  endfor
endfun

fun! s:place_content(node)
  let l:init_buf = bufnr('%')
  let l:init_wid = bufwinnr(l:init_buf)

  let l:init_last = bufwinnr('$')

  " If buf exists, place it in current window and kill tmp buff
  if util#buf_exists(a:node.bid)
    execute(a:node.bid . 'b')
    call util#execute_cmds(a:node.restore)

  " Otherwise create the buff and force it to be in the current window
  else
    call util#execute_cmds(a:node.init)
    let l:final_last = bufwinnr('$')

    if l:init_last != l:final_last
      let l:final_buf = winbufnr(l:final_last)
      execute(l:final_last . 'wincmd w')
      close
      execute(l:init_wid . 'wincmd w')
      execute(l:final_buf . 'b')
    endif
  endif

  let l:set_cmd = 'setlocal'
  for val in a:node['set']
    let l:set_cmd = l:set_cmd . ' ' . val
  endfor
  execute(l:set_cmd)

  return bufnr('%')
endfun

fun! vwm#list_active()
  let l:active = []
  for node in util#active_nodes()
    echom node.name
  endfor
endfun
