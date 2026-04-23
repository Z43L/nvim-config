local M = {}
local snippets_dir = vim.fn.stdpath('config') .. '/snippets'

-- ============================================================================
-- Helpers
-- ============================================================================

---Get visual selection text (usa 'v' que es el mark en tiempo real del visual)
local function get_visual_selection()
    local sp = vim.fn.getpos('v')
    local ep = vim.fn.getpos('.')
    local s_row, s_col = sp[2], sp[3]
    local e_row, e_col = ep[2], ep[3]
    -- Normalizar (inicio siempre antes que fin)
    if s_row > e_row or (s_row == e_row and s_col > e_col) then
        s_row, e_row = e_row, s_row
        s_col, e_col = e_col, s_col
    end
    -- nvim_buf_get_text usa indices 0-based
    local lines = vim.api.nvim_buf_get_text(0, s_row - 1, s_col - 1, e_row - 1, e_col, {})
    if not lines or #lines == 0 then return nil end
    return table.concat(lines, '\n')
end

---Escape a string for Lua string literal
local function escape_lua_string(str)
    return str:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r')
end

---Format snippet body for LuaSnip native format
local function format_snippet_body(text)
    local lines = vim.split(text, '\n', { plain = true })
    local parts = {}
    for _, line in ipairs(lines) do
        table.insert(parts, string.format('    t("%s")', escape_lua_string(line)))
    end
    return table.concat(parts, ',\n')
end

---Get or create snippets file path
local function get_snippets_file(ft)
    ft = ft or 'all'
    local dir = snippets_dir .. '/' .. ft
    vim.fn.mkdir(dir, 'p')
    return dir .. '/custom.lua'
end

---Read existing snippets from a file
local function read_snippets_file(path)
    if vim.fn.filereadable(path) == 0 then return {} end
    local lines = vim.fn.readfile(path)
    if #lines == 0 then return {} end
    local snippets = {}
    local i = 1
    while i <= #lines do
        local trigger = lines[i]:match('^%s*s%("([^"]+)"')
        if trigger then
            local name = lines[i]:match('%-%-%s*name:%s*(.+)$') or trigger
            local start_line = i
            local depth = 1
            i = i + 1
            while i <= #lines and depth > 0 do
                for _ in lines[i]:gmatch('{') do depth = depth + 1 end
                for _ in lines[i]:gmatch('}') do depth = depth - 1 end
                i = i + 1
            end
            table.insert(snippets, {
                trigger = trigger,
                name = name,
                path = path,
                start_line = start_line,
                end_line = i - 1,
            })
        else
            i = i + 1
        end
    end
    return snippets
end

---Collect ALL snippets from all snippet files
local function collect_all_snippets()
    local all = {}
    local function scan_dir(dir)
        local handle = vim.loop.fs_scandir(dir)
        if not handle then return end
        while true do
            local name, typ = vim.loop.fs_scandir_next(handle)
            if not name then break end
            if typ == 'directory' then
                local custom_file = dir .. '/' .. name .. '/custom.lua'
                if vim.fn.filereadable(custom_file) == 1 then
                    local snippets = read_snippets_file(custom_file)
                    for _, s in ipairs(snippets) do
                        s.ft = name
                        table.insert(all, s)
                    end
                end
            end
        end
    end
    scan_dir(snippets_dir)
    local root_custom = snippets_dir .. '/all/custom.lua'
    if vim.fn.filereadable(root_custom) == 1 then
        local snippets = read_snippets_file(root_custom)
        for _, s in ipairs(snippets) do
            s.ft = 'all'
            table.insert(all, s)
        end
    end
    return all
end

-- ============================================================================
-- Save snippet from visual selection
-- ============================================================================

