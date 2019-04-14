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
  let l:node = a:node
  let l:node['root'] = 1
  if !exists('l:node.name')
    let l:node['name'] = ''
  endif
  if !exists('l:node.abs')
    let l:node['abs'] = 1
  endif
  if !exists('l:node.opnBfr')
    let l:node['opnBfr'] = []
  endif
  if !exists('l:node.opnAftr')
    let l:node['opnAftr'] = []
  endif
  if !exists('l:node.clsBfr')
    let l:node['clsBfr'] = []
  endif
  if !exists('l:node.clsAftr')
    let l:node['clsAftr'] = []
  endif
  if !exists('l:node.active')
    let l:node['active'] = 0
  endif
  if !exists('l:node.cache')
    let l:node['cache'] = 1
  endif
  if exists('l:node.float')
    call s:normalize_float(l:node.float)
  endif
endfun

fun! s:normalize_node(node)

  let a:node['root'] = 0
  if !exists('a:node.sz')
    let a:node['sz'] = 0
  endif
  if !exists('a:node.bid')
    let a:node['bid'] = -1
  endif
  if !exists('a:node.init')
    let a:node['init'] = []
  endif
  if !exists('a:node.restore')
    let a:node['restore'] = []
  endif
  if !exists('a:node.focus')
    let a:node['focus'] = 0
  endif

  " set is just a convience wrapper for setlocal cmd
  if !exists('a:node.set')
    let a:node['set'] = ['bh=hide', 'nobl']
  endif

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

fun! s:normalize_float(node)
  let a:node.root = 0
  if !exists('a:node.x')
    echoerr "Missing key x"
  endif
  if !exists('a:node.y')
    echoerr "Missing key y"
  endif
  if !exists('a:node.width')
    echoerr "Missing key width"
  endif
  if !exists('a:node.height')
    echoerr "Missing key height"
  endif
  if !exists('a:node.relative')
    let a:node['relative'] = 'editor'
  endif
  if !exists('a:node.bid')
    let a:node['bid'] = -1
  endif
  if !exists('a:node.init')
    let a:node['init'] = []
  endif
  if !exists('a:node.restore')
    let a:node['restore'] = []
  endif
  if !exists('a:node.focus')
    let a:node['focus'] = 0
  endif
  if !exists('a:node.focusable')
    let a:node['focusable'] = 1
  endif
  if !exists('a:node.anchor')
    let a:node['anchor'] = 'NW'
  endif

  " set is just a convience wrapper for setlocal cmd
  if !exists('a:node.set')
    let a:node['set'] = ['bh=hide', 'nobl']
  endif
endfun

fun! g:VwmNormalize(node)
  call s:normalize_node(a:node)
  call s:normalize_root(a:node)
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
      call s:normalize_node(node)
      call s:normalize_root(node)
      let l:i = l:i + 1
    endfor
  else
    let g:vwm#layouts =[s:def_layt]
    call s:init()
  endif

  if !exists('g:vwm#force_vert_first')
    let g:vwm#force_vert_first = 0
  endif
  if !exists('g:vwm#safe_mode')
    let g:vwm#safe_mode = 0
  endif
  let g:vwm#active = 1
endfun

call s:init()

command! VwmReinit call s:init()
command! -nargs=+ VwmOpen call vwm#open(<f-args>)
command! -nargs=+ VwmClose call vwm#close(<f-args>)
command! -nargs=+ VwmToggle call vwm#toggle(<f-args>)
command! -nargs=0 VwmList call vwm#list_active()
command! -nargs=0 VwmRefresh call vwm#repop_active(v:null)
command! -nargs=0 VwmClsoeAll call vwm#close_all()
