" Utility functions

fun! util#buf_active(bid)
  return bufwinnr(a:bid) == -1 ? 0 : 1
endfun

fun! util#buf_exists(bid)
  return bufname(a:bid) =~ '^$' ? 0 : 1
endfun

fun! util#node_has_child(node, pos)
  if eval("exists('a:node." . a:pos . "')")
    return eval('len(a:node.' . a:pos . ')') ? 1 : 0
  endif
  return 0
endfun

fun! util#lookup_node(name)
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
fun! util#format_winnode(node, unlisted, isVert)
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

fun! util#resz_winnode(node, ori)
  if a:node.sz
    if a:ori <=2
      execute('vert resize ' . a:node.sz)
    else
      execute('resize ' . a:node.sz)
    endif
  endif
endfun

fun! util#active_nodes()
  let l:active = []
  for node in g:vwm#layouts

    if node.active
      let l:active += [node]
    endif

  endfor
  return l:active
endfun

fun! util#tmp_setlocal()
  setlocal bt=nofile bh=wipe noswapfile
endfun

fun! util#node_has_vert(node)
  return util#node_has_child(a:node, 'left') || util#node_has_child(a:node, 'right')
endfun

" Right recursive traverse and do
" orientation is optional 1:left, 2:right, 3:top, 4:bot
fun! util#traverse(node, fRprime, fRAftr, fBfr, fAftr, h, v)

  let l:v = {}
  let l:bid = bufnr('%')

  if a:h

    if util#node_has_child(a:node, 'left')
      if !(a:fRprime is v:null)
        call a:fRprime(a:node, 1)
      endif
      let l:v[1] = s:traverse_main(a:node.left, a:fBfr, a:fAftr, 1, 1)
      execute(bufwinnr(l:bid) . 'wincmd w')
    endif
    if util#node_has_child(a:node, 'right')
      if !(a:fRprime is v:null)
        call a:fRprime(a:node, 2)
      endif
      let l:v[2] = s:traverse_main(a:node.right, a:fBfr, a:fAftr, 2, 1)
      execute(bufwinnr(l:bid) . 'wincmd w')
    endif

  endif

  if a:v

    if util#node_has_child(a:node, 'top')
      if !(a:fRprime is v:null)
        call a:fRprime(a:node, 3)
      endif
      let l:v[3] = s:traverse_main(a:node.top, a:fBfr, a:fAftr, 3, 1)
      execute(bufwinnr(l:bid) . 'wincmd w')
    endif
    if util#node_has_child(a:node, 'bot')
      if !(a:fRprime is v:null)
        call a:fRprime(a:node, 4)
      endif
      let l:v[4] = s:traverse_main(a:node.bot, a:fBfr, a:fAftr, 4, 1)
      execute(bufwinnr(l:bid) . 'wincmd w')
    endif

  endif

  if !(a:fRAftr is v:null)
    call a:fRAftr(a:node, l:v)
  endif

  return a:node
endfun

fun! s:traverse_main(node, fBfr, fAftr, ori, fromRoot)
  if !a:fromRoot
    if !(a:fBfr is v:null)
      call a:fBfr(a:node, a:ori)
    endif
  endif

 let l:bid = bufnr('%')

  let l:v = {}

  if util#node_has_child(a:node, 'left')
    let l:v[1] = s:traverse_main(a:node.left, a:fBfr, a:fAftr, 1, 0)
    execute(bufwinnr(l:bid) . 'wincmd w')
  endif
  if util#node_has_child(a:node, 'right')
    let l:v[2] = s:traverse_main(a:node.right, a:fBfr, a:fAftr, 2, 0)
    execute(bufwinnr(l:bid) . 'wincmd w')
  endif
  if util#node_has_child(a:node, 'top')
    let l:v[3] = s:traverse_main(a:node.top, a:fBfr, a:fAftr, 3, 0)
    execute(bufwinnr(l:bid) . 'wincmd w')
  endif
  if util#node_has_child(a:node, 'bot')
    let l:v[4] = s:traverse_main(a:node.bot, a:fBfr, a:fAftr, 4, 0)
    execute(bufwinnr(l:bid) . 'wincmd w')
  endif

  if !(a:fAftr is v:null)
    call a:fAftr(a:node, l:v, a:ori)
  endif

  return a:node
endfun

" Execute layout defined commands. Accept funcrefs and Strings
fun! util#execute_cmds(cmds)
  for Cmd in a:cmds
    if type(Cmd) == 2
      call Cmd()
    else
      execute(Cmd)
    endif
  endfor
endfun