function M.save_visual()
    local text = get_visual_selection()
    if not text or text == '' then
        vim.notify('No hay texto seleccionado', vim.log.levels.WARN)
        return
    end

    vim.ui.input({ prompt = 'Trigger (abreviatura): ' }, function(trigger)
        if not trigger or trigger == '' then
            vim.notify('Cancelado: trigger vacio', vim.log.levels.WARN)
            return
        end

        vim.ui.input({ prompt = 'Nombre/descripcion: ', default = trigger }, function(name)
            if not name or name == '' then name = trigger end

            vim.ui.select({ 'Filetype actual (' .. vim.bo.filetype .. ')', 'Global (todos los archivos)' }, {
                prompt = 'Ambito del snippet:',
            }, function(_, idx)
                if not idx then return end

                local ft = idx == 1 and vim.bo.filetype or 'all'
                if ft == '' then ft = 'all' end

                local path = get_snippets_file(ft)
                local file_exists = vim.fn.filereadable(path) == 1

                local lines
                if file_exists then
                    lines = vim.fn.readfile(path)
                else
                    lines = { 'return {', '}' }
                end

                -- Build snippet body
                local body = format_snippet_body(text)
                local snippet_lines = {
                    '  -- name: ' .. name,
                    '  s("' .. trigger .. '", {',
                }
                -- Split body lines and add them individually
                for _, bl in ipairs(vim.split(body, '\n', { plain = true })) do
                    table.insert(snippet_lines, bl)
                end
                table.insert(snippet_lines, '  }),')

                -- Insert after `return {` (line 1), before the closing `}`
                -- Insertar en orden inverso para que queden en el orden correcto
                for i = #snippet_lines, 1, -1 do
                    table.insert(lines, 2, snippet_lines[i])
                end

                vim.fn.writefile(lines, path)

                -- Reload snippets
                require('luasnip.loaders.from_lua').load({ paths = snippets_dir })

                vim.notify('Snippet "' .. name .. '" guardado en ' .. ft .. '/custom.lua', vim.log.levels.INFO)
            end)
        end)
    end)
end

-- ============================================================================
-- Pick snippet from popup
-- ============================================================================

function M.pick()
    -- Recargar snippets primero
    require('luasnip.loaders.from_lua').load({ paths = snippets_dir })

    local snippets = collect_all_snippets()
    if #snippets == 0 then
        vim.notify('No hay snippets guardados', vim.log.levels.WARN)
        return
    end

    table.sort(snippets, function(a, b)
        if a.ft ~= b.ft then return a.ft < b.ft end
        return a.name < b.name
    end)

    vim.ui.select(snippets, {
        prompt = 'Seleccionar snippet:',
        format_item = function(item)
            return string.format('[%s] %s (%s)', item.ft, item.name, item.trigger)
        end,
    }, function(choice)
        if not choice then return end

        -- Leer contenido del snippet
        local lines = vim.fn.readfile(choice.path)
        local content = {}
        local in_body = false
        for _, line in ipairs(lines) do
            if line:match('^%s*s%(') then
                in_body = true
            elseif in_body and line:match('^%s*}%),') then
                break
            elseif in_body then
                local txt = line:match('^%s*t%("(.-)"%)')
                if txt then
                    txt = txt:gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\"', '"'):gsub('\\\\', '\\')
                    for subline in txt:gmatch('[^\n]+') do
                        table.insert(content, subline)
                    end
                end
            end
        end

        if #content == 0 then
            vim.notify('No se pudo leer el snippet', vim.log.levels.ERROR)
            return
        end

        -- Mostrar popup con nui.nvim
        local ok, Popup = pcall(require, 'nui.popup')
        if not ok then
            -- Fallback: insertar directamente si nui no esta disponible
            local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
            vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, content)
            vim.notify('Snippet "' .. choice.name .. '" insertado', vim.log.levels.INFO)
            return
        end

        local text = table.concat(content, '\n')

        -- Calcular dimensiones: scrolleable, dinamico, pero no ocupa toda la pantalla
        local content_width = 0
        for _, line in ipairs(content) do
            content_width = math.max(content_width, vim.fn.strdisplaywidth(line))
        end
        -- Ancho: preferido = ancho del contenido + padding, max 80% de pantalla
        local width = math.min(math.max(content_width + 6, 50), math.floor(vim.o.columns * 0.8))
        -- Alto: preferido = lineas del contenido + padding, max 70% de pantalla
        local height = math.min(math.max(#content + 3, 8), math.floor(vim.o.lines * 0.7))

        local popup = Popup({
            enter = true,
            focusable = true,
            border = {
                style = 'rounded',
                text = {
                    top = ' ' .. choice.name .. ' [c:Copiar <CR>:Insertar q:Cerrar] ',
                    top_align = 'center',
                },
            },
            position = '50%',
            size = { width = width, height = height },
        })

        popup:mount()

        -- Escribir contenido en el buffer del popup (EDITABLE)
        vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, content)
        vim.api.nvim_set_option_value('filetype', vim.bo.filetype, { buf = popup.bufnr }) -- mismo filetype para syntax highlighting
        vim.api.nvim_set_option_value('modifiable', true, { buf = popup.bufnr })
        vim.api.nvim_set_option_value('wrap', false, { win = popup.winid })

        -- Mapeos de accion (disponibles solo en modo normal)
        popup:map('n', 'c', function()
            local lines = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)
            local edited = table.concat(lines, '\n')
            vim.fn.setreg('+', edited)
            vim.notify('Snippet copiado al portapapeles', vim.log.levels.INFO)
            popup:unmount()
        end, { noremap = true, desc = 'Copiar al portapapeles' })

        popup:map('n', '<CR>', function()
            local lines = vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false)
            local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
            vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, lines)
            vim.notify('Snippet "' .. choice.name .. '" insertado', vim.log.levels.INFO)
            popup:unmount()
        end, { noremap = true, desc = 'Insertar en buffer' })

        popup:map('n', 'q', function() popup:unmount() end, { noremap = true })
        popup:map('n', '<Esc>', function() popup:unmount() end, { noremap = true })
    end)
