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
  if type(a:name) == 1
    let l:node_index = util#lookup_node(a:name)
    if l:node_index == -1
      return -1
    endif
    let l:node = g:vwm#layouts[l:node_index]
  elseif type(a:name) == 4
    let l:node = a:name
  else
    let l:err = 'unsupported type ' . type(a:name)
  endif

  call util#execute_cmds(l:node.clsBfr)
  let l:Funcr = function('s:close_helper', [l:node.cache])
  call util#traverse(l:node, v:null, v:null, v:null, l:Funcr, 1, 1)
  call s:deactivate(l:node)

  call util#execute_cmds(l:node.clsAftr)
  call vwm#repop_active()
endfun

fun! s:close_helper(cache, node, t1, t2)
  if util#buf_active(a:node["bid"])
    if a:cache
      execute(bufwinnr(a:node.bid) . 'wincmd w')
      close
    else
      execute(a:node.bid . 'bw')
    endif
  endif
endfun

fun! s:deactivate(node)
  let a:node['active'] = 0
endfun

fun! s:open(name)
  if type(a:name) == 1
    let l:nodeIndex = util#lookup_node(a:name)
    if l:nodeIndex == -1
      return -1
    endif
    let l:node = g:vwm#layouts[l:nodeIndex]
  elseif type(a:name) == 4
    let l:node = a:name
  else
    let l:err = 'unsupported type ' . type(a:name)
    echoerr l:err
  endif

  call util#execute_cmds(l:node.opnBfr)

  let l:node.bid = bufnr('%')
  let l:node.active = 1
  call vwm#repop_active()
endfun

fun! vwm#repop_active()
  let l:FClose = function('s:close_helper', [1])
  let l:FDct = function('s:deactivate')
  let l:active = util#active_nodes()

  for anode in l:active
    call util#traverse(anode, v:null, v:null, v:null, l:FClose, 1, 1)
  endfor

  let l:Primer = function('s:populate_root')
  let l:FBfr = function('s:populate_child')
  let l:FAftr = function('s:fill_winnode')
  let l:FRAftr = function('s:update_root')


  let l:p = g:vwm#force_vert_first
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

fun! s:update_root(root, def)
  call s:update_node(a:root, a:def)

  if exists('a:root.fid') > 0 && util#buf_active(a:root.fid)
    execute(bufwinnr(a:root.fid) . 'wincmd w')
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

fun! s:close_all()
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
