" Main plugin logic

fun! vwm#close(name)
  let l:node_index = util#lookup_node(a:name)
  if l:node_index == -1
    return -1
  endif
  let l:node = g:vwm#layouts[l:node_index]

  let l:Funcr = function('s:close_helper', [l:node.cache])
  let l:FRaftr = function('s:deactivate')
  call util#traverse(l:node, v:null, v:null, l:FRaftr, v:null, l:Funcr, 1, 1)
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

fun! s:deactivate(node, trash)
  let a:node['active'] = 0
endfun

fun! vwm#open(name)
  let l:nodeIndex = util#lookup_node(a:name)
  if l:nodeIndex == -1
    return -1
  endif

  let l:node = g:vwm#layouts[l:nodeIndex]
  let l:node.bid = bufnr('%')
  let l:hv = 0

  if util#node_has_vert(l:node)
    let l:hv = 1
    let l:FClose = function('s:close_helper', [1])
    let l:FDct = function('s:deactivate')
    let l:hnodes = util#filter_hnodes(util#active_nodes())

  "If this root node contains a vertical split, first save then close all active horizantal splits
    for hnode in l:hnodes
      call util#traverse(hnode, v:null, v:null, l:FDct, v:null, l:FClose, 1, 1)
    endfor

  endif

  let l:Primer = function('s:populate_root')
  let l:RAftr = function('s:update_root')
  let l:FBfr = function('s:populate_child')
  let l:FAftr = function('s:fill_winnode')
  let l:FRbr = function('s:ex_root_bfr')

  " Begin winnode population
  call util#traverse(l:node, l:Primer, l:FRbr, l:RAftr, l:FBfr, l:FAftr, 1, 1)

  " Restore hsplits
  if l:hv

    for hnode in l:hnodes
      call util#traverse(hnode, l:Primer, v:null, l:RAftr, l:FBfr, l:FAftr, 0, 1)
    endfor

  endif
endfun

fun! s:ex_root_bfr(root)
  call util#execute_cmds(a:root.bfr)
endfun

fun! s:ex_root_aftr(root)
  call util#execute_cmds(a:root.aftr)
endfun

fun! s:update_root(root, def)
  call s:update_node(a:root, a:def)

  if exists('a:root.fid') > 0 && util#buf_active(a:root.fid)
    execute(bufwinnr(a:root.fid) . 'wincmd w')
  endif
  if exists('a:root.aftr')
    call s:ex_root_aftr(a:root)
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

  let a:node['active'] = 1
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
    call util#execute_cmds(a:node.restore)
    return bufnr('%')
  endif

  " Otherwise create the buff and force it to be in the current window
  call util#execute_cmds(a:node.init)
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

