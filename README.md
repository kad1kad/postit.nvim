# postit.nvim

A simple, minimal Neovim post-it plugin for non-sophisticated note takers.

## Features

- 🙅‍♂️ No checkboxes, no markdown, nothing but a post-it
- 📅 Automatic timestamps in DD/MM/YY HH:MM format (Look at you fancy post-it!)
- 🔗 File navigation - 'Enter' on file paths to open them (Whaaat?)
- 💾 Auto-saves notes (stored in `~/.local/share/nvim/postit/`)
- 🖼️ Floating window interface
- 📏 Toggle between normal and fullscreen modes
- 🧹 Easy note clearing

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

**Option 1: Zero configuration (should work out of the box)**

```lua
{
  "kad1kad/postit.nvim"
}
```

**Option 2: With custom settings**

```lua
{
  "kad1kad/postit.nvim",
  opts = {
    width = 80,
    height = 25,
    border = "double"
  }
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

**Option 1: Auto-setup**

```lua
use "kad1kad/postit.nvim"
```

### Using vim-plug or other managers

Add the plugin and it will work automatically:

```vim
Plug 'kad1kad/postit.nvim'
```

## Usage

### Default Keymaps

- `<leader>nt` - Toggle post-it note
- `<leader>nf` - Toggle fullscreen mode
- `<leader>nd` - Clear note content (also resets timestamp)
- `<Enter>` or `gf` - Navigate to file under cursor
- `<Esc>` or `q` - Close post-it (when in post-it)

## Configuration

You can customize the plugin by passing options to the setup function:

```lua
require("postit").setup({
  width = 80,        -- Window width (default: 60)
  height = 25,       -- Window height (default: 20)
  border = "single", -- Border style: "single", "double", "rounded", "solid", "shadow"
})
```

## Requirements

- Neovim 0.7+

## License

MIT
