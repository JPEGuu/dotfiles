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

    -- Enable build-in packages
    vim.cmd.packadd("nvim.undotree")
    vim.opt.undofile = true
    vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"
    for _, value in ipairs(vim.opt.undodir:get()) do
        vim.fn.mkdir(value, "p")
    end
    vim.keymap.set('n', '<Leader>u', ':Undotree<CR>', { desc = 'Open Undo Tree' })

    -- Neovim 0.11 Filetype Registry (Fixes checkhealth warnings)
    vim.filetype.add({
        extension = {
            edn = "edn",
            gowork = "gowork",
            gotmpl = "gotmpl",
        },
        pattern = {
            [".*%.jsx"] = "javascript.jsx",
            [".*%.tsx"] = "typescript.tsx",
        },
    })

    -- Auto-reload files when they change on disk
    vim.opt.autoread = true
    vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
        command = "if mode() != 'c' | checktime | endif",
        pattern = { "*" },
    })

    -- Visual Options (Must be set before theme)
    vim.opt.termguicolors = true
    vim.opt.background = "dark"
    vim.opt.winblend = 0
    vim.opt.pumblend = 0

    add('rebelot/kanagawa.nvim')
    require('kanagawa').setup({
        compile = false,             -- enable compiling the colorscheme
        undercurl = true,            -- enable undercurls
        commentStyle = { italic = true },
        functionStyle = {},
        keywordStyle = { italic = true},
        statementStyle = { bold = true },
        typeStyle = {},
        transparent = true,         -- do not set background color
        dimInactive = true,         -- dim inactive window `:h hl-NormalNC`
        terminalColors = true,       -- define vim.g.terminal_color_{0,17}
        colors = {                   -- add/modify theme and palette colors
            palette = {},
            theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
        },
        overrides = function(colors) -- add/modify highlights
            return {}
        end,
        theme = "dragon",              -- Load "wave" theme
        background = {               -- map the value of 'background' option to a theme
            dark = "dragon",           -- try "dragon" !
            light = "lotus"
        },
    })
    vim.cmd("colorscheme kanagawa")

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

    -- Disable backup files
    vim.opt.backup = false

    -- Disable editorconfig
    vim.g.editorconfig = false

    -- Disable automatic newline at the end of file
    vim.opt.fixendofline = false
    vim.opt.endofline = false

    -- Clipboard sharing
    vim.opt.clipboard = 'unnamedplus'

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

    -- Treesitter Configuration (Updated for latest nvim-treesitter/main)
    add({
        source = 'nvim-treesitter/nvim-treesitter',
        -- Use 'master' while monitoring updates in 'main'
        checkout = 'main',
        -- Perform action after every checkout
        hooks = { post_checkout = function() vim.cmd('TSUpdate') end },
    })
    -- Possible to immediately execute code which depends on the added plugin
    require('nvim-treesitter').setup({
         install_dir = vim.fn.stdpath('data') .. '/site'
    })
    require('nvim-treesitter').install({ "lua", "vim", "vimdoc", "markdown", "bash", "javascript", "typescript", "php", "go", "rust", "clojure" }):wait(300000)

    -- Conjure Configuration (Set before plugin loads)
    vim.g["conjure#mapping#prefix"] = ","
    vim.g["conjure#log#hud#enabled"] = true
    vim.g["conjure#client_on_load"] = false -- Re-enable auto-start now that Treesitter is working
    vim.g["conjure#mapping#doc_word"] = false -- Disable 'K' mapping to avoid errors in PHP and prioritize LSP hover

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
    require("mini.files").setup({
        content = {
            prefix = function(entry)
                local icon, hl = MiniIcons.get(entry.fs_type, entry.name)
                local stat = vim.loop.fs_lstat(entry.path)
                if stat and stat.type == 'link' then
                    icon, hl = '', 'MiniIconsCyan'
                end
                return icon .. ' ', hl
            end,
        },
    })
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

            -- Conjure (Clojure REPL)
            { mode = 'n', keys = ',' },
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

            -- Conjure groups
            { mode = 'n', keys = ',e', desc = '+Evaluate' },
            { mode = 'n', keys = ',l', desc = '+Log' },
            { mode = 'n', keys = ',t', desc = '+Test' },
            { mode = 'n', keys = ',v', desc = '+View' },
            { mode = 'n', keys = ',c', desc = '+Connect' },
            { mode = 'n', keys = ',g', desc = '+Get' },
            { mode = 'n', keys = ',s', desc = '+Session' },
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

    -- Command-line navigation (Emacs-style)
    -- NOTE: <C-f> overrides default "open cmdline window" (use q: instead)
    -- NOTE: <C-a> overrides default "insert all matches"
    map("c", "<C-b>", "<Left>",  { desc = "Cmdline: Move left" })
    map("c", "<C-f>", "<Right>", { desc = "Cmdline: Move right" })
    map("c", "<C-a>", "<Home>",  { desc = "Cmdline: Move to beginning" })
    map("c", "<C-e>", "<End>",   { desc = "Cmdline: Move to end" })

    -- Terminal
    map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })
    map( "n", "<Leader>\\", function()
            vim.cmd('botright split | terminal')
            vim.cmd('resize 15') 
        end, { desc = "Open Terminal Window" }
    )
end)

-- =============================================================================
-- 4. External Plugins
-- =============================================================================

local function safecall(module_name, callback)
    local ok, module = pcall(require, module_name)
    if ok then
        callback(module)
    else
        print("Failed to load module: " .. module_name)
    end
