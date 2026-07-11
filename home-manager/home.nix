{ config, pkgs, inputs, ... }:

{
    home.stateVersion = "26.05";
    home.homeDirectory = "/home/swami";

    # Your user-specific packages (VSCodium extensions, themes, etc)
    home.packages = with pkgs; [
      fastfetch
      htop
      fortune

      # The Lightweight GTK File Manager Architecture
      pkgs.thunar
      pkgs.thunar-archive-plugin # Allows extracting zip/tar directly in Thunar
      pkgs.thunar-volman         # Automounts USBs

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
