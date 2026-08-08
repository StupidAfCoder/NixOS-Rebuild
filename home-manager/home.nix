{
  config,
  pkgs,
  inputs,
  ...
}:

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
  scriptPython = pkgs.python3.withPackages (ps: [
    ps.pillow
    ps.materialyoucolor
  ]);
in
{
  home.stateVersion = "26.05";
  home.homeDirectory = "/home/swami";
  home.sessionVariables = {
    EDITOR = "nvim";
    SUDO_EDITOR = "codium --wait";
  };

  home.packages = with pkgs; [
    fastfetch
    htop
    fortune
    killall
    imv
    hyprlock
    brave
    discord

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

    go
    gopls

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
    scriptPython

    libreoffice-fresh
    localsend
    chromium

    pywalfox-native
    imagemagick
    neovim
    nixfmt
    godot

    (inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules [
      pkgs.kdePackages.qtwayland
      pkgs.kdePackages.qt5compat
      pkgs.kdePackages.qtsvg # SVG icon rendering in QML
      pkgs.kdePackages.qtmultimedia
    ])
  ];

  programs.rmpc = {
    enable = true;
    config = ''
      ConfigFile(
          address: "127.0.0.1:6600",
      )
    '';
  };

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
  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  # This is some crazy command that links the hyprland.lua file to the home manager in it's mutable state meaning if you save the hyprland.lua the changes are real time (I believe it is magic)
  xdg.configFile."hypr/hyprland.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos_dotfiles/hyprland.lua";
  xdg.configFile."quickshell".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos_dotfiles/quickshell";
  xdg.dataFile."pixelarticons".source = "${pixelarticons}/share/pixelarticons/";
  xdg.configFile."matugen".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos_dotfiles/matugen";
  xdg.configFile."wallust".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos_dotfiles/wallust";
  # xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.nixos_dotfiles/nvim"; whenever I actually config neovim

  xdg.configFile."qt6ct/qt6ct.conf" = {
    text = ''
      [Appearance]
      color_scheme_path=/home/swami/.config/qt6ct/colors/matugen.conf
      custom_palette=true
      style=Fusion
    '';
    force = true;
  };

  xdg.configFile."qt5ct/qt5ct.conf" = {
    text = ''
      [Appearance]
      color_scheme_path=/home/swami/.config/qt5ct/colors/matugen.conf
      custom_palette=true
      style=Fusion
    '';
    force = true;
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/jpeg" = [ "imv.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "image/gif" = [ "imv.desktop" ];
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

  programs.firefox = {
    enable = true;
    nativeMessagingHosts = [ pkgs.pywalfox-native ];
    profiles.default.extensions.packages = [
      pkgs.nur.repos.rycee.firefox-addons.pywalfox
    ];
  };

  programs.zathura = {
    enable = true;
    options = {
      adjust-open = "width";
      pages-per-row = 1;
      scroll-step = 60;
      selection-clipboard = "clipboard";
      statusbar-home-tilde = true;
      window-title-basename = true;

      recolor = true;
      recolor-keephue = true;
    };
    mappings = {
      "d" = "scroll half-down";
      "u" = "scroll half-up";
      "R" = "reload";
      "r" = "rotate";
      "C" = "toggle_recolor";
    };
    extraConfig = ''
      include "${config.home.homeDirectory}/.config/zathura/colors-wallust"
    '';
  };

  gtk = {
    enable = true;
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
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
    platformTheme.name = "qt6ct";
    style.name = "Fusion";
  };

  #Systemd User defined Services
  systemd.user.services.quickshell = {
    Unit = {
      Description = "Quickshell desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${
        inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default.withModules [
          pkgs.kdePackages.qtwayland
          pkgs.kdePackages.qt5compat
          pkgs.kdePackages.qtsvg
          pkgs.kdePackages.qtmultimedia
        ]
      }/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.quickshell-theme-assets = {
    Unit.Description = "Regenerate Quickshell themed bar assets";
    Service = {
      Type = "oneshot";
      Environment = "PATH=${scriptPython}/bin:/run/current-system/sw/bin";
      ExecStart = "%h/.nixos_dotfiles/quickshell/bar/scripts/generate-theme-assets.sh";
    };
  };

  systemd.user.paths.quickshell-theme-assets = {
    Unit.Description = "Watch colors.json for theme changes";
    Path.PathModified = "%h/.nixos_dotfiles/quickshell/bar/theme/colors.json";
    Install.WantedBy = [ "default.target" ];
  };

  services.mpd = {
    enable = true;
    musicDirectory = "${config.home.homeDirectory}/Music";
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

  services.mpris-proxy.enable = true;

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
        font = "Pixel Operator Mono:pixelsize=16,JetBrainsMono Nerd Font:pixelsize=16";
        include = "~/.config/foot/wallust-colors.ini";
        pad = "8x8";
      };
      cursor = {
        style = "block";
        blink = "no";
      };
      mouse = {
        hide-when-typing = "yes";
      };
      csd = {
        size = 0;
        border-width = 0;
      };
    };
  };

  programs.bash.enable = true;

  imports = [
    ./alias.nix
    ./ssh.nix
    ./kitty.nix
    ./font.nix
    ./zsh.nix
  ];
}
