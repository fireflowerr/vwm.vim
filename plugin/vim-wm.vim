fun! s:validate(node)
  let l:node = s:normalize_node(a:node)

  if !s:node_is_valid(l:node)
    execute('echoerr "' . string(a:node) . ' is invalid"')
    return 0
  endif

  return l:node
endfun

fun! s:node_is_valid(node)
  return len(a:node) == 12 ? 1 : 0
endfun

fun! s:normalize_node(node)
  let l:node = a:node
  if !exists('a:node.sz')
    let l:node['sz'] = ''
  endif
  if !exists('a:node.bid')
    let l:node['bid'] = -1
  endif
  if !exists('a:node.name')
    let l:node['name'] = ''
  endif
  if !exists('a:node.cache')
    let l:node['cache'] = 1
  endif
  if !exists('a:node.unlisted')
    let l:node['unlisted'] = 1
  endif
  if !exists('a:node.init')
    let l:node['init'] = []
  endif
  if !exists('a:node.restore')
    let l:node['restore'] = []
  endif
  if !exists('a:node.abs')
    let l:node['abs'] = 1
  endif
  if s:node_has_child(a:node, 'left')
    call s:normalize_node(a:node.left)
  else
    let l:node['left'] = {}
  endif
  if s:node_has_child(a:node, 'right')
    call s:normalize_node(a:node.right)
  else
    let l:node['right'] = {}
  endif
  if s:node_has_child(a:node, 'top')
    call s:normalize_node(a:node.top)
  else
    let l:node['top'] = {}
  endif
  if s:node_has_child(a:node, 'bot')
    call s:normalize_node(a:node.bot)
  else
    let l:node['bot'] = {}
  endif

  return l:node
endfun

fun! s:is_empty(clct)
  return len(a:clct) == 0 ? 0 : 1
endfun

fun! s:node_has_child(node, pos)
  if eval("exists('a:node." . a:pos . "')")
    return eval('len(a:node.' . a:pos . ')') ? 1 : 0
  endif
  return 0
endfun

fun! s:init()  
  let l:i = 0
  for node in g:vwm#layouts 
    let g:vwm#layouts[i] = s:validate(node) 
    let l:i = l:i + 1
  endfor
endfun

call s:init()

command! VwmRefresh call s:init()

command! -nargs=1 VwmOpen call vwm#open(<q-args>)
command! -nargs=1 VwmClose call vwm#close(<q-args>)
