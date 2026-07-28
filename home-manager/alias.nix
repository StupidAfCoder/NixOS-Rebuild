{
  home.shellAliases =
    let
      flakeDir = "~/.nixos_dotfiles";
      hostName = "nixos";
    in
    {
      rebuild = "sudo nixos-rebuild switch --flake ${flakeDir}#${hostName}";
      dry-build = "sudo nixos-rebuild dry-build --flake ${flakeDir}#${hostName}";
      test-rebuild = "sudo nixos-rebuild test --flake ${flakeDir}#${hostName}";

      update = "nix flake update --flake ${flakeDir}";

      list-gen = "sudo nixos-rebuild list-generations --flake ${flakeDir}#${hostName}";

      clean-all = "sudo nix-collect-garbage -d";

      se = "sudoedit";
    };
}
