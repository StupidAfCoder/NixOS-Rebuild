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

  # Language servers + tools the doom.d modules expect on $PATH
  home.packages = with pkgs; [
    gopls
    clang-tools # provides clangd
    cmake
  ];

  # Run Emacs as a background daemon so both launchers below are instant
  services.emacs = {
    enable = true;
    client.enable = true;
    # NOT setting defaultEditor = true, since your home.nix already sets
    # EDITOR = "nvim" for git/sudo — this leaves that alone.
  };

  # App launcher entry #1: GUI, via daemon
  xdg.desktopEntries.emacs-gui = {
    name = "Emacs";
    genericName = "Text Editor";
    exec = "emacsclient -c -a emacs";
    icon = "emacs";
    terminal = false;
    categories = [
      "Development"
      "TextEditor"
    ];
  };

  # App launcher entry #2: TUI, via daemon, inside your terminal
  xdg.desktopEntries.emacs-tui = {
    name = "Emacs (Terminal)";
    genericName = "Text Editor";
    exec = "foot -e emacsclient -t -a emacs";
    icon = "emacs";
    terminal = false; # false because foot itself is the terminal being launched
    categories = [
      "Development"
      "TextEditor"
    ];
  };

  systemd.user.services.emacs-theme-reload = {
    Unit.Description = "Reload wallust Emacs theme in running daemon";
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.emacs-pgtk}/bin/emacsclient -e '(load-theme (quote doom-wallust) t)'";
    };
  };

  systemd.user.paths.emacs-theme-reload = {
    Unit.Description = "Watch generated Emacs theme file for changes";
    Path.PathModified = "%h/.config/emacs/themes/doom-wallust-theme.el";
    Install.WantedBy = [ "default.target" ];
  };
}
