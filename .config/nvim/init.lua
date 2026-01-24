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
    tab = '» ',
    trail = '·',
    nbsp = '␣',
    extends = '…',
    precedes = '…',
    eol = '↵',
  }
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
  require("mini.cursorword").setup()
  require("mini.indentscope").setup()
  require("mini.files").setup()
  require("mini.pick").setup()
  
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
  map("n", "<Leader>ff", ":Pick files<CR>", { desc = "Find Files" })
  map("n", "<Leader>fg", ":Pick grep_live<CR>", { desc = "Grep Live" })
  map("n", "<Leader>fb", ":Pick buffers<CR>", { desc = "Find Buffers" })
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

-- Avante (AI Assistant)
later(function()
  -- Dependencies
  add({ source = 'stevearc/dressing.nvim' })
  add({ source = 'nvim-lua/plenary.nvim' })
  add({ source = 'MunifTanjim/nui.nvim' })
  add({ source = 'MeanderingProgrammer/render-markdown.nvim' })

  -- Avante
  add({
    source = 'yetone/avante.nvim',
    hooks = {
      post_checkout = function() vim.fn.system('make BUILD_FROM_SOURCE=true') end,
      post_install = function() vim.fn.system('make BUILD_FROM_SOURCE=true') end,
    }
  })

  safecall("avante", function(avante)
    -- Setup render-markdown for Avante buffers
    require('render-markdown').setup({ file_types = { "markdown", "Avante" } })

    avante.setup({
      provider = "gemini",
      providers = {
        gemini = {
          model = "gemini-1.5-flash-latest",
          extra_request_body = {
            max_tokens = 4096,
          },
        },
      },
      behaviour = {
        auto_suggestions = false, 
      },
    })
  end)
end)

-- Skkeleton (Japanese Input)
later(function()
  add({ source = 'vim-denops/denops.vim' })
  add({ source = 'vim-skk/skkeleton' })

  -- Config (Use pcall directly or just define if available)
  if pcall(require, "skkeleton") then
      vim.fn["skkeleton#config"]({
        globalDictionaries = { "~/.skk/SKK-JISYO.L" },
        eggLikeNewline = true,
        registerConvertResult = true,
      })
      
      -- Keymaps
      vim.keymap.set("i", "<C-j>", "<Plug>(skkeleton-toggle)")
      vim.keymap.set("c", "<C-j>", "<Plug>(skkeleton-toggle)")
  end
end)
