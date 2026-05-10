# nvim-chinese-writer

A Neovim plugin for better Chinese writing experience in LazyVim.

## Features

All features are **disabled by default**. Use `:CW` or `:ChineseWriterToggle` to enable/disable everything at once.

- **Auto input method switching**: Automatically switch to English when leaving Insert mode, and restore Chinese when entering Insert mode (macOS only, requires [im-select](https://github.com/daipeihong/im-select))
- **Chinese punctuation mapping**: Map Chinese punctuation to English commands in Normal/Visual/Operator/Command modes
- **Pinyin jump**: Use `f`/`F`/`t`/`T` to jump to Chinese characters by pinyin first letter. `;` and `,` work as expected for repeating the jump.

## Requirements

- Neovim >= 0.8
- macOS (for input method switching)
- [im-select](https://github.com/daipeihong/im-select) installed at `~/.local/bin/im-select`

## Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim) (LazyVim)

```lua
-- ~/.config/nvim/lua/plugins/chinese-writer.lua
return {
  {
    "kkkksu/nvim-chinese-writer",
    dependencies = { "folke/flash.nvim" },
    event = "VeryLazy",
    config = function()
      require("chinese-writer").setup()
    end,
  },
}
```

## Usage

```vim
:CW                " Toggle Chinese Writer Mode ON/OFF
:ChineseWriterToggle
```

### When enabled

| Mode | Action | Result |
|:---|:---|:---|
| Insert | Enter Insert mode | Switch to Chinese Pinyin input method |
| Normal | Press `Esc` | Switch to English input method |
| Normal | `fa` | Jump to next char with pinyin first letter `a` (e.g. 爱, 啊, 安) |
| Normal | `;` | Repeat last `f`/`F`/`t`/`T` jump forward |
| Normal | `,` | Repeat last `f`/`F`/`t`/`T` jump backward |
| Normal | `，` | Works as `,` (reverse find character) |
| Command | `：` | Works as `:` (enter command line) |

### Pinyin jump examples

```
我爱北京天安门也看也吃也喝
```

- Cursor on 我, press `fa` → jump to **爱** (ai)
- Cursor on 我, press `fy` → jump to **也** (ye)
- Press `;` → jump to next **也**
- Press `,` → jump back to previous **也**

## Custom configuration

```lua
require("chinese-writer").setup({
  im_switch = {
    enabled = false,                              -- default
    im_select_path = vim.fn.expand("~/.local/bin/im-select"),
    default_im = "com.apple.keylayout.ABC",       -- English
    chinese_im = "com.apple.inputmethod.SCIM.ITABC", -- macOS Pinyin
  },
  punct_map = {
    enabled = false,                              -- default
  },
  pinyin_jump = {
    enabled = false,                              -- default
  },
})
```

If you want a feature enabled by default on startup, set its `enabled = true`.

## License

MIT
