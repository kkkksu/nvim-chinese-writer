local M = {}

M.config = {
  im_switch = {
    enabled = true,
    im_select_path = vim.fn.expand("~/.local/bin/im-select"),
    default_im = "com.apple.keylayout.ABC",
    chinese_im = "com.apple.inputmethod.SCIM.ITABC",
  },
  punct_map = {
    enabled = true,
  },
  pinyin_jump = {
    enabled = true,
  },
}

M.enabled = false

-- ============================
-- 输入法切换
-- ============================

local function switch_im(path, im_id)
  if not im_id or im_id == "" then
    return
  end
  vim.system({ path, im_id }):wait()
end

-- ============================
-- 中文标点映射
-- ============================

local default_punct_mappings = {
  nv = {
    { "，", "," },
    { "。", "." },
    { "；", ";" },
    { "：", ":" },
    { "？", "?" },
    { "！", "!" },
    { "“", '"' },
    { "”", '"' },
    { "‘", "'" },
    { "’", "'" },
    { "（", "(" },
    { "）", ")" },
    { "【", "[" },
    { "】", "]" },
    { "《", "<" },
    { "》", ">" },
    { "、", "\\" },
    { "·", "`" },
    { "￥", "$" },
  },
  cmd = {
    { "：", ":" },
    { "，", "," },
    { "。", "." },
    { "；", ";" },
    { "？", "?" },
    { "！", "!" },
    { "（", "(" },
    { "）", ")" },
    { "【", "[" },
    { "】", "]" },
    { "《", "<" },
    { "》", ">" },
    { "、", "\\" },
    { "“", '"' },
    { "”", '"' },
    { "‘", "'" },
    { "’", "'" },
    { "·", "`" },
    { "￥", "$" },
  },
}

local function setup_punct_map(cfg)
  local mappings = cfg.mappings or default_punct_mappings

  for _, m in ipairs(mappings.nv or default_punct_mappings.nv) do
    vim.cmd(string.format("nmap <silent> %s %s", m[1], m[2]))
    vim.cmd(string.format("vmap <silent> %s %s", m[1], m[2]))
    vim.cmd(string.format("omap <silent> %s %s", m[1], m[2]))
  end

  for _, m in ipairs(mappings.cmd or default_punct_mappings.cmd) do
    vim.cmd(string.format("cmap <silent> %s %s", m[1], m[2]))
  end
end

-- ============================
-- 拼音首字母跳转 (LUT 方案)
-- ============================

