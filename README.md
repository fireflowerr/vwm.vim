# *V*im *W*indow *M*anager 

A layout manager for vim and nvim.
![](expose.gif)

## Features

* Save and manage vim windows via layouts
* Automatically cache and unlist buffers
* Automatically reuse buffers
* Highly configurable

## Installation

* **vimplug:** `Plug 'paroxayte/vwm.vim'`
* **dein:** `call dein#add('paroxayte/vwm.vim')`
* **manual:** source the this repo to your vim runtime

## Usage

* **Layout on:**  `:VwmOpen *layout_name*`
* **Layout off:** `:VwmClose *layout_name*`

## Example
  
**_note:_** For detailed configuration see `help: vwm.vim`, for more examples see `:help
vwm.vim-examples`

The following example will create 3 equally sized terminals of height 12 at the bottom of the vim
  screen on **neovim**.

```vim
let g:vwm#layouts = [
      \  {
      \    'name': 'test',
      \    'bot':
      \    {
      \      'init': ['call termopen("zsh", {"detach": 0})'],
      \      'sz': 12,
      \      'left': 
      \      {
      \        'init': ['call termopen("zsh", {"detach": 0})'],
      \      },
      \      'right':
      \      {
      \        'init': ['call termopen("zsh", {"detach": 0})'],
      \      }
      \    }
      \  }
      \]
```
