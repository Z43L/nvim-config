local M = {}

-- ============================================================================
-- Paths
-- ============================================================================
local JSON_PATH = vim.fn.stdpath("data") .. "/ollama_config.json"
local ENV_PATH  = vim.fn.stdpath("config") .. "/.env"

-- ============================================================================
-- State
-- ============================================================================
M._state = {
  mode      = "local",
  local_url = "http://127.0.0.1:11434",
  cloud_url = "https://ollama.com",
  api_key   = nil,
  model     = nil,
}

-- ============================================================================
-- Helpers: JSON
-- ============================================================================
local function read_json(path)
  if vim.fn.filereadable(path) == 0 then return nil end
  local lines = vim.fn.readfile(path)
  if #lines == 0 then return nil end
  local ok, data = pcall(vim.json.decode, table.concat(lines, "\n"))
  if ok then return data end
  return nil
end

local function write_json(path, data)
  local ok, encoded = pcall(vim.json.encode, data)
  if ok then
    vim.fn.writefile(vim.split(encoded, "\n", { plain = true }), path)
  end
end

-- ============================================================================
-- Helpers: .env
-- ============================================================================
local function read_env()
  if vim.fn.filereadable(ENV_PATH) == 0 then return {} end
  local env = {}
  for _, line in ipairs(vim.fn.readfile(ENV_PATH)) do
    local k, v = line:match("^([A-Za-z_][A-Za-z0-9_]*)%s*=%s*(.*)$")
    if k and v then
      v = v:gsub("^['\"]", ""):gsub("['\"]$", "")
      env[k] = v
    end
  end
  return env
end

local function write_env(key, value)
  local lines = {}
  local found = false
  if vim.fn.filereadable(ENV_PATH) == 1 then
    for _, line in ipairs(vim.fn.readfile(ENV_PATH)) do
      local k = line:match("^([A-Za-z_][A-Za-z0-9_]*)%s*=")
      if k == key then
        table.insert(lines, key .. "=" .. value)
        found = true
      else
        table.insert(lines, line)
      end
    end
  end
  if not found then
    table.insert(lines, key .. "=" .. value)
  end
  vim.fn.writefile(lines, ENV_PATH)
end

-- ============================================================================
-- Load / Save config
-- ============================================================================
function M.load_config()
  -- JSON state
  local json = read_json(JSON_PATH)
  if json then
    if json.mode      ~= nil then M._state.mode      = json.mode end
    if json.local_url ~= nil then M._state.local_url = json.local_url end
    if json.model     ~= nil then M._state.model     = json.model end
    -- cloud_url: ignorar vacías o la antigua URL incorrecta
    if json.cloud_url and #json.cloud_url > 0
       and not json.cloud_url:match("api%.ollama%.ai")
       and not json.cloud_url:match("^%s*$") then
      M._state.cloud_url = json.cloud_url
    end
  end

  -- .env secrets (tienen prioridad sobre JSON)
  local env = read_env()
  if env.OLLAMA_API_KEY   then M._state.api_key   = env.OLLAMA_API_KEY end
  if env.OLLAMA_CLOUD_URL and #env.OLLAMA_CLOUD_URL > 0 then
    M._state.cloud_url = env.OLLAMA_CLOUD_URL
  end
end

function M.save_config()
  write_json(JSON_PATH, {
    mode      = M._state.mode,
    local_url = M._state.local_url,
    cloud_url = M._state.cloud_url,
    model     = M._state.model,
  })
end

-- ============================================================================
-- URL / Headers helpers
-- ============================================================================
function M.get_url()
  return (M._state.mode == "cloud" and M._state.cloud_url or M._state.local_url)
end

function M.get_headers()
  if M._state.api_key and #M._state.api_key > 0 then
    return { Authorization = "Bearer " .. M._state.api_key }
  end
  return nil
end

-- ============================================================================
-- Apply settings to ollama.nvim plugin
-- ============================================================================
function M.apply_to_ollama()
  local ok, ollama = pcall(require, "ollama")
  if not ok then return end
  ollama.config.url = M.get_url()
  if M._state.model then
    ollama.config.model = M._state.model
  end
  if M._state.api_key then
    ollama.config.api_key = M._state.api_key
  end
end

