local M = {}
local config_dir = vim.fn.stdpath('config')

---Run a git command in the config directory and return output
local function git_cmd(args)
    local cmd = 'git -C ' .. vim.fn.shellescape(config_dir) .. ' ' .. args .. ' 2>&1'
    local output = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error
    return exit_code == 0, output, exit_code
end

---Show git status in a floating window
function M.status()
    local ok, output = git_cmd('status -sb')
    if not ok then
        vim.notify('Error ejecutando git status:\n' .. output, vim.log.levels.ERROR)
        return
    end

    -- Create a scratch buffer
    local buf = vim.api.nvim_create_buf(false, true)
    local lines = vim.split(output, '\n', { plain = true })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    -- Set buffer options
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    vim.api.nvim_set_option_value('readonly', true, { buf = buf })
    vim.api.nvim_set_option_value('filetype', 'gitstatus', { buf = buf })

    -- Calculate dimensions
    local width = math.min(60, math.floor(vim.o.columns * 0.5))
    local height = math.min(#lines + 2, math.floor(vim.o.lines * 0.4))

    -- Open floating window
    vim.api.nvim_open_win(buf, true, {
        relative = 'editor',
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        border = 'rounded',
        title = ' Git Status ',
        title_pos = 'center',
        style = 'minimal',
    })

    -- Close mappings
    vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = buf, silent = true })
    vim.keymap.set('n', '<Esc>', '<cmd>close<CR>', { buffer = buf, silent = true })
end

---Git add all changes
function M.add_all()
    local ok, output = git_cmd('add -A')
    if ok then
        vim.notify('Todos los cambios añadidos al staging area', vim.log.levels.INFO)
    else
        vim.notify('Error en git add:\n' .. output, vim.log.levels.ERROR)
    end
end

---Interactive git commit
function M.commit()
    vim.ui.input({ prompt = 'Mensaje del commit: ' }, function(msg)
        if not msg or msg == '' then
            vim.notify('Commit cancelado: mensaje vacio', vim.log.levels.WARN)
            return
        end

        -- First add all changes
        git_cmd('add -A')

        -- Then commit
        local ok, output = git_cmd('commit -m ' .. vim.fn.shellescape(msg))
        if ok then
            vim.notify('Commit realizado: ' .. msg, vim.log.levels.INFO)
        else
            vim.notify('Error en git commit:\n' .. output, vim.log.levels.ERROR)
        end
    end)
end

---Git push
function M.push()
    vim.notify('Pushing...', vim.log.levels.INFO)
    local ok, output = git_cmd('push origin $(git rev-parse --abbrev-ref HEAD)')
    if ok then
        vim.notify('Push completado!', vim.log.levels.INFO)
    else
        vim.notify('Error en git push:\n' .. output, vim.log.levels.ERROR)
    end
end

---Git pull
function M.pull()
    vim.notify('Pulling...', vim.log.levels.INFO)
    local ok, output = git_cmd('pull origin $(git rev-parse --abbrev-ref HEAD)')
    if ok then
        vim.notify('Pull completado! Reinicia Neovim para aplicar cambios.', vim.log.levels.INFO)
    else
        vim.notify('Error en git pull:\n' .. output, vim.log.levels.ERROR)
    end
end

---Full sync: pull -> add -> commit -> push
function M.sync()
    vim.ui.input({ prompt = 'Mensaje del commit: ' }, function(msg)
        if not msg or msg == '' then
            vim.notify('Sync cancelado: mensaje vacio', vim.log.levels.WARN)
            return
        end

        vim.notify('Sincronizando...', vim.log.levels.INFO)

        -- 1. Pull
        local ok1, out1 = git_cmd('pull origin $(git rev-parse --abbrev-ref HEAD)')
        if not ok1 then
            vim.notify('Error en pull:\n' .. out1, vim.log.levels.ERROR)
            return
        end

        -- 2. Add all
        git_cmd('add -A')

        -- 3. Commit
        local ok3, out3 = git_cmd('commit -m ' .. vim.fn.shellescape(msg))
        if not ok3 then
            -- Check if nothing to commit
            if out3:match('nothing to commit') or out3:match('working tree clean') then
                vim.notify('No hay cambios para commitear', vim.log.levels.INFO)
            else
                vim.notify('Error en commit:\n' .. out3, vim.log.levels.ERROR)
                return
            end
        end

        -- 4. Push
        local ok4, out4 = git_cmd('push origin $(git rev-parse --abbrev-ref HEAD)')
        if ok4 then
            vim.notify('Sync completado! Configuracion sincronizada con GitHub.', vim.log.levels.INFO)
        else
            vim.notify('Error en push:\n' .. out4, vim.log.levels.ERROR)
        end
    end)
end

---Safe quit: save all, sync if needed, then quit
function M.safe_quit()
    -- 1. Save all buffers
    vim.cmd('wa')
    vim.notify('Todos los buffers guardados', vim.log.levels.INFO)

    -- 2. Check if there are git changes
    local ok_status, status_out = git_cmd('status --porcelain')
    if not ok_status then
        vim.notify('Error verificando git status:\n' .. status_out, vim.log.levels.ERROR)
        return
    end

    local has_changes = status_out:match('%S')

    if has_changes then
        -- Commit message automatico
        local msg = 'sincronizado'

        vim.notify('Sincronizando y cerrando...', vim.log.levels.INFO)

        -- Pull
        local ok1, out1 = git_cmd('pull origin $(git rev-parse --abbrev-ref HEAD)')
        if not ok1 then
            vim.notify('Error en pull:\n' .. out1, vim.log.levels.ERROR)
            return
        end

        -- Add
        git_cmd('add -A')

        -- Commit
        local ok3, out3 = git_cmd('commit -m ' .. vim.fn.shellescape(msg))
        if not ok3 then
            if not (out3:match('nothing to commit') or out3:match('working tree clean')) then
                vim.notify('Error en commit:\n' .. out3, vim.log.levels.ERROR)
                return
            end
        end

        -- Push
        local ok4, out4 = git_cmd('push origin $(git rev-parse --abbrev-ref HEAD)')
        if ok4 then
            vim.notify('Sync completado! Cerrando Neovim...', vim.log.levels.INFO)
        else
            vim.notify('Error en push:\n' .. out4, vim.log.levels.ERROR)
            return
        end
    end

    -- 3. Quit Neovim
    vim.cmd('qa')
end

return M
