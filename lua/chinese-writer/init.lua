local M = {}

M.config = {
  im_switch = {
    enabled = true,
    im_select_path = vim.fn.expand("~/.local/bin/im-select"),
    default_im = "com.apple.keylayout.ABC",
    -- 你常用的中文输入法 ID，默认 macOS 拼音
    chinese_im = "com.apple.inputmethod.SCIM.ITABC",
  },
  punct_map = {
    enabled = true,
  },
  pinyin_jump = {
    enabled = false,
  },
}

-- ============================
-- 输入法自动切换
-- ============================

local function switch_im(path, im_id)
  if not im_id or im_id == "" then
    return
  end
  vim.system({ path, im_id }):wait()
end

local function setup_im_switch(cfg)
  if vim.fn.executable(cfg.im_select_path) == 0 then
    vim.notify("chinese-writer: im-select not found at " .. cfg.im_select_path, vim.log.levels.WARN)
    return
  end

  local group = vim.api.nvim_create_augroup("ChineseWriterIM", { clear = true })

  -- 离开 Insert 模式：切回英文
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      switch_im(cfg.im_select_path, cfg.default_im)
    end,
  })

  -- 进入 Insert 模式：切到中文
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      switch_im(cfg.im_select_path, cfg.chinese_im)
    end,
  })

  -- 获得焦点时根据当前模式调整
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
-- 拼音跳转（预留接口）
-- ============================

local function setup_pinyin_jump(cfg)
  if not cfg.enabled then
    return
  end
  vim.notify("chinese-writer: pinyin_jump is not yet implemented", vim.log.levels.INFO)
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
    setup_pinyin_jump(M.config.pinyin_jump)
  end
end

return M
