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
      imv
    
      (pkgs.thunar.override {
        thunarPlugins = with pkgs; [
            thunar-archive-plugin
            thunar-volman
        ];
      })
        
      file-roller  
      unzip        
      zip          

      grim
      slurp
      wl-clipboard
      hyprpicker
      satty

      wallust
      matugen
      fuzzel

      btop
      rmpc
      libnotify
      mpc
      
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

  # This is some crazy command that links the hyprland.lua file to the home manager in it's mutable state meaning if you save the hyprland.lua the changes are real time (I believe it is magic)
  xdg.configFile."hypr/hyprland.lua".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos_dotfiles/hyprland.lua";

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/jpeg" = [ "imv.desktop" ];
      "image/png"  = [ "imv.desktop" ];
      "image/gif"  = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];
      "image/svg+xml" = [ "imv.desktop" ];
    };
  };

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

  #Systemd User defined Services
  services.mpd = {
    enable = true;
    musicDirectory = "~/Music";
    # Optional:
    network.listenAddress = "127.0.0.1"; # if you want to allow non-localhost connections
    network.startWhenNeeded = true; # systemd feature: only start MPD service upon connection to its socket

    extraConfig = ''
      audio_output {
        type "pulse"
        name "PipeWire PulseAudio"
      }
    '';
  };

  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
    };
  };

  services.udiskie = {
    enable = true;
    tray = "auto";
  };

  systemd.user.services.polkit-kde-agent = {
    Unit = {
      Description = "KDE Polkit Authentication Agent";
      Wants = [ "graphical-session.target" ]; # Required by the wiki
      After = [ "graphical-session.target" ]; # Required by the wiki
    };
    Install = {
      WantedBy = [ "graphical-session.target" ]; # Required by the wiki
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"; # Required by the wiki
      Restart = "on-failure"; # Required by the wiki
      RestartSec = 1; # Required by the wiki
      TimeoutStopSec = 10; # Required by the wiki
    };
  };

  # Bluetooth Tray Applet
  services.blueman-applet.enable = true;

  imports = [
      ./bash.nix
      ./ssh.nix
      ./kitty.nix
  ];
}
