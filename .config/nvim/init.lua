-- ~/.config/nvim/init.lua

-- =============================================================================
-- 1. Bootstrap Mini.deps
-- =============================================================================
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
    vim.cmd('echo "Installing `mini.nvim`" | redraw')
    vim.fn.system({ 'git', 'clone', '--filter=blob:none', 'https://github.com/echasnovski/mini.nvim', mini_path })
    vim.cmd('packadd mini.nvim | helptags ALL')
end

require('mini.deps').setup({ path = { package = path_package } })

local add = MiniDeps.add
local now = MiniDeps.now
local later = MiniDeps.later

-- =============================================================================
-- 2. Basic Configuration (Immediate)
-- =============================================================================
now(function()
    vim.g.mapleader = " "
    vim.g.maplocalleader = " "

    -- Visual Options (Must be set before theme)
    vim.opt.termguicolors = true
    vim.opt.background = "dark"

    -- Auto-reload files when they change on disk
    vim.opt.autoread = true
    vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
        command = "if mode() != 'c' | checktime | endif",
        pattern = { "*" },
    })

    -- Theme: Catppuccin Mocha via Mini.base16
    require('mini.base16').setup({
        palette = {
            base00 = '#1e1e2e', base01 = '#181825', base02 = '#313244', base03 = '#45475a',
            base04 = '#585b70', base05 = '#cdd6f4', base06 = '#f5e0dc', base07 = '#b4befe',
            base08 = '#f38ba8', base09 = '#fab387', base0A = '#f9e2af', base0B = '#a6e3a1',
            base0C = '#94e2d5', base0D = '#89b4fa', base0E = '#cba6f7', base0F = '#f2cdcd',
        }
    })

    -- Mini.basics: Sensible defaults
    require('mini.basics').setup({
        options = { basic = true, extra_ui = true, win_borders = "single" },
        mappings = { basic = true, windows = true, move_with_alt = true },
    })

    -- Visuals
    require('mini.icons').setup()
    require('mini.statusline').setup()

    -- Disable swap files
    vim.opt.swapfile = false

    -- Invisible characters
    vim.opt.list = true
    vim.opt.listchars = {
        tab      = '» ',
        trail    = '·',
        nbsp     = '␣',
        extends  = '…',
        precedes = '…',
        eol      = '↵',
    }

    -- Indent setting
    vim.opt.tabstop    = 4
    vim.opt.shiftwidth = 4
    vim.opt.expandtab  = true

    -- Changelog / Memo Configuration (Ref: https://homaju.hatenablog.com/entry/2022/06/16/080957)
    -- Automatically set user name from git config
    local git_user = vim.fn.system('git config --global user.name'):gsub('%s+$', '')
    if git_user == "" then git_user = os.getenv("USER") or "Unknown" end

    vim.g.changelog_username = git_user
    vim.g.changelog_dateformat = "%Y-%m-%d"

    -- Keymap to open global changelog
    vim.keymap.set('n', '<Leader>mm', ':edit ~/Changelog<CR>', { desc = 'Open Global Changelog' })
end)

