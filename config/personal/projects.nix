# Personal Projects Configuration
# Integrates personal GitHub projects into nix-mox
{ config, pkgs, lib, ... }:

let
  # Personal project repositories
  projects = {
    mona-nvim = {
      url = "https://github.com/Hydepwns/mona.nvim";
      description = "Mona Neovim configuration/plugin";
      path = "~/projects/mona.nvim";
    };
    lspbridge = {
      url = "https://github.com/Hydepwns/LSPbridge";
      description = "LSP Bridge implementation";
      path = "~/projects/LSPbridge";
    };
    synthwave84-zed = {
      url = "https://github.com/Hydepwns/synthwave84-zed";
      description = "Synthwave84 theme for Zed editor";
      path = "~/projects/synthwave84-zed";
    };
  };

  # Helper script to clone/update projects
  setupProjectsScript = pkgs.writeShellScriptBin "setup-personal-projects" ''
    #!/usr/bin/env bash
    set -e
    
    echo "Setting up personal projects..."
    
    # Create projects directory if it doesn't exist
    mkdir -p ~/projects
    
    # Clone or update mona.nvim
    if [ ! -d ~/projects/mona.nvim ]; then
      echo "Cloning mona.nvim..."
      git clone ${projects.mona-nvim.url} ~/projects/mona.nvim
    else
      echo "Updating mona.nvim..."
      cd ~/projects/mona.nvim && git pull
    fi
    
    # Clone or update LSPbridge
    if [ ! -d ~/projects/LSPbridge ]; then
      echo "Cloning LSPbridge..."
      git clone ${projects.lspbridge.url} ~/projects/LSPbridge
    else
      echo "Updating LSPbridge..."
      cd ~/projects/LSPbridge && git pull
    fi
    
    # Clone or update synthwave84-zed
    if [ ! -d ~/projects/synthwave84-zed ]; then
      echo "Cloning synthwave84-zed..."
      git clone ${projects.synthwave84-zed.url} ~/projects/synthwave84-zed
    else
      echo "Updating synthwave84-zed..."
      cd ~/projects/synthwave84-zed && git pull
    fi
    
    echo "Personal projects setup complete!"
  '';

  # Neovim configuration with mona.nvim
  monaNeovimConfig = pkgs.neovimUtils.makeNeovimConfig {
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
    
    # Custom init.vim that sources mona.nvim
    customRC = ''
      " Source mona.nvim configuration if available
      if isdirectory(expand("~/projects/mona.nvim"))
        set runtimepath+=~/projects/mona.nvim
        runtime plugin/mona.vim
        lua require('mona').setup()
      endif
      
      " Additional Neovim settings
      set number
      set relativenumber
      set expandtab
      set tabstop=2
      set shiftwidth=2
      set smartindent
      set termguicolors
      
      " LSPbridge integration if available
      if isdirectory(expand("~/projects/LSPbridge"))
        set runtimepath+=~/projects/LSPbridge
      endif
    '';
    
    plugins = with pkgs.vimPlugins; [
      # Essential plugins
      telescope-nvim
      nvim-treesitter
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      friendly-snippets
      
      # UI enhancements
      lualine-nvim
      nvim-web-devicons
      bufferline-nvim
      
      # Git integration
      gitsigns-nvim
      fugitive
      
      # Additional functionality
      which-key-nvim
      nvim-autopairs
      comment-nvim
      indent-blankline-nvim
      
      # Themes
      tokyonight-nvim
      catppuccin-nvim
    ];
  };

  # Custom Neovim package with mona.nvim
  monaNeovim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped monaNeovimConfig;

in
{
  # Add project setup script to system packages
  environment.systemPackages = with pkgs; [
    setupProjectsScript
    
    # Development tools for the projects
    nodejs_20
    python3
    rustc
    cargo
    
    # LSP servers for various languages
    nodePackages.typescript-language-server
    nodePackages.vscode-langservers-extracted
    rust-analyzer
    gopls
    lua-language-server
    nil # Nix LSP
    
    # Additional tools
    ripgrep
    fd
    fzf
    tree-sitter
  ];

  # Home Manager configuration for personal projects
  home-manager.users.hydepwns = lib.mkMerge [
    {
      # Create project directories
      home.file.".config/projects.json".text = builtins.toJSON projects;
      
      # Zed configuration with synthwave84 theme
      # NOTE: After running setup-personal-projects, the theme will be available locally
      
      home.file.".config/zed/settings.json".text = builtins.toJSON {
        theme = "Synthwave84";
        vim_mode = true;
        format_on_save = "on";
        tab_size = 2;
        soft_wrap = "editor_width";
        show_whitespaces = "selection";
        
        # LSP configuration
        lsp = {
          rust-analyzer = {
            binary = {
              path = "${pkgs.rust-analyzer}/bin/rust-analyzer";
            };
          };
          typescript-language-server = {
            binary = {
              path = "${pkgs.nodePackages.typescript-language-server}/bin/typescript-language-server";
            };
          };
          nil = {
            binary = {
              path = "${pkgs.nil}/bin/nil";
            };
          };
        };
      };
      
      # Git aliases for project management
      programs.git.aliases = {
        # Project-specific aliases
        mona = "!cd ~/projects/mona.nvim && git";
        lsp = "!cd ~/projects/LSPbridge && git";
        theme = "!cd ~/projects/synthwave84-zed && git";
        
        # Quick project status
        projects-status = "!for dir in ~/projects/*/; do echo \"\\n=== $(basename $dir) ===\"; cd $dir && git status -s; done";
        projects-pull = "!for dir in ~/projects/*/; do echo \"\\n=== Updating $(basename $dir) ===\"; cd $dir && git pull; done";
      };
      
      # Shell aliases for quick project access
      programs.zsh.shellAliases = lib.mkMerge [
        {
          # Project navigation
          cdmona = "cd ~/projects/mona.nvim";
          cdlsp = "cd ~/projects/LSPbridge";
          cdtheme = "cd ~/projects/synthwave84-zed";
          
          # Quick edits
          edmona = "zed ~/projects/mona.nvim";
          edlsp = "zed ~/projects/LSPbridge";
          edtheme = "zed ~/projects/synthwave84-zed";
          
          # Neovim with mona configuration
          nvim-mona = "${monaNeovim}/bin/nvim";
          vm = "nvim-mona";
          
          # Project management
          setup-projects = "setup-personal-projects";
          update-projects = "projects-pull";
        }
      ];
      
      # Add project directories to PATH for easy script access
      home.sessionVariables = {
        PATH = "$PATH:$HOME/projects/mona.nvim/bin:$HOME/projects/LSPbridge/bin";
        MONA_NVIM_PATH = "$HOME/projects/mona.nvim";
        LSPBRIDGE_PATH = "$HOME/projects/LSPbridge";
      };
    }
  ];

  # Systemd service to auto-update projects daily (optional)
  systemd.user.services.update-personal-projects = {
    description = "Update personal GitHub projects";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${setupProjectsScript}/bin/setup-personal-projects";
    };
  };
  
  systemd.user.timers.update-personal-projects = {
    description = "Update personal projects daily";
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };
}