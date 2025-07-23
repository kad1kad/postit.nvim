### File Navigation### Multiple Notes# postit.nvim

A simple, minimal Neovim post-it plugin for non-sophisticated note takers.

## Features

- 🗒️ Single persistent post-it note
- 💾 Auto-saves notes (stored in `~/.local/share/nvim/postit/`)
- 📅 Automatic timestamps in DD/MM/YY HH:MM format
- 🖼️ Floating window interface
- 📏 Toggle between normal and fullscreen modes
- 🧹 Easy note clearing
- 🔗 File navigation - 'Enter' on file paths to open them

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

**Option 2: With configuration**

```lua
use {
  "kad1kad/postit.nvim",
  config = function()
    require("postit").setup({
      width = 80,
      height = 25,
      border = "double"
    })
  end
}
```

### Using vim-plug or other managers

Add the plugin and it will work automatically:

```vim
Plug 'kad1kad/postit.nvim'
```

Or configure via global variable:

```lua
vim.g.postit_config = {
  width = 80,
  height = 25,
  border = "double"
}
```

## Usage

### Default Keymaps

- `<leader>nt` - Toggle post-it note
- `<leader>nf` - Toggle fullscreen mode (when in post-it)
- `<leader>nd` - Clear note content (also resets timestamp)
- `gf` - Navigate to file under cursor (when in post-it)
- `<Enter>` - Navigate to file under cursor (when in post-it)
- `<Esc>` or `q` - Close post-it (when in post-it)

### File Navigation

Perfect for linking to files in your project:

- Type any file path in your note:
  - `./src/main.js`
  - `/absolute/path/to/file.txt`
  - `relative/path/config.json`
  - `README.md`
- Place cursor on the line with the file path
- Press `gf` or `<Enter>` to open the file
- The post-it will close and the file will open in the current buffer

## Configuration

You can customize the plugin by passing options to the setup function:

```lua
require("postit").setup({
  width = 80,        -- Window width (default: 60)
  height = 25,       -- Window height (default: 20)
  border = "single", -- Border style: "single", "double", "rounded", "solid", "shadow"
})
```

## File Storage

Notes are automatically stored in:

```
~/.local/share/nvim/postit/note.txt
```

## Tips

- Notes auto-save as you type, so you never lose your work
- Use fullscreen mode (`<leader>nf`) for longer notes
- Clear notes with (`<leader>nd`) to start fresh with a new timestamp
- Your note gets an automatic header with creation date/time
- Use file paths in your notes for quick navigation - supports relative and absolute paths

## Requirements

- Neovim 0.7+

## License

MIT
