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
    enabled = false,
  },
}

M.enabled = false
M.original_maps = {}

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
-- 中文写作模式 (f/t/F/T 增强)
-- ============================

local function make_pinyin_jump(cmd, path, chinese_im, default_im)
  return function()
    -- 切换到中文输入法，让用户输入目标字符
    switch_im(path, chinese_im)
    -- 获取用户输入的字符（可以是中文字符）
    local char = vim.fn.getcharstr()
    -- 立即切回英文
    switch_im(path, default_im)
    -- 执行原始的 f/t/F/T 命令
    if char and char ~= "" then
      vim.api.nvim_feedkeys(cmd .. char, "n", false)
    end
  end
end

function M.enable_chinese_writer_mode()
  local cfg = M.config.im_switch
  local path, chinese, default = cfg.im_select_path, cfg.chinese_im, cfg.default_im

  -- 保存原始映射（如果有）
  for _, key in ipairs({ "f", "F", "t", "T" }) do
    local existing = vim.fn.maparg(key, "n", false, true)
    if existing and existing.lhs then
      M.original_maps[key] = existing
    end
  end

  -- 设置新映射
  for _, mode in ipairs({ "n", "x", "o" }) do
    vim.keymap.set(mode, "f", make_pinyin_jump("f", path, chinese, default), { desc = "Chinese writer f" })
    vim.keymap.set(mode, "F", make_pinyin_jump("F", path, chinese, default), { desc = "Chinese writer F" })
    vim.keymap.set(mode, "t", make_pinyin_jump("t", path, chinese, default), { desc = "Chinese writer t" })
    vim.keymap.set(mode, "T", make_pinyin_jump("T", path, chinese, default), { desc = "Chinese writer T" })
  end

  M.enabled = true
  vim.notify("Chinese Writer Mode: ON", vim.log.levels.INFO)
end

function M.disable_chinese_writer_mode()
  -- 删除映射
  for _, mode in ipairs({ "n", "x", "o" }) do
    for _, key in ipairs({ "f", "F", "t", "T" }) do
      pcall(vim.keymap.del, mode, key)
    end
  end

  -- 恢复原始映射（如果有）
  for key, map in pairs(M.original_maps) do
    if map then
      vim.fn.mapset(map)
    end
  end
  M.original_maps = {}

  M.enabled = false
  vim.notify("Chinese Writer Mode: OFF", vim.log.levels.INFO)
end

function M.toggle()
  if M.enabled then
    M.disable_chinese_writer_mode()
  else
    M.enable_chinese_writer_mode()
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

  -- 注册命令
  vim.api.nvim_create_user_command("ChineseWriterToggle", function()
    M.toggle()
  end, { desc = "Toggle Chinese Writer Mode" })

  vim.api.nvim_create_user_command("CW", function()
    M.toggle()
  end, { desc = "Toggle Chinese Writer Mode" })
end

return M
