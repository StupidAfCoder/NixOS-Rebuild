{ config, pkgs, inputs, ... }:

{
    home.stateVersion = "26.05";
    home.homeDirectory = "/home/swami";

    # Your user-specific packages (VSCodium extensions, themes, etc)
    home.packages = with pkgs; [
      fastfetch
      htop
      fortune
      killall
    
    (pkgs.thunar.override {
      thunarPlugins = with pkgs; [
          thunar-archive-plugin
          thunar-volman
      ];
    })
      
      # The Archive Backend Engines
      file-roller  # The graphical UI that actually processes the extraction
      unzip        # Core CLI tool to read zips
      zip          # Core CLI tool to create zips

      grim
      slurp
      wl-clipboard
      hyprpicker
      satty
      
      (inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules [ 
        pkgs.kdePackages.qtwayland 
        pkgs.kdePackages.qt5compat 
      ])
    ];

  wayland.windowManager.hyprland = {
    enable = true;
    
    # We already compile Hyprland at the OS level in configuration.nix.
    # Setting these to null prevents Home Manager from downloading a conflicting version.
    package = null;
    portalPackage = null;
    
    # Notice we completely omit the 'settings = {}' block.
  };

  # 2. The UWSM Environment Hook (You found this in the docs)
  # This guarantees Quickshell and other apps can find your Nix binaries.
  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  # We still symlink the Lua file directly so we can write real code, not Nix-generated strings.
  xdg.configFile."hypr/hyprland.lua".source = ../hyprland.lua;

  # Modernized Git Configuration
   programs.git = {
     enable = true;
     settings = {
      user = {
        name = "StupidAfCoder";
        email = "storekeeper1983@gmail.com";
       };
     };
   };

  home.pointerCursor = {
    gtk.enable = true;
    x11.enable = true;
    name = "MeguminCursor";
    size = 24;
    
    # We build a custom package locally instead of fetching from a dead URL
    package = pkgs.stdenv.mkDerivation {
      pname = "megumin-cursor";
      version = "1.0";
      
      # Points to the folder we just moved into your dotfiles repo
      src = ../cursors/MeguminCursor;
      
      # stdenv automatically 'cd's into the src directory, so we just copy everything inside it (.)
      installPhase = ''
        mkdir -p $out/share/icons/MeguminCursor
        cp -R . $out/share/icons/MeguminCursor/
      '';
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme; 
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "MeguminCursor";
      size = 24;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "gtk2";
  };

  imports = [
      ./bash.nix
      ./ssh.nix
      ./kitty.nix
  ];
}