-- ============================================================================
-- Fetch available models from active endpoint
-- ============================================================================
function M.fetch_models()
  local active_url = M.get_url()
  if not active_url or #active_url == 0 then
    vim.notify("URL no configurada. Usa <leader>oc para configurar el endpoint.", vim.log.levels.ERROR)
    return {}
  end

  local url = active_url .. "/api/tags"
  local h = M.get_headers()
  local opts = { timeout = 15000 }
  if h then opts.headers = h end

  local ok, res = pcall(function()
    return require("plenary.curl").get(url, opts)
  end)

  if not ok then
    local err = tostring(res)
    local clean = err:match("stderr=%{(.-)%}") or err:match("curl error exit_code=(%d+)") or err:sub(1, 120)
    vim.notify("Conexión fallida: " .. clean, vim.log.levels.ERROR)
    return {}
  end

  if type(res) ~= "table" then
    vim.notify("Respuesta inesperada del servidor", vim.log.levels.ERROR)
    return {}
  end

  if res.status ~= 200 then
    local msg = (res.body and #res.body > 0) and ("HTTP " .. res.status .. ": " .. res.body:sub(1, 200)) or ("HTTP " .. tostring(res.status))
    vim.notify(msg, vim.log.levels.ERROR)
    return {}
  end

  local decode_ok, body = pcall(vim.json.decode, res.body)
  if not decode_ok or not body or not body.models then
    vim.notify("Respuesta inválida del endpoint (esperaba JSON con 'models')", vim.log.levels.ERROR)
    return {}
  end

  local names = {}
  for _, m in ipairs(body.models) do
    if m.name then table.insert(names, m.name) end
  end
  return names
end

-- ============================================================================
-- Select model (vim.ui.select)
-- ============================================================================
function M.select_model()
  local models = M.fetch_models()
  if #models == 0 then
    vim.ui.select({ "Sí", "No" }, {
      prompt = "No hay modelos. ¿Abrir configuración?",
    }, function(choice)
      if choice == "Sí" then M.configure() end
    end)
    return
  end

  vim.ui.select(models, {
    prompt = "Modelo Ollama (" .. M._state.mode .. "):",
    format_item = function(item)
      return (item == M._state.model) and ("● " .. item) or ("  " .. item)
    end,
  }, function(choice)
    if not choice then return end
    M._state.model = choice
    M.apply_to_ollama()
    M.save_config()
    vim.notify("Modelo activo: " .. choice, vim.log.levels.INFO)
  end)
end

-- ============================================================================
-- Toggle local / cloud
-- ============================================================================
function M.toggle_mode()
  M._state.mode = (M._state.mode == "local") and "cloud" or "local"
  M.apply_to_ollama()
  M.save_config()
  local msg = "Ollama modo: " .. M._state.mode .. " (" .. M.get_url() .. ")"
  if M._state.mode == "cloud" and (not M._state.api_key or #M._state.api_key == 0) then
    msg = msg .. " — API key no configurada. Usa <leader>oc"
  end
  vim.notify(msg, vim.log.levels.INFO)
end

-- ============================================================================
-- Configuration menu
-- ============================================================================
function M.configure()
  vim.ui.select({
    "Toggle modo (actual: " .. M._state.mode .. ")",
    "Cambiar API key",
    "Cambiar URL cloud",
    "Cambiar URL local",
    "Seleccionar modelo",
  }, {
    prompt = "Configuración Ollama:",
  }, function(choice, idx)
    if not idx then return end

    if idx == 1 then
      M.toggle_mode()

    elseif idx == 2 then
      local key = vim.fn.inputsecret("API key (cloud): ")
      if key and #key > 0 then
        M._state.api_key = key
        write_env("OLLAMA_API_KEY", key)
        M.apply_to_ollama()
        vim.notify("API key guardada en .env", vim.log.levels.INFO)
      end

    elseif idx == 3 then
      vim.ui.input({ prompt = "URL cloud: ", default = M._state.cloud_url or "" }, function(url)
        if url and #url > 0 then
          M._state.cloud_url = url
          write_env("OLLAMA_CLOUD_URL", url)
          M.save_config()
          M.apply_to_ollama()
          vim.notify("URL cloud: " .. url, vim.log.levels.INFO)
        end
      end)

    elseif idx == 4 then
      vim.ui.input({ prompt = "URL local: ", default = M._state.local_url or "" }, function(url)
        if url and #url > 0 then
          M._state.local_url = url
          M.save_config()
          M.apply_to_ollama()
          vim.notify("URL local: " .. url, vim.log.levels.INFO)
        end
      end)

    elseif idx == 5 then
      M.select_model()
    end
  end)
end

-- ============================================================================
-- Init: load + apply
-- ============================================================================
function M.init()
  M.load_config()
  M.apply_to_ollama()
end

return M
