local M = {}

-- ============================================================================
-- Tab-completion state (shared across popups)
-- ============================================================================
local tab_state = {
  base = "",
  completions = {},
  idx = 0,
}

local function reset_tab_state()
  tab_state = { base = "", completions = {}, idx = 0 }
end

local function get_line_text(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
  return lines[1] or ""
end

local function set_line_text(bufnr, text)
  vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { text })
  local winid = vim.fn.bufwinid(bufnr)
  if winid ~= -1 then
    vim.api.nvim_win_set_cursor(winid, { 1, #text })
  end
end

local function do_tab_completion(bufnr, completion_type, forward)
  forward = forward ~= false
  local text = get_line_text(bufnr)

  if tab_state.base ~= text then
    tab_state.base = text
    tab_state.completions = vim.fn.getcompletion(text, completion_type)
    tab_state.idx = 0
  end

  if #tab_state.completions == 0 then return end

  if forward then
    tab_state.idx = (tab_state.idx % #tab_state.completions) + 1
  else
    tab_state.idx = ((tab_state.idx - 2 + #tab_state.completions) % #tab_state.completions) + 1
  end

  set_line_text(bufnr, tab_state.completions[tab_state.idx])
end

local function attach_reset_autocmd(bufnr)
  vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = bufnr,
    callback = function()
      local text = get_line_text(bufnr)
      if text == tab_state.base then return end
      if #tab_state.completions == 0 then return end
      for _, c in ipairs(tab_state.completions) do
        if vim.startswith(c, text) then return end
      end
      reset_tab_state()
    end,
  })
end

-- ============================================================================
-- Generic popup builder
-- ============================================================================
local function open_input_popup(title, completion_type, on_confirm)
  local ok, Popup = pcall(require, "nui.popup")
  if not ok then
    vim.notify("nui.nvim no disponible", vim.log.levels.ERROR)
    return
  end

  reset_tab_state()

  local popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = { top = " " .. title .. " ", top_align = "center" },
    },
    position = "50%",
    size = { width = 70, height = 3 },
  })

  popup:mount()

  local cwd = vim.fn.getcwd() .. "/"
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, { cwd })
  vim.api.nvim_set_option_value("modifiable", true, { buf = popup.bufnr })
  vim.api.nvim_set_option_value("buftype", "", { buf = popup.bufnr })

  -- TAB forward
  popup:map("i", "<Tab>", function()
    do_tab_completion(popup.bufnr, completion_type, true)
  end, { noremap = true })

  -- S-TAB backward
  popup:map("i", "<S-Tab>", function()
    do_tab_completion(popup.bufnr, completion_type, false)
  end, { noremap = true })

  -- Enter: confirm
  popup:map("i", "<CR>", function()
    local path = get_line_text(popup.bufnr)
    popup:unmount()
    reset_tab_state()
    if path and #path > 0 then
      on_confirm(path)
    end
  end, { noremap = true })

  -- Close
  popup:map("n", "<Esc>", function()
    popup:unmount()
    reset_tab_state()
  end, { noremap = true })
  popup:map("i", "<C-c>", function()
    popup:unmount()
    reset_tab_state()
  end, { noremap = true })
  popup:map("n", "q", function()
    popup:unmount()
    reset_tab_state()
  end, { noremap = true })

  attach_reset_autocmd(popup.bufnr)

  vim.api.nvim_win_set_cursor(popup.winid, { 1, #cwd })
  vim.cmd("startinsert!")
end

-- ============================================================================
-- Create file popup
-- ============================================================================
function M.create_file()
  open_input_popup("Crear archivo", "file", function(path)
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    vim.cmd("edit " .. vim.fn.fnameescape(path))
    vim.notify("Archivo creado: " .. path, vim.log.levels.INFO)
  end)
end

-- ============================================================================
-- Create directory popup
-- ============================================================================
function M.create_dir()
  open_input_popup("Crear directorio", "dir", function(path)
    vim.fn.mkdir(path, "p")
    vim.notify("Directorio creado: " .. path, vim.log.levels.INFO)
  end)
end

return M