end

-- Conjure (Clojure REPL Integration)
later(function()
    add({ source = 'Olical/conjure' })
end)

-- LSP (Mason + LspConfig)
later(function()
    add({ source = 'williamboman/mason.nvim' })
    add({ source = 'williamboman/mason-lspconfig.nvim' })
    add({ source = 'neovim/nvim-lspconfig' })

    -- Wait for plugins to be available in runtimepath
    vim.schedule(function()
        local servers = { "lua_ls", "ts_ls", "phpactor", "gopls", "rust_analyzer", "clojure_lsp" }

        -- Add Mason binaries to PATH
        local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
        if vim.fn.isdirectory(mason_bin) == 1 then
            vim.env.PATH = mason_bin .. ":" .. vim.env.PATH
        end

        safecall("mason", function(mason)
            mason.setup()
        end)

        safecall("mason-lspconfig", function(mason_lspconfig)
            mason_lspconfig.setup({ ensure_installed = servers })
        end)

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

        -- Ensure LSP keymaps are set on attach (Neovim 0.10+ style)
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(args)
                local bufnr = args.buf
                local client = vim.lsp.get_client_by_id(args.data.client_id)

                -- Keymaps
                local keyopts = { buffer = bufnr, silent = true }
                vim.keymap.set('n', 'gd', vim.lsp.buf.definition, keyopts)
                vim.keymap.set('n', 'K', vim.lsp.buf.hover, keyopts)

                -- Enable omnifunc for completion
                if client and client.server_capabilities.completionProvider then
                    vim.bo[bufnr].omnifunc = 'v:lua.MiniCompletion.completefunc_lsp'
                end
            end,
        })

        -- Suppress lspconfig deprecation warning in Neovim 0.11+
        local original_notify = vim.notify
        vim.notify = function(msg, level, opts)
            local m = tostring(msg)
            if m:find("deprecated") or m:find("lspconfig") then
                return
            end
            original_notify(msg, level, opts)
        end

        safecall("lspconfig", function(lspconfig)
            local capabilities = vim.lsp.protocol.make_client_capabilities()

            -- Manually setup each server
            for _, server_name in ipairs(servers) do
                local opts = {
                    capabilities = capabilities,
                }

                if server_name == "lua_ls" then
                    opts.settings = {
                        Lua = {
                            diagnostics = { globals = { "vim" } },
                            workspace = { checkThirdParty = false },
                            telemetry = { enable = false },
                        }
                    }
                end

                lspconfig[server_name].setup(opts)
            end

            -- Restore original notify after setup is complete
            vim.notify = original_notify
        end)
    end)
end)

-- Git Interface
later(function()
    -- NeoGit
    add({ source = 'nvim-lua/plenary.nvim' })
    add({ source = 'sindrets/diffview.nvim' })
    add({ source = 'NeogitOrg/neogit' })

    safecall("neogit", function(neogit)
        neogit.setup({
            disable_commit_confirmation = true,
            disable_context_highlighting= false,
            integrations = {
                diffview = true,
            },
        })

        -- Color
        vim.api.nvim_set_hl(0, "NeogitNormal", { bg = "#1f1f28", fg = "#dcd7ba" })
        vim.api.nvim_set_hl(0, "NeogitDiffContextHighlight", { bg = "#2a2a37" })

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

    -- Command-line input for Terminal mode
    local function skk_term_input()
        local term_job_id = vim.b.terminal_job_id
        if not term_job_id then
            vim.notify("No terminal job found in this buffer.", vim.log.levels.WARN)
            return
        end

        local job_id = term_job_id

        -- Use schedule to trigger input() after leaving terminal mode context
        vim.schedule(function()
            -- Trigger SKK enable for the upcoming input() prompt
            -- Using <Plug>(skkeleton-enable) instead of <C-j> to ensure it's ON even if it wasn't cleared.
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Plug>(skkeleton-enable)", true, false, true), 'm', false)

            local ok, result = pcall(vim.fn.input, "SKK: ")

            -- Ensure Skkeleton is disabled after input() returns
            -- This fixes the issue where the state is not cleared when returning to terminal mode.
            pcall(vim.fn["skkeleton#disable"])

            if ok and result and result ~= "" then
                -- Send the string to the terminal job without a newline
                vim.api.nvim_chan_send(job_id, result)
            end

            -- Restart terminal insert mode
            vim.cmd('startinsert')
        end)
    end

    vim.keymap.set('t', '<C-j>', skk_term_input, { desc = "SKK Input for Terminal" })

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
                -- For normal windows
                vim.opt_local.cursorline = true
                vim.opt_local.winhighlight = "CursorLine:" .. hl
                -- For command line
                if vim.fn.getcmdtype() ~= "" then
                    vim.api.nvim_set_hl(0, "MsgArea", { link = hl })
                    vim.cmd('redraw')
                end
            else
                vim.opt_local.winhighlight = ""
                vim.api.nvim_set_hl(0, "MsgArea", { link = "Normal" })
                vim.cmd('redraw')
            end
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-disable-pre",
        callback = function()
            vim.opt_local.winhighlight = ""
            vim.api.nvim_set_hl(0, "MsgArea", { link = "Normal" })
        end,
    })

    vim.api.nvim_create_autocmd("CmdlineLeave", {
        callback = function()
            vim.api.nvim_set_hl(0, "MsgArea", { link = "Normal" })
        end,
    })
end)
