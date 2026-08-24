{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true; # native — do NOT also add the oh-my-zsh version
    syntaxHighlighting.enable = true; # native — do NOT also add the oh-my-zsh version

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "sudo"
        "extract"
        "command-not-found"
      ];
      theme = ""; # empty — starship owns the prompt, not oh-my-zsh
    };

    initContent = ''
        # Dynamically loads one or multiple packages into an ephemeral Nix shell
        test-pkg() {
        # 1. Guard clause: Ensure at least one argument is provided
        if [ $# -eq 0 ]; then
          echo "Error: Supply at least one package name."
          return 1
        fi

        # 2. Initialize an empty array
        local pkgs=()

        # 3. Loop through every argument passed to the function
        for pkg in "$@"; do
          # Prepend the required nixpkgs# flake reference to each item
          pkgs+=("nixpkgs#$pkg")
        done

        # 4. Execute nix shell with the fully expanded array
        # Note: ''${...} is required to escape Nix string interpolation so Zsh can read it
        nix shell "''${pkgs[@]}"

        eval "$(direnv hook zsh)"
      }
      TRAPUSR1() {
        zle reset-prompt
      }
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      format = "[ $username@$hostname ](bg:blue fg:black bold) [$directory](bold cyan)$git_branch$git_status$nodejs$rust$python$golang$c$character";
      right_format = "[$time](bold purple)";

      username = {
        show_always = true;
        format = "$user";
        style_user = "bg:blue fg:black bold";
        style_root = "bg:red fg:black bold";
      };

      hostname = {
        ssh_only = false;
        format = "$hostname";
        style = "bg:blue fg:black bold";
      };

      directory = {
        format = "[$path]($style) ";
        truncation_length = 3;
        truncate_to_repo = true;
        read_only = "[RO]";
        style = "bold cyan";
      };

      character = {
        success_symbol = "[_](bold green)";
        error_symbol = "[X](bold red)";
        vimcmd_symbol = "[<](bold green)";
      };

      git_branch = {
        symbol = "";
        style = "bold yellow";
        format = "[\\[$branch\\]]($style) ";
      };

      git_status = {
        style = "bold red";
        format = "[\\[$all_status$ahead_behind\\]]($style) ";
      };

      nodejs = {
        symbol = "JS";
        style = "bold green";
        format = "[\\[$symbol:$version\\]]($style) ";
      };

      rust = {
        symbol = "RS";
        style = "bold yellow";
        format = "[\\[$symbol:$version\\]]($style) ";
      };

      python = {
        symbol = "PY";
        style = "bold blue";
        format = "[\\[$symbol:$version\\]]($style) ";
      };

      golang = {
        symbol = "GO";
        style = "bold cyan";
        format = "[\\[$symbol:$version\\]]($style) ";
      };

      c = {
        symbol = "C";
        style = "bold purple";
        format = "[\\[$symbol:$version\\]]($style) ";
      };

      fill = {
        disabled = true;
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "bold purple";
      };
    };
  };

  # these two are the ones that will actually make your terminal life easier —
  # see the plugin section below for why
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };
}
