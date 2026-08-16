# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  config,
  pkgs,
  inputs,
  ...
}:

let
  # Define your custom system package right here in memory
  megumin-cursor = pkgs.stdenvNoCC.mkDerivation {
    pname = "megumin-cursor";
    version = "1.0";

    # Point this strictly to the local Git-tracked folder
    src = ./assets/MeguminCursor;

    # We don't need to 'make' or 'build' anything, just install
    dontBuild = true;

    installPhase = ''
      # Create the standard Linux icon directory structure inside the Nix store
      mkdir -p $out/share/icons/MeguminCursor

      # Copy all files from the source into the new store path
      cp -R . $out/share/icons/MeguminCursor/
    '';
  };

  pixel-operator = pkgs.stdenvNoCC.mkDerivation {
    pname = "pixel-operator";
    version = "2018.10.04";
    src = pkgs.fetchzip {
      url = "https://dl.dafont.com/dl/?f=pixel_operator";
      sha256 = "1a6wb3awlc5qn2wbw1iy03c759m97gl9gnsqn9iwjdjlixqzfa9l";
      extension = "zip";
      stripRoot = false;
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp *.ttf $out/share/fonts/truetype/
    '';
  };
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  environment.sessionVariables = {
    # Force applications to use the NVIDIA VA-API driver
    LIBVA_DRIVER_NAME = "nvidia";
    NIXOS_OZONE_WL = "1";
    XCURSOR_THEME = "MeguminCursor";
    XCURSOR_SIZE = "24";
    QT_QPA_PLATFORMTHEME = "qt6ct";
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024; # 16 GiB safety net
    }
  ];

  boot.zswap.enable = true;

  boot.kernel.sysctl = {
    "vm.swappiness" = 40;
  };

  boot.kernelModules = [ "i2c-dev" ];

  boot.extraModprobeConfig = ''
    options nvidia NVreg_RegistryDwords="RMUseSwI2c=0x01;RMI2cSpeed=100"
  '';

  systemd.oomd.enable = true;
  security.polkit.enable = true;

  services.xserver.enable = true;

  services.udisks2.enable = true;
  services.upower.enable = true;
  services.blueman.enable = true;

  services.tlp.enable = true;

  # Thunar backend services for Trash, Networking, and Thumbnails
  services.gvfs.enable = true;
  services.tumbler.enable = true;

  security.rtkit.enable = true; # Gives audio high-priority processing
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you ever want to use JACK for pro audio, uncomment this:
    # jack.enable = true;
  };

  security.pam.services.hyprlock = { };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.loader = {
    grub = {
      enable = true;
      device = "nodev"; # "nodev" is used for UEFI
      efiSupport = true;
      useOSProber = true;
    };
    efi.canTouchEfiVariables = true;

    elegant-grub2-theme = {
      enable = true;
      theme = "mountain"; # Options: forest, mojave, mountain, wave
      type = "blur"; # Options: window, float, sharp, blur
      side = "left"; # Options: left, right
      color = "dark"; # Options: dark, light
      screen = "1080p"; # Options: 1080p, 2k, 4k
      logo = "system"; # Options: default, system
    };
  };

  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # NM's own connectivity probe (full/limited/portal/none), used by the
  # bar's network icon to distinguish "link up" from "actually online".
  # Default check interval is several minutes -- set to 15s so the icon
  # reacts to a real outage in roughly one bar refresh cycle instead of lagging.
  networking.networkmanager.connectionConfig = {
    enable = true;
    interval = 15;
    uri = "http://detectportal.firefox.com/success.txt";
  };

  networking.nameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";
  time.hardwareClockInLocalTime = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IN";
    LC_IDENTIFICATION = "en_IN";
    LC_MEASUREMENT = "en_IN";
    LC_MONETARY = "en_IN";
    LC_NAME = "en_IN";
    LC_NUMERIC = "en_IN";
    LC_PAPER = "en_IN";
    LC_TELEPHONE = "en_IN";
    LC_TIME = "en_IN";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."swami" = {
    isNormalUser = true;
    description = "Yash";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "i2c"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;

  # configuration.nix (or wherever your system config lives)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.hyprland = {
    enable = true;
    withUWSM = true; # recommended for most users
    xwayland.enable = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland = {
      enable = true;
    };

    package = pkgs.kdePackages.sddm;

    extraPackages = [
      pkgs.kdePackages.qtsvg
      pkgs.kdePackages.qtdeclarative
      pkgs.kdePackages.qt5compat
      pkgs.kdePackages.qtmultimedia
      pkgs.kdePackages.qtwayland
    ];

    settings = {
      Theme = {
        CursorTheme = "MeguminCursor";
        CursorSize = 24;
      };
    };
  };

  programs.qylock = {
    enable = true;
    theme = "pixel-coffee"; # any directory name under themes/
    sddm.enable = true; # installs theme + sets it active (default)
    #quickshell.enable = true;       # adds `qylock-lock` to PATH (default)
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    kitty
    git
    wget
    firefox
    inputs.awww.packages.${pkgs.stdenv.hostPlatform.system}.awww
    pkgs.nicotine-plus
    lxqt.lxqt-policykit
    megumin-cursor
    hyprpolkitagent

    brightnessctl # brightness widget
    ddcutil # external monitor brightness control (optional)
    lm_sensors # temp/sensor widgets
    libqalculate # if you build a calculator module
    inetutils
    # ffmpeg-full.override { withUnfree = true; }

    kdePackages.qt6ct
    libsForQt5.qtstyleplugin-kvantum
    kdePackages.qtstyleplugin-kvantum

    adw-gtk3

    gcc
    cmake
    ninja
    pkg-config
    clang
    clang-tools # clang-format, clangd
    qt6.qtdeclarative # QML tooling incl. qmlformat, qmllint

    libcava
    aubio

    aseprite
    cloudflare-warp

    vscodium-fhs
  ];

  services.cloudflare-warp.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  hardware.graphics = {
    enable = true;

    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  services.udev.packages = [ pkgs.brightnessctl ];

  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
  '';

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    cozette
    google-fonts
    nerd-fonts.caskaydia-cove # good icon coverage if you want it — swap for any nerd font you like
    rubik # optional, only if you like Caelestia's UI typeface
    material-symbols
    pixel-operator
  ];

  users.groups.i2c = { };

  nix.settings.auto-optimise-store = true;
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