-- =============================================================================
-- 3. Mini Modules (Lazy Loaded)
-- =============================================================================
later(function()
    require("mini.ai").setup()
    require("mini.surround").setup()
    require("mini.comment").setup()
    require("mini.pairs").setup()
    require("mini.bracketed").setup()
    require("mini.tabline").setup()
    require('mini.bufremove').setup()
    vim.api.nvim_create_user_command(
        'Bufdelete',
        function()
            MiniBufremove.delete()
        end,
        { desc = 'Remove buffer' }
    )
    require("mini.cursorword").setup()
    require("mini.jump").setup()
    require("mini.jump2d").setup({
        mappings = {
            start_jumping = '<CR>',
        },
    })
    require("mini.align").setup()
    require("mini.extra").setup()
    require("mini.indentscope").setup()
    require("mini.files").setup()
    require("mini.notify").setup()
    require("mini.hipatterns").setup({
        highlighters = {
            -- Highlight hex color strings (#rrggbb) with their color
            hex_color = require("mini.hipatterns").gen_highlighter.hex_color(),

            -- Highlight common programming keywords (only if followed by ': ')
            fixme     = { pattern = '%f[%w]()FIXME():%s', group = 'MiniHipatternsFixme' },
            bug       = { pattern = '%f[%w]()BUG():%s',   group = 'MiniHipatternsFixme' },
            hack      = { pattern = '%f[%w]()HACK():%s',  group = 'MiniHipatternsHack'  },
            todo      = { pattern = '%f[%w]()TODO():%s',  group = 'MiniHipatternsTodo'  },
            note      = { pattern = '%f[%w]()NOTE():%s',  group = 'MiniHipatternsNote'  },
            memo      = { pattern = '%f[%w]()MEMO():%s',  group = 'MiniHipatternsNote'  },
            warn      = { pattern = '%f[%w]()WARN():%s',  group = 'MiniHipatternsWarn'  },
            perf      = { pattern = '%f[%w]()PERF():%s',  group = 'MiniHipatternsPerf'  },
            test      = { pattern = '%f[%w]()TEST():%s',  group = 'MiniHipatternsTest'  },
        },
    })

    -- Define highlight groups for hipatterns (Catppuccin Mocha colors)
    vim.api.nvim_set_hl(0, 'MiniHipatternsFixme', { fg = '#1e1e2e', bg = '#f38ba8', bold = true }) -- Red
    vim.api.nvim_set_hl(0, 'MiniHipatternsHack',  { fg = '#1e1e2e', bg = '#fab387', bold = true }) -- Peach/Orange
    vim.api.nvim_set_hl(0, 'MiniHipatternsTodo',  { fg = '#1e1e2e', bg = '#89b4fa', bold = true }) -- Blue
    vim.api.nvim_set_hl(0, 'MiniHipatternsNote',  { fg = '#1e1e2e', bg = '#a6e3a1', bold = true }) -- Green
    vim.api.nvim_set_hl(0, 'MiniHipatternsWarn',  { fg = '#1e1e2e', bg = '#f9e2af', bold = true }) -- Yellow
    vim.api.nvim_set_hl(0, 'MiniHipatternsPerf',  { fg = '#1e1e2e', bg = '#cba6f7', bold = true }) -- Mauve
    vim.api.nvim_set_hl(0, 'MiniHipatternsTest',  { fg = '#1e1e2e', bg = '#94e2d5', bold = true }) -- Teal    

    require("mini.pick").setup()

    require("mini.diff").setup({
        view = {
            style = 'sign',
            signs = { add = '│', change = '│', delete = '-' },
        }
    })

    require("mini.git").setup()

    -- Mini.clue (Keybinding hints)
    local miniclue = require('mini.clue')
    miniclue.setup({
        triggers = {
            -- Leader triggers
            { mode = 'n', keys = '<Leader>' },
            { mode = 'x', keys = '<Leader>' },

            -- Built-in completion
            { mode = 'i', keys = '<C-x>' },

            -- g key
            { mode = 'n', keys = 'g' },
            { mode = 'x', keys = 'g' },

            -- Marks
            { mode = 'n', keys = "'" },
            { mode = 'n', keys = '`' },
            { mode = 'x', keys = "'" },
            { mode = 'x', keys = '`' },

            -- Registers
            { mode = 'n', keys = '"' },
            { mode = 'x', keys = '"' },
            { mode = 'i', keys = '<C-r>' },
            { mode = 'c', keys = '<C-r>' },

            -- Window commands
            { mode = 'n', keys = '<C-w>' },

            -- z key
            { mode = 'n', keys = 'z' },
            { mode = 'x', keys = 'z' },
        },

        clues = {
            -- Enhance this by adding descriptions for <Leader> mapping groups
            miniclue.gen_clues.builtin_completion(),
            miniclue.gen_clues.g(),
            miniclue.gen_clues.marks(),
            miniclue.gen_clues.registers(),
            miniclue.gen_clues.windows(),
            miniclue.gen_clues.z(),

            -- Custom mapping descriptions
            { mode = 'n', keys = '<Leader>f', desc = '+Find' },
            { mode = 'n', keys = '<Leader>g', desc = '+Git' },
            { mode = 'n', keys = '<Leader>n', desc = '+Notify' },
            { mode = 'n', keys = '<Leader>b', desc = '+Buffer' },
            { mode = 'n', keys = '<Leader>c', desc = '+Config' },
            { mode = 'n', keys = '<Leader>e', desc = 'File Explorer' },
        },

        window = {
            delay = 200, -- Delay before showing the popup (ms)
            config = { width = 'auto' },
        }
    })

    -- Completion (Use omnifunc for LSP)
    require("mini.completion").setup({
        lsp_completion = { source_func = "omnifunc", auto_setup = false }
    })

    -- Keymaps
    local map = vim.keymap.set
    map("n", "<Leader>e", ":lua MiniFiles.open()<CR>", { desc = "File Explorer" })
    map("n", "<Leader>cn", function() MiniFiles.open(vim.fn.stdpath('config')) end, { desc = "Config Neovim" })
    map("n", "<Leader>ff", ":Pick files<CR>", { desc = "Find Files" })
    map("n", "<Leader>fg", ":Pick git_files<CR>", { desc = "Find Git Files" })
    map("n", "<Leader>fl", ":Pick grep_live<CR>", { desc = "Grep Live" })
    map("n", "<Leader>fo", ":Pick oldfiles<CR>", { desc = "Find Old Files" })
    map("n", "<Leader>fd", ":Pick diagnostic<CR>", { desc = "Find Diagnostics" })
    map("n", "<Leader>fb", ":Pick buffers<CR>", { desc = "Find Buffers" })

    -- Buffer
    map("n", "<Leader>bd", ":Bufdelete<CR>", { desc = "Delete Buffer" })

    -- Git
    map({ "n", "x" }, "<Leader>gc", MiniGit.show_at_cursor, { desc = "Git Context (Blame)" })

    -- Notify
    map("n", "<Leader>nh", MiniNotify.show_history, { desc = "Notify History" })

    -- Tab management
    map("n", "[t", ":tabprevious<CR>", { desc = "Previous Tab" })
    map("n", "]t", ":tabnext<CR>", { desc = "Next Tab" })
    map("n", "<Leader>tn", ":tabnew<CR>", { desc = "New Tab" })
    map("n", "<Leader>tc", ":tabclose<CR>", { desc = "Close Tab" })
end)

-- =============================================================================
-- 4. External Plugins
-- =============================================================================

local function safecall(module_name, callback)
    local ok, module = pcall(require, module_name)
    if ok then
        callback(module)
    else
        -- Silently fail on first load, mini.deps will install it
    end
end

-- Treesitter (Syntax Highlighting)
later(function()
    add({
        source = 'nvim-treesitter/nvim-treesitter',
        hooks = { 
            post_checkout = function() vim.cmd('TSUpdate') end,
            post_install = function() vim.cmd('TSUpdate') end 
        }
    })

    safecall("nvim-treesitter.configs", function(configs)
        configs.setup({
            ensure_installed = { "lua", "vim", "vimdoc", "markdown", "bash", "javascript", "typescript", "php", "go", "rust", "clojure" },
            auto_install = true,
            highlight = { enable = true },
        })
    end)
end)

-- LSP (Mason + LspConfig)
later(function()
    add({ source = 'williamboman/mason.nvim' })
    add({ source = 'williamboman/mason-lspconfig.nvim' })
    add({ source = 'neovim/nvim-lspconfig' })

    safecall("mason", function(mason)
        mason.setup()

        safecall("mason-lspconfig", function(mason_lspconfig)
            local servers = { "lua_ls", "ts_ls", "intelephense", "gopls", "rust_analyzer", "clojure_lsp" }
            mason_lspconfig.setup({ ensure_installed = servers })

            safecall("lspconfig", function(lspconfig)
                local capabilities = vim.lsp.protocol.make_client_capabilities()

                -- Common setup options
                local function setup_server(server_name)
                    local opts = {
                        capabilities = capabilities,
                        on_attach = function(client, bufnr)
                            -- Enable Mini.completion for LSP
                            vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.MiniCompletion.completefunc_lsp')

                            -- Keymaps
                            local keyopts = { buffer = bufnr }
                            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, keyopts)
                            vim.keymap.set('n', 'K', vim.lsp.buf.hover, keyopts)
                        end,
                    }

                    -- Specific settings for Lua
                    if server_name == "lua_ls" then
                        opts.settings = {
                            Lua = {
                                diagnostics = { globals = { "vim" } },
                                workspace = { checkThirdParty = false },
                                telemetry = { enable = false },
                            }
                        }
                    end

                    if vim.fn.has('nvim-0.11') == 1 then
                        vim.lsp.config(server_name, opts)
                        vim.lsp.enable(server_name)
                    else
                        lspconfig[server_name].setup(opts)
                    end
                end

                -- Manually setup all ensured servers
                for _, server in ipairs(servers) do
                    setup_server(server)
                end

                -- LSP Diagnostics Icons (Nerd Fonts)
                vim.diagnostic.config({
                    signs = {
                        text = {
                            [vim.diagnostic.severity.ERROR] = '',
                            [vim.diagnostic.severity.WARN] = '',
                            [vim.diagnostic.severity.HINT] = '󰌵',
                            [vim.diagnostic.severity.INFO] = '',
                        },
                    },
                })
            end)
        end)
    end)
end)

