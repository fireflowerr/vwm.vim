let s:def_layt = {
      \  'name': 'default',
      \  'bot':
      \  {
      \    'sz': 12,
      \    'init': ['setlocal nonumber', 'term bash'],
      \    'left':
      \    {
      \      'init': ['setlocal nonumber','term bash']
      \    }
      \  }
      \}

fun! s:normalize_root(node)
  let a:node['root'] = 1
endfun

fun! s:normalize_node(node)
  if !exists('a:node.sz')
    let a:node['sz'] = 0
  endif
  if !exists('a:node.bid')
    let a:node['bid'] = -1
  endif
  if !exists('a:node.name')
    let a:node['name'] = ''
  endif
  if !exists('a:node.cache')
    let a:node['cache'] = 1
  endif
  if !exists('a:node.init')
    let a:node['init'] = []
  endif
  if !exists('a:node.restore')
    let a:node['restore'] = []
  endif
  if !exists('a:node.abs')
    let a:node['abs'] = 1
  endif
  if !exists('a:node.active')
    let a:node['active'] = 0
  endif
  if !exists('a:node.fixed')
    let a:node['fixed'] = 0
  endif
  if !exists('a:node.focus')
    let a:node['focus'] = 0
  endif

  " set is just a convience wrapper for setlocal cmd
  if !exists('a:node.set')
    let a:node['set'] = ['bh=hide', 'nobl']
  endif

  let l:set_cmd = 'setlocal'
  for val in a:node['set']
    let l:set_cmd += ' ' . val
  endfor
  let a:node['init'] += [l:set_cmd]

  if s:node_has_child(a:node, 'left')
    call s:normalize_node(a:node.left)
  else
    let a:node['left'] = {}
  endif
  if s:node_has_child(a:node, 'right')
    call s:normalize_node(a:node.right)
  else
    let a:node['right'] = {}
  endif
  if s:node_has_child(a:node, 'top')
    call s:normalize_node(a:node.top)
  else
    let a:node['top'] = {}
  endif
  if s:node_has_child(a:node, 'bot')
    call s:normalize_node(a:node.bot)
  else
    let a:node['bot'] = {}
  endif

  return a:node
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
  if exists('g:vwm#layouts')
    let l:i = 0
    for node in g:vwm#layouts
      call s:normalize_root(node)
      call s:normalize_node(node)
      let l:i = l:i + 1
    endfor
  else
    let g:vwm#layouts =[s:def_layt]
    call s:init()
  endif
endfun

call s:init()

command! VwmRefresh call s:init()
command! -nargs=1 VwmOpen call vwm#open(<q-args>)
command! -nargs=1 VwmClose call vwm#close(<q-args>)
command! -nargs=1 VwmToggle call vwm#toggle(<q-args>)
