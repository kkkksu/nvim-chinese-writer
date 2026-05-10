local M = {}

M.config = {
  -- 输入法自动切换配置
  im_switch = {
    enabled = true,
    im_select_path = vim.fn.expand("~/.local/bin/im-select"),
    default_im = "com.apple.keylayout.ABC",
  },
  -- 中文标点映射配置
  punct_map = {
    enabled = true,
    -- 可在这里自定义映射，例如: mappings = { { "，", "," } }
  },
  -- 拼音跳转配置（预留，后续实现）
  pinyin_jump = {
    enabled = false,
  },
}

M.last_im = nil

-- ============================
-- 输入法自动切换
-- ============================

local function switch_im(path, im_id)
  if not im_id or im_id == "" then
    return
  end
  vim.system({ path, im_id })
end

local function get_current_im(path)
  local ok, result = pcall(function()
    return vim.fn.system(path):gsub("%s+", "")
  end)
  if ok then
    return result
  end
  return nil
end

local function setup_im_switch(cfg)
  if vim.fn.executable(cfg.im_select_path) == 0 then
    vim.notify("chinese-writer: im-select not found at " .. cfg.im_select_path, vim.log.levels.WARN)
    return
  end

  local group = vim.api.nvim_create_augroup("ChineseWriterIM", { clear = true })

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      local current = get_current_im(cfg.im_select_path)
      if current and current ~= cfg.default_im then
        M.last_im = current
      end
      switch_im(cfg.im_select_path, cfg.default_im)
    end,
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      if M.last_im and M.last_im ~= cfg.default_im then
        switch_im(cfg.im_select_path, M.last_im)
      end
    end,
  })

  vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
      local mode = vim.api.nvim_get_mode().mode
      if mode:sub(1, 1) == "i" or mode:sub(1, 1) == "I" then
        if M.last_im and M.last_im ~= cfg.default_im then
          switch_im(cfg.im_select_path, M.last_im)
        end
      else
        switch_im(cfg.im_select_path, cfg.default_im)
      end
    end,
  })

  vim.api.nvim_create_autocmd("FocusLost", {
    group = group,
    callback = function()
      if M.last_im and M.last_im ~= cfg.default_im then
        switch_im(cfg.im_select_path, M.last_im)
      end
    end,
  })
end

-- ============================
-- 中文标点映射
-- ============================

local default_punct_mappings = {
  -- Normal / Visual / Operator 模式
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
  -- Command 模式
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
  -- TODO: implement f/t/F/T for chinese characters via pinyin first letter
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