-- Neogit & Diffview (Git Interface)
later(function()
    add({ source = 'nvim-lua/plenary.nvim' })
    add({ source = 'sindrets/diffview.nvim' })
    add({ source = 'NeogitOrg/neogit' })

    safecall("neogit", function(neogit)
        neogit.setup({
            disable_commit_confirmation = true,
            integrations = {
                diffview = true,
            },
        })

        -- Keymaps
        vim.keymap.set("n", "<Leader>gg", neogit.open, { desc = "Neogit Status" })
    end)
end)

-- Skkeleton (Japanese Input)
later(function()
    add({ source = 'vim-denops/denops.vim' })
    add({ source = 'vim-skk/skkeleton' })

    -- Keymaps (Set unconditionally)
    vim.keymap.set("i", "<C-j>", "<Plug>(skkeleton-toggle)")
    vim.keymap.set("c", "<C-j>", "<Plug>(skkeleton-toggle)")

    -- Configuration (Apply on initialization)
    vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-initialize-pre",
        callback = function()
            vim.fn["skkeleton#config"]({
                globalDictionaries = { "~/.skk/SKK-JISYO.L" },
                eggLikeNewline = true,
                registerConvertResult = true,
            })

            -- Define Highlight Groups for Modes (Darker for better contrast)
            vim.api.nvim_set_hl(0, 'SkkeletonHira',    { bg = '#1a2b20' }) -- Darker Green
            vim.api.nvim_set_hl(0, 'SkkeletonKata',    { bg = '#2b201a' }) -- Darker Brown
            vim.api.nvim_set_hl(0, 'SkkeletonHankata', { bg = '#2b1a2b' }) -- Darker Purple
            vim.api.nvim_set_hl(0, 'SkkeletonZenkaku', { bg = '#1a202b' }) -- Darker Cyan
            vim.api.nvim_set_hl(0, 'SkkeletonAbbrev',  { bg = '#2b1a1a' }) -- Darker Red
        end,
    })

    -- Visual Feedback for Skkeleton Mode
    vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-mode-changed",
        callback = function()
            local mode = vim.fn["skkeleton#mode"]()
            local mode_map = {
                hira    = "SkkeletonHira",
                kata    = "SkkeletonKata",
                hankata = "SkkeletonHankata",
                zenkaku = "SkkeletonZenkaku",
                abbrev  = "SkkeletonAbbrev",
            }
            local hl = mode_map[mode]
            if hl then
                vim.opt_local.cursorline = true
                vim.opt_local.winhighlight = "CursorLine:" .. hl
            end
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-disable-pre",
        callback = function()
            vim.opt_local.winhighlight = ""
        end,
    })
end)
