-- =====================================================================
--  Neovim Pro Setup (single-file, Lua-first, lazy.nvim plugin manager)
--  Drop this file at: ~/.config/nvim/init.lua
--  Requires Neovim 0.11+
-- =====================================================================

-- Leader
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ---------------------------------------------------------------------
-- Bootstrap lazy.nvim
-- ---------------------------------------------------------------------
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git', 'clone', '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', lazypath
    })
end
vim.opt.rtp:prepend(lazypath)

-- ---------------------------------------------------------------------
-- Core options
-- ---------------------------------------------------------------------
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.termguicolors = true
opt.signcolumn = 'yes'
opt.updatetime = 200
opt.timeoutlen = 400
opt.scrolloff = 6
opt.splitbelow = true
opt.splitright = true
opt.cursorline = true
opt.clipboard = 'unnamedplus'

-- ---------------------------------------------------------------------
-- Plugins
-- ---------------------------------------------------------------------
require('lazy').setup({
    -- Theme & UI
    { 'folke/tokyonight.nvim',   lazy = false,  priority = 1000,                              opts = { style = 'night' } },
    {
        'nvim-lualine/lualine.nvim',                                                                                                                                                           dependencies = { 'nvim-tree/nvim-web-devicons' },                                                                                                                                      opts = function() return { options = { theme = 'tokyonight', globalstatus = true } } end                                                                                           },                                                                                                                                                                                     { 'akinsho/bufferline.nvim', version = '*', dependencies = 'nvim-tree/nvim-web-devicons', opts = {} },                                                                                 { 'rcarriga/nvim-notify',    opts = {} },                                                                                                                                              { 'stevearc/dressing.nvim',  opts = {} },                                                                                                                                              { 'folke/which-key.nvim',    opts = {} },

    -- File explorer
    {
        'nvim-tree/nvim-tree.lua',
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            require('nvim-tree').setup({
                view = { width = 34, side = 'left' },                                                                                                                                                  filters = { dotfiles = false },                                                                                                                                                        git = { enable = true },                                                                                                                                                           })                                                                                                                                                                                 end
    },

    -- Finder & fuzzy
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.6',
        dependencies = {
            'nvim-lua/plenary.nvim',
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        },
        opts = { defaults = { prompt_prefix = '  ', selection_caret = ' ', path_display = { 'smart' } } },
        config = function(_, opts)
            local telescope = require('telescope')
            telescope.setup(opts)
            pcall(telescope.load_extension, 'fzf')
            pcall(telescope.load_extension, 'projects')
        end
    },

    -- Treesitter
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        opts = {
            ensure_installed = {
                'bash', 'c', 'lua', 'python', 'javascript', 'typescript', 'tsx', 'html', 'css', 'json', 'yaml', 'toml',
                'markdown', 'markdown_inline', 'vim', 'vimdoc', 'gitignore'
            },
            highlight = { enable = true },
            indent = { enable = true },
        }
    },

    -- Git
    { 'lewis6991/gitsigns.nvim',             opts = {} },

    -- Indentation guides
    { 'lukas-reineke/indent-blankline.nvim', main = 'ibl',                                 opts = {} },

    -- Comments
    { 'numToStr/Comment.nvim',               opts = {} },

    -- Autopairs
    { 'windwp/nvim-autopairs',               opts = { check_ts = true } },

    -- Todo highlights
    { 'folke/todo-comments.nvim',            dependencies = 'nvim-lua/plenary.nvim',       opts = {} },

    -- Diagnostics list & quickfix++
    { 'folke/trouble.nvim',                  dependencies = 'nvim-tree/nvim-web-devicons', opts = {} },

    -- Terminal
    { 'akinsho/toggleterm.nvim',             version = '*',                                opts = { open_mapping = [[<c-`>]], direction = 'float' } },

    -- Project & sessions
    {
        'ahmedkhalf/project.nvim',
        config = function()
            require('project_nvim').setup({
                detection_methods = { 'pattern' },
                patterns = { '.git', 'Makefile', 'package.json', 'pyproject.toml' },
            })
        end
    },
    { 'folke/persistence.nvim',  event = 'BufReadPre', opts = {} },

    -- LSP / Formatting / Completion
    { 'williamboman/mason.nvim', opts = {} },
    {
        'williamboman/mason-lspconfig.nvim',
        dependencies = { 'mason.nvim' },
        opts = { ensure_installed = { 'lua_ls', 'pyright', 'ts_ls', 'bashls', 'html', 'cssls', 'jsonls', 'yamlls' } }
    },
    { 'neovim/nvim-lspconfig' }, -- solo para leer server_configurations (sin framework)

    { 'hrsh7th/nvim-cmp' },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'saadparwaiz1/cmp_luasnip' },
    { 'L3MON4D3/LuaSnip',            build = 'make install_jsregexp' },
    { 'rafamadriz/friendly-snippets' },

    {
        'stevearc/conform.nvim',
        opts = {
            formatters_by_ft = {
                lua = { 'stylua' },
                python = { 'ruff_format' },
                javascript = { 'prettier' },
                typescript = { 'prettier' },
                css = { 'prettier' },
                html = { 'prettier' },
                json = { 'jq' },
                yaml = { 'yamlfmt' },
            },
            format_on_save = function(_) return { timeout_ms = 1000, lsp_fallback = true } end,
        }
    },

    -- Breadcrumbs
    { 'SmiteshP/nvim-navic', dependencies = 'neovim/nvim-lspconfig' },

    -- LSP progress
    { 'j-hui/fidget.nvim',   opts = {} },

    -- Ollama (local AI)
    {
        'nomnivore/ollama.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            model = 'devstral-2:123b-cloud',
            prompt = '> ',
            accept_keymap = '<C-y>',
            chat_separator = '────────────────────────────',
            mappings = { send = '<C-y>', close = '<Esc>' },
            options = {
                num_ctx = 2048,
                num_predict = 512,
                temperature = 0.6,
                top_p = 0.9,
            },
            prompts = {
                Ask_About_Code = {
                    prompt =
                    [[Eres un experto. Responde preguntas sobre el código seleccionado ($sel) o, si no hay selección, sobre el buffer. Pregunta: $input]],
                    input_label = 'Q> ',
                    action = 'display',
                },
                Explain_Code = {
                    prompt = [[Explica claramente qué hace este código: $sel]],
                    action = 'display',
                },
                Generate_Code = {
                    prompt = [[Genera el código solicitado: $input. Si hay contexto: $sel]],
                    action = 'display',
                },
                Modify_Code = {
                    prompt = [[Refactoriza o modifica el siguiente código según: $input. Código: $sel]],
                    action = 'replace',
                },
                Simplify_Code = {
                    prompt = [[Simplifica el siguiente código manteniendo la funcionalidad: $sel]],
                    action = 'replace',
                },
                Raw = {
                    prompt = [[$input]],
                    action = 'display',
                },
            },
        }
    },

    -- CodeCompanion + Ollama
    {
        'olimorris/codecompanion.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {
            strategies = {
                chat = { adapter = 'ollama', options = { model = 'devstral-2:123b-cloud', temperature = 0.7 } },
                inline = { adapter = 'ollama', options = { model = 'devstral-2:123b-cloud', temperature = 0.7 } },
            },
            keymaps = {
                toggle_chat = '<leader>cc',
                inline_code = '<leader>ci',
            },
        }
    },
    {
        'kawre/leetcode.nvim',
        build = ':TSUpdate html',
        dependencies = {
            'nvim-telescope/telescope.nvim',
            'nvim-lua/plenary.nvim',
            'MunifTanjim/nui.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        opts = {
            lang = 'python3', -- ¡Ajusta tu lenguaje aquí!
        },
        event = 'VeryLazy',
    },

    -- Wilder: cmdline popup (autocompletado visual de comandos)
    {
        'gelguy/wilder.nvim',
        dependencies = { 'romgrk/fzy-lua-native' },
        event = 'CmdlineEnter',
        config = function()
            local wilder = require('wilder')
            wilder.setup({ modes = { ':', '/', '?' } })
            wilder.set_option('pipeline', {
                wilder.branch(
                    wilder.cmdline_pipeline({ fuzzy = 1, fuzzy_filter = wilder.lua_fzy_filter() }),
                    wilder.vim_search_pipeline()
                ),
            })
            wilder.set_option('renderer', wilder.renderer_mux({
                [':'] = wilder.popupmenu_renderer({
                    highlighter = wilder.lua_fzy_highlighter(),
                    left = { ' ', wilder.popupmenu_devicons() },
                    right = { ' ', wilder.popupmenu_scrollbar() },
                    highlights = { default = 'WilderMenu' },
                }),
                ['/'] = wilder.wildmenu_renderer({
                    highlighter = wilder.lua_fzy_highlighter(),
                }),
                ['?'] = wilder.wildmenu_renderer({
                    highlighter = wilder.lua_fzy_highlighter(),
                }),
            }))
        end,
    },

    -- Docstring generator (multi-language)
    {
        'danymat/neogen',
        dependencies = 'nvim-treesitter/nvim-treesitter',
        config = true,
    },

    -- Markdown Preview (navegador) con tema Tokyo Night
    {
        'iamcco/markdown-preview.nvim',
        cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
        ft = { 'markdown' },
        build = 'cd app && npm install',
        init = function()
            vim.g.mkdp_theme = 'dark'
            vim.g.mkdp_markdown_css = vim.fn.expand('~/.config/nvim/markdown-preview/tokyonight-markdown.css')
            vim.g.mkdp_highlight_css = vim.fn.expand('~/.config/nvim/markdown-preview/tokyonight-highlight.css')
            vim.g.mkdp_refresh_slow = 0
            vim.g.mkdp_page_title = '${name}'
        end,
    },

    -- OpenCode (Claude Code integration)
    {
        'nickjvandyke/opencode.nvim',
        version = '*',
        dependencies = {
            {
                'folke/snacks.nvim',
                optional = true,
                opts = {
                    input = {},
                    picker = {
                        actions = {
                            opencode_send = function(...)
                                return require('opencode').snacks_picker_send(...)
                            end,
                        },
                        win = {
                            input = {
                                keys = {
                                    ['<a-a>'] = { 'opencode_send', mode = { 'n', 'i' } },
                                },
                            },
                        },
                    },
                },
            },
        },
        config = function()
            vim.g.opencode_opts = {}
            vim.o.autoread = true

            vim.keymap.set({ 'n', 'x' }, '<C-a>', function()
                require('opencode').ask('@this: ', { submit = true })
            end, { desc = 'Ask opencode…' })
            vim.keymap.set({ 'n', 'x' }, '<C-x>', function()
                require('opencode').select()
            end, { desc = 'Execute opencode action…' })
            vim.keymap.set({ 'n', 't' }, '<C-.>', function()
                require('opencode').toggle()
            end, { desc = 'Toggle opencode' })

            vim.keymap.set({ 'n', 'x' }, 'go', function()
                return require('opencode').operator('@this ')
            end, { desc = 'Add range to opencode', expr = true })
            vim.keymap.set('n', 'goo', function()
                return require('opencode').operator('@this ') .. '_'
            end, { desc = 'Add line to opencode', expr = true })

            vim.keymap.set('n', '<S-C-u>', function()
                require('opencode').command('session.half.page.up')
            end, { desc = 'Scroll opencode up' })
            vim.keymap.set('n', '<S-C-d>', function()
                require('opencode').command('session.half.page.down')
            end, { desc = 'Scroll opencode down' })

            -- Re-map native increment/decrement since <C-a> and <C-x> are taken
            vim.keymap.set('n', '+', '<C-a>', { desc = 'Increment under cursor', noremap = true })
            vim.keymap.set('n', '-', '<C-x>', { desc = 'Decrement under cursor', noremap = true })
        end,
    },

    -- CopilotChat (GitHub Copilot Chat integration)
    {
        'CopilotC-Nvim/CopilotChat.nvim',
        dependencies = {
            { 'nvim-lua/plenary.nvim' },
            {
                'zbirenbaum/copilot.lua',
                config = function()
                    require('copilot').setup({
                        panel = { enabled = false },
                        suggestion = { enabled = false },
                    })
                end,
            },
        },
        build = 'make tiktoken',
        opts = {
            model = 'gpt-4.1',
            temperature = 0.1,
            window = {
                layout = 'vertical',
                width = 0.5,
            },
            auto_insert_mode = false,
        },
        config = function(_, opts)
            require('CopilotChat').setup(opts)

            -- Keymaps para CopilotChat (evitamos <leader>cc que usa CodeCompanion)
            local map = vim.keymap.set
            local silent = { silent = true }

            map({ 'n', 'v' }, '<leader>co', '<cmd>CopilotChatOpen<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Open' }))
            map({ 'n', 'v' }, '<leader>cq', '<cmd>CopilotChatClose<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Close' }))
            map({ 'n', 'v' }, '<leader>ct', '<cmd>CopilotChatToggle<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Toggle' }))
            map({ 'n', 'v' }, '<leader>cr', '<cmd>CopilotChatReset<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Reset' }))
            map({ 'n', 'v' }, '<leader>cs', '<cmd>CopilotChatStop<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Stop' }))
            map('v', '<leader>ce', '<cmd>CopilotChatExplain<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Explain' }))
            map('v', '<leader>cf', '<cmd>CopilotChatFix<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Fix' }))
            map('v', '<leader>cd', '<cmd>CopilotChatDocs<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Docs' }))
            map('v', '<leader>cm', '<cmd>CopilotChatTests<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Tests' }))
            map('v', '<leader>cv', '<cmd>CopilotChatReview<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Review' }))
            map('v', '<leader>cO', '<cmd>CopilotChatOptimize<CR>', vim.tbl_extend('force', silent, { desc = 'CopilotChat: Optimize' }))

            -- Quick chat con input
            map({ 'n', 'v' }, '<leader>cp', function()
                local input = vim.fn.input('CopilotChat: ')
                if input ~= '' then
                    require('CopilotChat').ask(input, { selection = require('CopilotChat.select').buffer })
                end
            end, vim.tbl_extend('force', silent, { desc = 'CopilotChat: Quick prompt' }))

            -- Selector de modelo
            local models = {
                { name = 'GPT-4.1',          id = 'gpt-4.1' },
                { name = 'GPT-4o',            id = 'gpt-4o' },
                { name = 'o3-mini',           id = 'o3-mini' },
                { name = 'o1',                id = 'o1' },
                { name = 'Claude 3.5 Sonnet', id = 'claude-3.5-sonnet' },
                { name = 'Claude 3.7 Sonnet', id = 'claude-3.7-sonnet' },
            }
            map({ 'n', 'v' }, '<leader>cM', function()
                vim.ui.select(models, {
                    prompt = 'CopilotChat model:',
                    format_item = function(item) return item.name end,
                }, function(choice)
                    if not choice then return end
                    require('CopilotChat').config.model = choice.id
                    vim.notify('CopilotChat modelo: ' .. choice.name, vim.log.levels.INFO)
                end)
            end, vim.tbl_extend('force', silent, { desc = 'CopilotChat: Cambiar modelo' }))
        end,
    },

}, {
    checker = { enabled = true, notify = false },
    change_detection = { notify = false },
})

-- ---------------------------------------------------------------------
-- Colorscheme
-- ---------------------------------------------------------------------
vim.cmd.colorscheme('tokyonight')

-- ---------------------------------------------------------------------
-- LSP setup (Neovim 0.11+ API — sin framework lspconfig)
-- ---------------------------------------------------------------------
local capabilities = require('cmp_nvim_lsp').default_capabilities()
require('mason').setup()
require('mason-lspconfig').setup()

-- Lista de servers
local servers = { 'ts_ls', 'pyright', 'lua_ls', 'bashls', 'html', 'cssls', 'jsonls', 'yamlls' }

-- Para cada server, usamos la definición de nvim-lspconfig/server_configurations
for _, server in ipairs(servers) do
    local ok, mod = pcall(require, 'lspconfig.server_configurations.' .. server)
    if ok and mod and mod.default_config then
        local default = vim.deepcopy(mod.default_config)
        local filetypes = default.filetypes or {}

        -- Ajustes específicos que tenías (ej. lua_ls globals = { 'vim' })
        if server == 'lua_ls' then
            default.settings = default.settings or {}
            default.settings.Lua = default.settings.Lua or {}
            default.settings.Lua.diagnostics = default.settings.Lua.diagnostics or {}
            default.settings.Lua.diagnostics.globals = { 'vim' }
            default.settings.Lua.workspace = { checkThirdParty = false }
            default.settings.Lua.telemetry = { enable = false }
        end

        -- Autocmd para iniciar el cliente en buffers con esos filetypes
        vim.api.nvim_create_autocmd('FileType', {
            pattern = filetypes,
            callback = function(args)
                local bufnr = args.buf
                -- Evitar duplicados
                for _, client in pairs(vim.lsp.get_clients({ buffer = bufnr })) do
                    if client.name == server then return end
                end
                -- root_dir según default_config.root_dir si existe
                local fname = vim.api.nvim_buf_get_name(bufnr)
                local root_dir = default.root_dir and default.root_dir(fname)
                local cfg = vim.lsp.config(vim.tbl_deep_extend('force', default, {
                    name = server,
                    capabilities = capabilities,
                    root_dir = root_dir or vim.fn.getcwd(),
                }))
                vim.lsp.start(cfg, { bufnr = bufnr })
            end
        })
    end
end

-- nvim-navic attach al arrancar cualquier LSP que soporte documentSymbol
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then return end
        -- Solo atachear a servidores que soporten documentSymbol (navic lo necesita)
        if client.server_capabilities.documentSymbolProvider then
            pcall(function() require('nvim-navic').attach(client, args.buf) end)
        end
    end
})

-- Diagnósticos
vim.diagnostic.config({
    virtual_text = { spacing = 2, prefix = '●' },
    float = { border = 'rounded' },
})

-- ---------------------------------------------------------------------
-- Completion (nvim-cmp)
-- ---------------------------------------------------------------------
local cmp = require('cmp')
local luasnip = require('luasnip')
require('luasnip.loaders.from_vscode').lazy_load()
local lua_snippets_ok = pcall(require('luasnip.loaders.from_lua').lazy_load, { paths = vim.fn.stdpath('config') .. '/snippets' })
if not lua_snippets_ok then
    vim.notify('Error cargando snippets LuaSnip: algunos archivos pueden estar corruptos', vim.log.levels.WARN)
end

cmp.setup({
    snippet = { expand = function(args) luasnip.lsp_expand(args.body) end },
    mapping = cmp.mapping.preset.insert({
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
        ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { 'i', 's' }),
    }),
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
        { name = 'buffer' },
    })
})

-- Cmdline completion
cmp.setup.cmdline({ '/', '?' }, { mapping = cmp.mapping.preset.cmdline(), sources = { { name = 'buffer' } } })
cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({ { name = 'path' } }, { { name = 'cmdline' } })
})

-- ---------------------------------------------------------------------
-- Keymaps (leader = space)
-- ---------------------------------------------------------------------
local map = vim.keymap.set
local silent = { noremap = true, silent = true }

-- Normaliza la selección visual (evita rangos invertidos que rompen ollama.nvim)
local function with_norm_vis(cmd)
    return function()
        local _, ls, cs = unpack(vim.fn.getpos("'<"))
        local _, le, ce = unpack(vim.fn.getpos("'>"))
        if ls > le or (ls == le and cs > ce) then
            vim.fn.setpos("'<", { 0, le, ce, 0 })
            vim.fn.setpos("'>", { 0, ls, cs, 0 })
        end
        vim.cmd(cmd)
    end
end

-- File explorer & files
map('n', '<leader>e', require('nvim-tree.api').tree.toggle, silent)
map('n', '<leader>w', '<cmd>w<CR>', silent)
map('n', '<leader>q', '<cmd>q<CR>', silent)

-- Telescope
map('n', '<leader>ff', '<cmd>Telescope find_files<CR>', silent)
map('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', silent)
map('n', '<leader>fb', '<cmd>Telescope buffers<CR>', silent)
map('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', silent)

-- Windows
map('n', '<leader>sv', '<C-w>v', silent)
map('n', '<leader>sh', '<C-w>s', silent)
map('n', '<leader>se', '<C-w>=', silent)
map('n', '<leader>sx', '<cmd>close<CR>', silent)

-- Diagnostics
map('n', '[d', vim.diagnostic.goto_prev, silent)
map('n', ']d', vim.diagnostic.goto_next, silent)
map('n', '<leader>do', vim.diagnostic.open_float, silent)
map('n', '<leader>dl', '<cmd>Trouble diagnostics toggle<CR>', silent)

-- LSP
map('n', 'gd', vim.lsp.buf.definition, silent)
map('n', 'gr', vim.lsp.buf.references, silent)
map('n', 'gi', vim.lsp.buf.implementation, silent)
map('n', 'K', vim.lsp.buf.hover, silent)
map('n', '<leader>rn', vim.lsp.buf.rename, silent)
map('n', '<leader>ca', vim.lsp.buf.code_action, silent)

-- Formatting (Conform)
map({ 'n', 'v' }, '<leader>f', function() require('conform').format({ async = true }) end, silent)

-- Comment
map({ 'n', 'v' }, '<leader>/', function() require('Comment.api').toggle.linewise.current() end, silent)

-- Git
map('n', '<leader>gb', '<cmd>Gitsigns blame_line<CR>', silent)
map('n', '<leader>gd', '<cmd>Gitsigns diffthis<CR>', silent)

-- Trouble
map('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<CR>', silent)
map('n', '<leader>xq', '<cmd>Trouble qflist toggle<CR>', silent)

-- Terminal
map('n', '<leader>tt', '<cmd>ToggleTerm<CR>', silent)

-- Project/session
map('n', '<leader>pp', function() require('telescope').extensions.projects.projects({}) end, silent)
map('n', '<leader>ss', function() require('persistence').load() end, silent)
map('n', '<leader>sl', function() require('persistence').load({ last = true }) end, silent)
map('n', '<leader>sd', function() require('persistence').stop() end, silent)

-- Ollama
-- Abrir selector de prompts de Ollama (Normal y Visual) en <leader>p
-- CORRECCIÓN:
-- Modo Normal (sin cambios)
map('n', '<leader>p', ":<C-u>lua require('ollama').prompt()<CR>", { silent = true, desc = 'Ollama prompt' })

-- Modo Visual (¡Usando la función normalizadora!)
map('v', '<leader>p', with_norm_vis("lua require('ollama').prompt()"), { silent = true, desc = 'Ollama prompt' })
-- Visual: invoca prompts concretos con selección normalizada
map('v', '<leader>aa', with_norm_vis("lua require('ollama').prompt('Ask_About_Code')"), { silent = true })
map('v', '<leader>ee', with_norm_vis("lua require('ollama').prompt('Explain_Code')"), { silent = true })
map('v', '<leader>gg', with_norm_vis("lua require('ollama').prompt('Generate_Code')"), { silent = true })
map('v', '<leader>mm', with_norm_vis("lua require('ollama').prompt('Modify_Code')"), { silent = true })
map('v', '<leader>ss', with_norm_vis("lua require('ollama').prompt('Simplify_Code')"), { silent = true })
map('v', '<leader>rr', with_norm_vis("lua require('ollama').prompt('Raw')"), { silent = true })

-- CodeCompanion shortcuts
map('n', '<leader>cc', '<cmd>CodeCompanionChatToggle<CR>', silent)
map('v', '<leader>ci', '<cmd>CodeCompanionInline<CR>', silent)

-- Snippets personalizados (LuaSnip nativo)
map('v', '<leader>sy', function() require('snippets').save_visual() end, vim.tbl_extend('force', silent, { desc = 'Snippets: Guardar selección' }))
map('n', '<leader>sp', function() require('snippets').pick() end, vim.tbl_extend('force', silent, { desc = 'Snippets: Buscar y expandir' }))
map('n', '<leader>se', function() require('snippets').edit() end, vim.tbl_extend('force', silent, { desc = 'Snippets: Editar archivo' }))

-- Docstring generator (neogen)
map('n', '<leader>dg', function() require('neogen').generate() end, vim.tbl_extend('force', silent, { desc = 'Generar docstring' }))

-- Neovim config git sync
map('n', '<leader>Ns', function() require('nvimgit').status() end, vim.tbl_extend('force', silent, { desc = 'Git: Status' }))
map('n', '<leader>Na', function() require('nvimgit').add_all() end, vim.tbl_extend('force', silent, { desc = 'Git: Add all' }))
map('n', '<leader>Nc', function() require('nvimgit').commit() end, vim.tbl_extend('force', silent, { desc = 'Git: Commit' }))
map('n', '<leader>Np', function() require('nvimgit').push() end, vim.tbl_extend('force', silent, { desc = 'Git: Push' }))
map('n', '<leader>Nl', function() require('nvimgit').pull() end, vim.tbl_extend('force', silent, { desc = 'Git: Pull' }))
map('n', '<leader>Ny', function() require('nvimgit').sync() end, vim.tbl_extend('force', silent, { desc = 'Git: Sync (pull+commit+push)' }))

-- Which-key labels
local wk = require('which-key')
wk.add({
    { '<leader>f',  group = 'Find/Telescope' },
    { '<leader>g',  group = 'Git' },
    { '<leader>x',  group = 'Diagnostics (Trouble)' },
    { '<leader>s',  group = 'Sessions' },
    { '<leader>p',  group = 'Ollama' },
    { '<leader>pp', desc = 'Projects (Telescope)' },
    { '<leader>t',  group = 'Terminal' },
    { '<leader>c',  group = 'Chat/AI' },
    { '<leader>co', desc = 'CopilotChat: Open' },
    { '<leader>ct', desc = 'CopilotChat: Toggle' },
    { '<leader>cp', desc = 'CopilotChat: Quick prompt' },
    { '<leader>ce', desc = 'CopilotChat: Explain' },
    { '<leader>cf', desc = 'CopilotChat: Fix' },
    { '<leader>cd', desc = 'CopilotChat: Docs' },
    { '<leader>cm', desc = 'CopilotChat: Tests' },
    { '<leader>cv', desc = 'CopilotChat: Review' },
    { '<leader>cO', desc = 'CopilotChat: Optimize' },
    { '<leader>cM', desc = 'CopilotChat: Cambiar modelo' },
    { '<leader>S',  group = 'Snippets' },
    { '<leader>sy', desc = 'Snippets: Guardar selección' },
    { '<leader>sp', desc = 'Snippets: Buscar y expandir' },
    { '<leader>se', desc = 'Snippets: Editar archivo' },
    { '<leader>dg', desc = 'Generar docstring (neogen)' },
    { '<leader>N',  group = 'Nvim Config (Git)' },
    { '<leader>Ns', desc = 'Git: Status' },
    { '<leader>Na', desc = 'Git: Add all' },
    { '<leader>Nc', desc = 'Git: Commit' },
    { '<leader>Np', desc = 'Git: Push' },
    { '<leader>Nl', desc = 'Git: Pull' },
    { '<leader>Ny', desc = 'Git: Sync (full)' },
})

-- =====================================================================
-- LeetCode Help Popup (<leader>lh)
-- Requiere: nui.nvim (instalado por leetcode.nvim)
-- =====================================================================

vim.keymap.set("n", "<leader>lh", function()
    local ok, Popup = pcall(require, "nui.popup")
    if not ok then
        vim.notify("nui.nvim no encontrado. Asegúrate de que leetcode.nvim esté instalado.", vim.log.levels.ERROR)
        return
    end

    local event = require("nui.utils.autocmd").event

    local popup = Popup({
        enter = true,
        focusable = true,
        border = {
            style = "rounded",
            text = {
                top = " LeetCode Cheatsheet ",
                top_align = "center",
            },
        },
        position = "50%",
        size = {
            width = "80",
            height = "60%",
        },
    })

    -- El contenido de tu documentación formateado
    local content = {
        " COMMAND        DESCRIPTION",
        " ────────────────────────────────────────────────────────────",
        " Leet           Opens menu dashboard",
        " menu           Same as Leet",
        " exit           Close leetcode.nvim",
        " console        Opens console pop-up for currently opened question",
        " info           Opens a pop-up with info about current question",
        " tabs           Opens a picker with all currently opened question tabs",
        " yank           Yanks the code section",
        " lang           Opens a picker to change the language",
        " run            Run currently opened question",
        " test           Same as Leet run",
        " submit         Submit currently opened question",
        " random         Opens a random question",
        " daily          Opens the question of today",
        " list           Opens a picker with all available problems",
        " open           Opens current question in default browser",
        " restore        Try to restore default question layout",
        " last_submit    Replace editor code with latest submitted code",
        " reset          Resets editor code section to default snippet",
        " inject         Re-injects editor code, keeping code section intact",
        " fold           Applies folding to imports section",
        " desc           Toggle question description",
        " toggle         Same as Leet desc",
        " stats          Toggle description stats visibility",
        " ",
        " [COOKIE / CACHE]",
        " cookie update  Opens a prompt to enter a new cookie",
        " cookie delete  Deletes stored cookie and logs out",
        " cache update   Fetches problems and updates local cache",
        " ",
        " [TECLAS]",
        " q / <Esc>      Cerrar esta ventana",
    }

    -- Montar el popup
    popup:mount()

    -- Escribir el contenido en el buffer del popup
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, content)

    -- Configurar buffer como no editable
    vim.api.nvim_set_option_value("modifiable", false, { buf = popup.bufnr })
    vim.api.nvim_set_option_value("readonly", true, { buf = popup.bufnr })
    vim.api.nvim_set_option_value("filetype", "leetcode-help", { buf = popup.bufnr })

    -- Resaltado de sintaxis básico para que se vea bonito
    vim.api.nvim_create_autocmd("FileType", {
        buffer = popup.bufnr,
        callback = function()
            vim.fn.matchadd("Title", [=[^\s*\[.*\]]=])
            vim.fn.matchadd("Keyword", [[^\s*\w\+]]) -- Resaltar los comandos (primera palabra)
            vim.fn.matchadd("Comment", [[Same as.*]]) -- Resaltar notas secundarias
        end,
    })

    -- Mapeos para cerrar la ventana con q o Esc
    popup:map("n", "q", function() popup:unmount() end, { noremap = true })
    popup:map("n", "<Esc>", function() popup:unmount() end, { noremap = true })

    -- Cerrar automáticamente si cambiamos de buffer
    popup:on(event.BufLeave, function() popup:unmount() end)
end, { desc = "LeetCode Help Popup" })

-- ---------------------------------------------------------------------
-- Final touches
-- ---------------------------------------------------------------------
-- Save with Ctrl-s
vim.keymap.set({ 'n', 'i', 'v' }, '<C-s>', '<cmd>w<CR>', { silent = true })

-- Resaltar yank
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function() vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 120 }) end,
})

-- Telescope projects extension (en caso de carga perezosa)
pcall(function() require('telescope').load_extension('projects') end)


-- =============================================================
-- Global Help / Cheatsheet Popup (<leader>ah)
-- Muestra todos los atajos de teclado configurados
-- =====================================================================
vim.keymap.set("n", "<leader>ah", function()
  local ok, Popup = pcall(require, "nui.popup")
  if not ok then
    vim.notify("nui.nvim no encontrado.", vim.log.levels.ERROR)
    return
  end

  local event = require("nui.utils.autocmd").event

  local popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " Configuración Neovim Pro ",
        top_align = "center",
      },
    },
    position = "50%",
    size = {
      width = "90",
      height = "85%",
    },
  })

  local content = {
    " ATAJO            ACCIÓN",
    " ──────────────────────────────────────────────────────────────────",
    " [GENERAL]",
    " <C-s>            Guardar archivo (Modo normal/insert/visual)",
    " <leader>w        Guardar archivo",
    " <leader>q        Cerrar ventana/buffer",
    " <leader>e        Abrir/Cerrar Explorador de Archivos (NvimTree)",
    " ",
    " [BUSCADOR (TELESCOPE)]",
    " <leader>ff       Buscar archivos (Find Files)",
    " <leader>fg       Buscar texto en proyecto (Live Grep)",
    " <leader>fb       Buscar en buffers abiertos",
    " <leader>fh       Ayuda de neovim (Help Tags)",
    " <leader>pp       Cambiar de proyecto",
    " ",
    " [VENTANAS]",
    " <leader>sv       Dividir verticalmente  (|)",
    " <leader>sh       Dividir horizontalmente (-)",
    " <leader>se       Igualar tamaño de ventanas",
    " <leader>sx       Cerrar división actual",
    " ",
    " [LSP & CÓDIGO]",
    " gd               Ir a definición",
    " gr               Ir a referencias",
    " gi               Ir a implementación",
    " K                Ver documentación (Hover)",
    " <leader>rn       Renombrar variable/función",
    " <leader>ca       Acciones de código (Code Action)",
    " <leader>f        Formatear código (Prettier/Ruff/etc)",
    " <leader>al       Comentar/Descomentar línea o bloque (<leader>+/)",
    " ",
    " [DIAGNÓSTICOS]",
    " [d / ]d          Ir al error anterior / siguiente",
    " <leader>do       Ver error en ventana flotante",
    " <leader>dl       Ver lista de errores (Trouble)",
    " <leader>xx       Alternar panel de errores (Trouble)",
    " ",
    " [GIT]",
    " <leader>gb       Ver quién modificó la línea (Blame)",
    " <leader>gd       Ver diferencias (Diff)",
    " ",
    " [INTELIGENCIA ARTIFICIAL (OLLAMA)]",
    " <leader>p        Prompt genérico (Normal y Visual)",
    " <leader>aa       Preguntar sobre el código (Ask)",
    " <leader>ee       Explicar código seleccionado",
    " <leader>gg       Generar código",
    " <leader>mm       Modificar/Refactorizar código",
    " <leader>ss       Simplificar código",
    " <leader>cc       Abrir Chat (CodeCompanion)",
    " <leader>ci       Chat en línea (Inline)",
    " ",
    " [COPILOT CHAT]",
    " <leader>co       Abrir CopilotChat",
    " <leader>ct       Toggle CopilotChat",
    " <leader>cp       Quick prompt (input libre)",
    " <leader>ce       Explicar selección",
    " <leader>cf       Fix selección",
    " <leader>cd       Generar docs selección",
    " <leader>cm       Generar tests selección",
    " <leader>cv       Review selección",
    " <leader>cO       Optimizar selección",
    " <leader>cM       Cambiar modelo de CopilotChat",
    " ",
    " [SNIPPETS PERSONALIZADOS]",
    " <leader>sy       Guardar selección como snippet (modo visual)",
    " <leader>sp       Buscar snippet (popup editable: c copiar, Enter insertar)",
    " <leader>se       Editar archivo de snippets del filetype",
    " ",
    " [DOCSTRINGS]",
    " <leader>dg       Generar docstring (Python/C/C++/Java/JS/Go...)",
    " ",
    " [LEETCODE]",
    " <leader>lh       Ver menú de ayuda exclusivo de LeetCode",
    " :Leet            Abrir Dashboard",
    " ",
    " [NVIM CONFIG (GIT)]",
    " <leader>Ns       Git status",
    " <leader>Na       Git add all",
    " <leader>Nc       Git commit",
    " <leader>Np       Git push",
    " <leader>Nl       Git pull",
    " <leader>Ny       Git sync (pull+commit+push)",
    " ",
    " [SESIONES & TERMINAL]",
    " <leader>ss       Restaurar sesión actual",
    " <leader>sl       Restaurar última sesión",
    " <leader>sd       Detener grabación de sesión",
    " <leader>tt       Abrir/Cerrar Terminal flotante",
    " <C-`>            Abrir/Cerrar Terminal flotante",
    " ",
    " [SALIR]",
    " q / <Esc>        Cerrar esta ayuda",
  }

  popup:mount()
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, content)

  -- Configuración del buffer
  vim.api.nvim_set_option_value("modifiable", false, { buf = popup.bufnr })
  vim.api.nvim_set_option_value("readonly", true, { buf = popup.bufnr })
  vim.api.nvim_set_option_value("filetype", "nvim-help", { buf = popup.bufnr })

  -- Resaltado de sintaxis (Usando comillas normales para evitar errores)
  vim.api.nvim_create_autocmd("FileType", {
    buffer = popup.bufnr,
    callback = function()
      -- Regex: Corchetes al inicio (ej: [GIT])
      vim.fn.matchadd("Title", "^\\s*\\[.*\\]")
      -- Regex: Teclas especiales entre <> (ej: <leader>)
      vim.fn.matchadd("Special", "<[^>]\\+>")
      -- Regex: Palabras clave al inicio (ej: gd)
      vim.fn.matchadd("String", "^\\s*\\w\\+")
      -- Regex: Comentarios
      vim.fn.matchadd("Comment", "Same as.*")
    end,
  })

  -- Cerrar
  popup:map("n", "q", function() popup:unmount() end, { noremap = true })
  popup:map("n", "<Esc>", function() popup:unmount() end, { noremap = true })
  popup:on(event.BufLeave, function() popup:unmount() end)
end, { desc = "Ayuda Global / Cheatsheet" })
