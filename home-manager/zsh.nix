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
      }
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
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
