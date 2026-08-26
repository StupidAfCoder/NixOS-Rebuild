{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.doom-emacs = {
    enable = true;
    doomDir = ./doom.d;
    doomLocalDir = "${config.home.homeDirectory}/.local/share/doom";
    emacs = pkgs.emacs-pgtk;
    extraPackages = epkgs: [
      epkgs.treesit-grammars.with-all-grammars
    ];
  };

  home.packages = with pkgs; [
    gopls
    clang-tools
    cmake
    nixd
    nixfmt
  ];

  services.emacs = {
    enable = true;
    client.enable = true;
  };

  xdg.desktopEntries.emacs-gui = {
    name = "Emacs";
    genericName = "Text Editor";
    exec = "emacs";
    icon = "emacs";
    terminal = false;
    categories = [
      "Development"
      "TextEditor"
    ];
  };

  xdg.desktopEntries.emacs-tui = {
    name = "Emacs (Terminal)";
    genericName = "Text Editor";
    exec = "foot -e emacsclient -t -a emacs";
    icon = "emacs";
    terminal = false;
    categories = [
      "Development"
      "TextEditor"
    ];
  };
}
