" Example layouts
"
let s:vimdiff = {
      \  'name': 'vimdiff',
      \  'top':
      \  {
      \    'init': ['wincmd o', 'normal ibase'],
      \    'left':
      \    {
      \      'init': ['normal ilocal']
      \    },
      \    'right':
      \    {
      \      'init': ['normal iremote']
      \    }
      \  },
      \  'bot':
      \  {
      \    'init': ['normal imerge'],
      \    'sz': 20
      \  }
      \}

let s:frame = {
      \  'name': 'frame',
      \  'top': {
      \    'left': {
      \      'init': []
      \    },
      \    'right': {
      \      'init': []
      \    }
      \  },
      \  'bot': {
      \    'left': {
      \      'init': []
      \    },
      \    'right': {
      \      'init': []
      \    }
      \  },
      \  'left': {
      \    'init' :[]
      \  },
      \  'right': {
      \    'init' :[]
      \  }
      \}

let s:bot_panel = {
      \    'name': 'bot_panel',
      \    'bot':
      \    {
      \      'sz': 12,
      \      'left':
      \      {
      \        'init': []
      \      }
      \    }
      \  }

let g:vwm#layouts = [ s:vimdiff, s:frame, s:bot_panel ]
