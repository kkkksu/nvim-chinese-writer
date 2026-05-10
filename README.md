# nvim-chinese-writer

A Neovim plugin for better Chinese writing experience in LazyVim.

## Features

- **Auto input method switching**: Automatically switch to English when leaving Insert mode, and restore Chinese when entering Insert mode (macOS only, requires [im-select](https://github.com/daipeihong/im-select))
- **Chinese punctuation mapping**: Map Chinese punctuation to English commands in Normal/Visual/Operator/Command modes
- **Pinyin jump** (WIP): Use `f`/`t`/`F`/`T` to jump to Chinese characters by pinyin first letter

## Requirements

- Neovim >= 0.8
- macOS (for input method switching)
- [im-select](https://github.com/daipeihong/im-select) installed at `~/.local/bin/im-select`

## Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim) (LazyVim)

```lua
-- ~/.config/nvim/lua/plugins/chinese-writer.lua
return {
  "kkkksu/nvim-chinese-writer",
  config = function()
    require("chinese-writer").setup()
  end,
}
```

### Custom configuration

```lua
require("chinese-writer").setup({
  im_switch = {
    enabled = true,
    im_select_path = vim.fn.expand("~/.local/bin/im-select"),
    default_im = "com.apple.keylayout.ABC",
  },
  punct_map = {
    enabled = true,
  },
  pinyin_jump = {
    enabled = false, -- work in progress
  },
})
```

## Input Method Switching

The plugin uses `im-select` to query and set the current input method:

- **InsertLeave** → Switch to English (`com.apple.keylayout.ABC`)
- **InsertEnter** → Restore previous Chinese input method
- **FocusGained** → Adjust based on current mode
- **FocusLost** → Restore previous input method

## Chinese Punctuation Mapping

The following mappings are set automatically:

| Chinese | English | Modes |
|:---|:---|:---|
| `，` | `,` | n, v, o, c |
| `。` | `.` | n, v, o, c |
| `；` | `;` | n, v, o, c |
| `：` | `:` | n, v, o, c |
| `？` | `?` | n, v, o, c |
| `！` | `!` | n, v, o, c |
| `（` `）` | `(` `)` | n, v, o, c |
| `【` `】` | `[` `]` | n, v, o, c |
| `《` `》` | `<` `>` | n, v, o, c |
| `"` `"` | `"` `"` | n, v, o, c |
| `'` `'` | `'` `'` | n, v, o, c |
| `、` | `\` | n, v, o, c |
| `·` | `` ` `` | n, v, o, c |
| `￥` | `$` | n, v, o, c |

## License

MIT
