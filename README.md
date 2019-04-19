# *V*im *W*indow *M*anager

A layout manager for vim and nvim.
![](https://gist.githubusercontent.com/paroxayte/003aa6e0925ae601e4febb607710a3c5/raw/4abe97a75ab5a19b114d011226344b4a40fce716/default.gif)

## Features

* Save and manage vim windows via layouts
* Automatically cache and unlist buffers
* Automatically reuse buffers
* Regroup command buffers
* Highly configurable

## Installation

* **vimplug:** `Plug 'paroxayte/vwm.vim'`
* **dein:** `call dein#add('paroxayte/vwm.vim')`
* **manual:** source the this repo to your vim runtime

## Usage

* **Layout on:**      `:VwmOpen *layout_name*`
* **Layout off:**     `:VwmClose *layout_name*`
* **Layout toggle:**  `:VwmToggle *layout_name*`

*note:* `default` *is the only default layout. Test it out!*

## Examples

**_note:_** For detailed configuration see `help: vwm.vim`.
### layouts
**[definitions](https://gist.githubusercontent.com/paroxayte/003aa6e0925ae601e4febb607710a3c5/raw/4abe97a75ab5a19b114d011226344b4a40fce716/layouts.vim)**
![](https://gist.githubusercontent.com/paroxayte/003aa6e0925ae601e4febb607710a3c5/raw/4abe97a75ab5a19b114d011226344b4a40fce716/layouts.gif)

### command buffer regrouping
*vwm can take commands that open a new window, and incorporate that window in to a defined layout*

The following example will make use of the wonderful [NERDTree plugin](https://github.com/scrooloose/nerdtree) and the equally wonderful [Tagbar plugin](https://github.com/majutsushi/tagbar).

**[definitions](https://gist.githubusercontent.com/paroxayte/003aa6e0925ae601e4febb607710a3c5/raw/4abe97a75ab5a19b114d011226344b4a40fce716/dev_panel.vim)**
![](https://gist.githubusercontent.com/paroxayte/003aa6e0925ae601e4febb607710a3c5/raw/4abe97a75ab5a19b114d011226344b4a40fce716/bufsteal.gif)
