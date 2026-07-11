{ config, pkgs, inputs, ... }:

{
    home.stateVersion = "26.05";
    home.homeDirectory = "/home/swami";

    # Your user-specific packages (VSCodium extensions, themes, etc)
    home.packages = with pkgs; [
      fastfetch
      htop
      fortune

      kdePackages.dolphin
      kdePackages.qtsvg                # Mandatory for rendering Papirus SVG icons in Qt6
      kdePackages.qtwayland            # Native Wayland support for Qt6 apps
      kdePackages.kio-admin            # Allows you to edit root files directly inside Dolphin
      kdePackages.kio-extras           # Enables thumbnails, archives, and network drives
      kdePackages.kdegraphics-thumbnailers # Enables image previews inside Dolphin
    
      kdePackages.qt6ct                # Qt6 Configuration Tool
      kdePackages.qtstyleplugin-kvantum  # The actual Qt6 rendering engine
      kdePackages.breeze-icons

      grim
      slurp
      wl-clipboard
      hyprpicker
      satty
      
      (inputs.quickshell.packages.${pkgs.system}.default.withModules [ 
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

  /*gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme; # Standard base GTK theme
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    # Ensures GTK applications use your custom cursor too
    #cursorTheme = {};
  };*/

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  imports = [
      ./bash.nix
      ./ssh.nix
      ./kitty.nix
  ];
}
