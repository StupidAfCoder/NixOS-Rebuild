{ config, pkgs, inputs, ... }:

let
  pixelarticons = pkgs.stdenvNoCC.mkDerivation {
    pname = "pixelarticons";
    version = "unstable-2024";
    src = pkgs.fetchFromGitHub {
      owner = "halfmage";
      repo = "pixelarticons";
      rev = "efb6e172f2cec1abb1fb61a9a7bfe60e671ec002";
      hash = "sha256-5GNscKfRnZqYeBUc3B8ESUY7scifJUjASpbxuk6iWRY=";
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/pixelarticons
      cp -r svg $out/share/pixelarticons/
    '';
  };
in
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
      foot

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

      zathura
      foliate

      pixelarticons

      (inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules [ 
        pkgs.kdePackages.qtwayland 
        pkgs.kdePackages.qt5compat 
        pkgs.kdePackages.qtsvg          # SVG icon rendering in QML
        pkgs.kdePackages.qtmultimedia
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
  xdg.configFile."quickshell".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos_dotfiles/quickshell";
  xdg.dataFile."pixelarticons".source = "${pixelarticons}/share/pixelarticons/";

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
    platformTheme.name = "qtct";
    style.name = "kvantum";
  };

  #Systemd User defined Services
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules [
        pkgs.kdePackages.qtwayland
        pkgs.kdePackages.qt5compat
        pkgs.kdePackages.qtsvg
        pkgs.kdePackages.qtmultimedia
      ]}/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

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

  services.udiskie = {
    enable = true;
    tray = "auto";
  };

  # Bluetooth Tray Applet
  services.blueman-applet.enable = true;

  programs.foot = {
    enable = true;
    settings = {
      main = {
        dpi-aware = "yes";
        font = "Cozette:size=13";
      };
      mouse = {
        hide-when-typing = "yes";
      };
    };
  };

  imports = [
      ./bash.nix
      ./ssh.nix
      ./kitty.nix
      ./font.nix
  ];
}