end

-- ============================================================================
-- Delete snippet
-- ============================================================================

function M.delete()
    require('luasnip.loaders.from_lua').load({ paths = snippets_dir })

    local snippets = collect_all_snippets()
    if #snippets == 0 then
        vim.notify('No hay snippets guardados', vim.log.levels.WARN)
        return
    end

    table.sort(snippets, function(a, b)
        if a.ft ~= b.ft then return a.ft < b.ft end
        return a.name < b.name
    end)

    vim.ui.select(snippets, {
        prompt = 'Borrar snippet:',
        format_item = function(item)
            return string.format('[%s] %s (%s)', item.ft, item.name, item.trigger)
        end,
    }, function(choice)
        if not choice then return end

        -- Confirmar borrado (sincrono)
        local confirm = vim.fn.confirm(
            'Borrar snippet "' .. choice.name .. '"?',
            'Si\nNo',
            2
        )
        if confirm ~= 1 then
            vim.notify('Borrado cancelado', vim.log.levels.INFO)
            return
        end

        -- Leer archivo
        local lines = vim.fn.readfile(choice.path)

        -- Eliminar lineas del snippet (de start_line a end_line)
        for i = choice.end_line, choice.start_line, -1 do
            table.remove(lines, i)
        end

        -- Verificar si queda algun snippet
        local has_snippets = false
        for _, line in ipairs(lines) do
            if line:match('^%s*s%(') then
                has_snippets = true
                break
            end
        end

        if has_snippets then
            vim.fn.writefile(lines, choice.path)
        else
            -- Borrar archivo si queda vacio
            vim.fn.delete(choice.path)
        end

        -- Recargar snippets
        require('luasnip.loaders.from_lua').load({ paths = snippets_dir })

        vim.notify('Snippet "' .. choice.name .. '" borrado', vim.log.levels.INFO)
    end)
end

-- ============================================================================
-- Edit snippets file for current filetype
-- ============================================================================

function M.edit()
    local ft = vim.bo.filetype ~= '' and vim.bo.filetype or 'all'
    local path = get_snippets_file(ft)
    if vim.fn.filereadable(path) == 0 then
        vim.fn.writefile({ 'return {', '}' }, path)
    end
    vim.cmd('edit ' .. path)
end

return M