local function find_next_pinyin(chars, start_idx, target, backward)
  local ok, lut = pcall(require, "chinese-writer.pinyin-lut")
  if not ok then
    vim.notify("chinese-writer: pinyin-lut not found", vim.log.levels.WARN)
    return nil, nil
  end

  local step = backward and -1 or 1
  local s = backward and math.min(start_idx - 1, #chars) or math.min(start_idx + 1, #chars)
  local e = backward and 1 or #chars

  vim.notify(string.format("find_next_pinyin: target=%s, start=%d, end=%d, step=%d, chars_count=%d", target, s, e, step, #chars), vim.log.levels.INFO)

  for i = s, e, step do
    local c = chars[i]
    -- 英文字符直接匹配
    if c:lower() == target then
      vim.notify(string.format("find_next_pinyin: matched EN at %d, char='%s'", i, c), vim.log.levels.INFO)
      return i, c
    end
    -- 中文字符拼音首字母匹配
    local first = lut.get_first_letter(c)
    if first == target then
      vim.notify(string.format("find_next_pinyin: matched CN at %d, char='%s', pinyin=%s", i, c, first), vim.log.levels.INFO)
      return i, c
    end
  end

  vim.notify("find_next_pinyin: no match", vim.log.levels.INFO)
  return nil, nil
end

local function make_pinyin_jump(cmd, backward)
  return function()
    local char = vim.fn.getcharstr()
    if char == "" or char == "\x1b" then
      return
    end

    local target = char:lower()
    local line = vim.api.nvim_get_current_line()
    -- 按字符分割（正确处理 UTF-8 多字节字符）
    local chars = vim.fn.split(line, '\\zs')
    local row, col_byte = unpack(vim.api.nvim_win_get_cursor(0))
    -- 将字节位置转换为字符索引
    local col_char = vim.str_utfindex(line, col_byte)

    vim.notify(string.format("pinyin_jump: cmd=%s, target=%s, col_byte=%d, col_char=%d, line='%s'", cmd, target, col_byte, col_char, line), vim.log.levels.INFO)

    local idx, matched_char = find_next_pinyin(chars, col_char, target, backward)
    if idx and matched_char then
      -- 将字符索引转换回字节位置
      local byte_pos = vim.str_byteindex(line, idx)
      vim.notify(string.format("pinyin_jump: jumping to byte=%d, char='%s'", byte_pos, matched_char), vim.log.levels.INFO)
      vim.api.nvim_win_set_cursor(0, {row, byte_pos})
      -- 用 feedkeys 让 Neovim 记录搜索状态，支持 ; 和 ,
      vim.schedule(function()
        vim.api.nvim_feedkeys(cmd .. matched_char, "n", false)
      end)
    else
      vim.notify("pinyin_jump: fallback to default " .. cmd .. char, vim.log.levels.INFO)
      vim.api.nvim_feedkeys(cmd .. char, "n", false)
    end
  end
end

function M.enable_pinyin_jump()
  for _, mode in ipairs({ "n", "x", "o" }) do
    vim.keymap.set(mode, "f", make_pinyin_jump("f", false), { desc = "Pinyin jump forward" })
    vim.keymap.set(mode, "F", make_pinyin_jump("F", true), { desc = "Pinyin jump backward" })
    vim.keymap.set(mode, "t", make_pinyin_jump("t", false), { desc = "Pinyin till forward" })
    vim.keymap.set(mode, "T", make_pinyin_jump("T", true), { desc = "Pinyin till backward" })
  end
  M.enabled = true
  vim.notify("Chinese Writer Mode: ON (pinyin jump)", vim.log.levels.INFO)
end

function M.disable_pinyin_jump()
  for _, mode in ipairs({ "n", "x", "o" }) do
    for _, key in ipairs({ "f", "F", "t", "T" }) do
      pcall(vim.keymap.del, mode, key)
    end
  end
  M.enabled = false
  vim.notify("Chinese Writer Mode: OFF", vim.log.levels.INFO)
end

function M.toggle()
  if M.enabled then
    M.disable_pinyin_jump()
  else
    M.enable_pinyin_jump()
  end
end

-- ============================
-- 输入法自动切换
-- ============================

local function setup_im_switch(cfg)
  if vim.fn.executable(cfg.im_select_path) == 0 then
    vim.notify("chinese-writer: im-select not found at " .. cfg.im_select_path, vim.log.levels.WARN)
    return
  end

  local group = vim.api.nvim_create_augroup("ChineseWriterIM", { clear = true })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      switch_im(cfg.im_select_path, cfg.default_im)
    end,
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      switch_im(cfg.im_select_path, cfg.chinese_im)
    end,
  })

  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      local mode = vim.api.nvim_get_mode().mode
      if mode:sub(1, 1) == "i" or mode:sub(1, 1) == "I" then
        switch_im(cfg.im_select_path, cfg.chinese_im)
      else
        switch_im(cfg.im_select_path, cfg.default_im)
      end
    end,
  })
end

-- ============================
-- 主入口
-- ============================

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  if M.config.im_switch.enabled then
    setup_im_switch(M.config.im_switch)
  end

  if M.config.punct_map.enabled then
    setup_punct_map(M.config.punct_map)
  end

  if M.config.pinyin_jump.enabled then
    M.enable_pinyin_jump()
  end

  -- 注册命令
  vim.api.nvim_create_user_command("ChineseWriterToggle", function()
    M.toggle()
  end, { desc = "Toggle Chinese Writer Mode" })

  vim.api.nvim_create_user_command("CW", function()
    M.toggle()
  end, { desc = "Toggle Chinese Writer Mode" })
end

return M
