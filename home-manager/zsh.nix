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
        [[ -o zle ]] && zle reset-prompt
      }
    '';
  };

  # ANSI colors intentionally follow the Wallust terminal palette. No second theme file.
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      command_timeout = 800;
      scan_timeout = 30;
      format = "[┌─](bright-black) $username$hostname$directory$git_branch$git_status$nix_shell$cmd_duration$line_break[└─](bright-black)$character";
      right_format = "$status";
      username = {
        show_always = false;
        format = "[$user]($style) ";
        style_user = "cyan";
        style_root = "bold red";
      };
      hostname = { ssh_only = true; format = "[@$hostname](cyan) "; };
      directory = {
        format = "[$path]($style)[$read_only](red) ";
        style = "bold blue";
        truncation_length = 3;
        truncate_to_repo = true;
        truncation_symbol = "../";
        read_only = " [RO]";
      };
      character = {
        success_symbol = "[>](bold green)";
        error_symbol = "[>](bold red)";
        vimcmd_symbol = "[=](bold cyan)";
      };
      git_branch = { symbol = ""; format = "[git:$branch](yellow) "; };
      git_status = {
        format = "([$all_status$ahead_behind](red) )";
        conflicted = "!";
        modified = "~";
        untracked = "?";
        staged = "+";
        ahead = "↑";
        behind = "↓";
      };
      nix_shell = { format = "[nix:$state](cyan) "; pure_msg = "pure"; impure_msg = "dev"; };
      cmd_duration = { min_time = 2000; format = "[took $duration](bright-black) "; };
      status = { disabled = false; symbol = "exit:"; format = "[$symbol$status](red)"; };
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
