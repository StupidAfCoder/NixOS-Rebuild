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
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      scan_timeout = 10;
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
