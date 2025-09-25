{ config, pkgs, lib, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "dev";
  home.homeDirectory = "/home/dev";

  # Packages that should be installed to the user profile.
  home.packages = with pkgs; [
    # Add user-specific packages here
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # Configure zsh with home-manager for better integration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "docker"
        "npm"
        "node"
        "nodejs"
        "nix"
      ];
      theme = "robbyrussell";
    };

    # Custom aliases
    shellAliases = {
      ll = "ls -la";
      la = "ls -la";
      rebuild = "sudo nixos-rebuild switch --flake /home/dev/nixos#current-system";
      update-flake = "cd /home/dev/nixos && nix flake update";
    };

    # Custom zsh configuration
    initExtra = ''
      # Custom prompt modifications
      export EDITOR="nvim"
      export PATH="$HOME/.bun/bin:$PATH"

      # History settings
      setopt HIST_IGNORE_DUPS
      setopt HIST_IGNORE_ALL_DUPS
      setopt HIST_IGNORE_SPACE
      setopt HIST_SAVE_NO_DUPS
      setopt SHARE_HISTORY

      # Enable history search with arrow keys
      autoload -U history-search-end
      zle -N history-beginning-search-backward-end history-search-end
      zle -N history-beginning-search-forward-end history-search-end
      bindkey "^[[A" history-beginning-search-backward-end
      bindkey "^[[B" history-beginning-search-forward-end
    '';
  };

  # Neovim kickstart configuration
  xdg.configFile."nvim/init.lua".text = ''
    -- Kickstart.nvim configuration
    vim.g.mapleader = ' '
    vim.g.maplocalleader = ' '

    -- Basic settings
    vim.opt.number = true
    vim.opt.relativenumber = true
    vim.opt.mouse = 'a'
    vim.opt.showmode = false
    vim.opt.clipboard = 'unnamedplus'
    vim.opt.breakindent = true
    vim.opt.undofile = true
    vim.opt.ignorecase = true
    vim.opt.smartcase = true
    vim.opt.signcolumn = 'yes'
    vim.opt.updatetime = 250
    vim.opt.timeoutlen = 300
    vim.opt.splitright = true
    vim.opt.splitbelow = true
    vim.opt.list = true
    vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
    vim.opt.inccommand = 'split'
    vim.opt.cursorline = true
    vim.opt.scrolloff = 10
    vim.opt.hlsearch = true
    vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

    -- Basic keymaps
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

    -- Highlight when yanking text
    vim.api.nvim_create_autocmd('TextYankPost', {
      desc = 'Highlight when yanking (copying) text',
      group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
      callback = function()
        vim.highlight.on_yank()
      end,
    })

    -- LSP configuration
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end,
    })

    -- LSP server configurations
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
          },
        },
      },
      nil_ls = {},
      tsserver = {},
      pyright = {},
      rust_analyzer = {},
      gopls = {},
    }

    -- Setup LSP servers (configured via Nix, not mason)
    for server_name, server in pairs(servers) do
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      require('lspconfig')[server_name].setup(server)
    end

    -- Autocompletion
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'
    luasnip.config.setup {}

    cmp.setup {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = 'menu,menuone,noinsert' },

      mapping = cmp.mapping.preset.insert {
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-y>'] = cmp.mapping.confirm { select = true },
        ['<C-Space>'] = cmp.mapping.complete {},
        ['<C-l>'] = cmp.mapping(function()
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          end
        end, { 'i', 's' }),
        ['<C-h>'] = cmp.mapping(function()
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { 'i', 's' }),
      },
      sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'path' },
      },
    }

    -- Telescope
    require('telescope').setup {
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
      },
    }

    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    local builtin = require 'telescope.builtin'
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

    -- Additional plugins setup
    require('which-key').setup()
    require('gitsigns').setup()
    require('Comment').setup()
    require('lualine').setup()
    require('nvim-autopairs').setup()

    -- Treesitter
    require('nvim-treesitter.configs').setup {
      ensure_installed = {},
      auto_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { 'ruby' },
      },
      indent = { enable = true, disable = { 'ruby' } },
    }

    -- Colorscheme
    vim.cmd.colorscheme 'default'
  '';

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  home.stateVersion = "24.11";
}