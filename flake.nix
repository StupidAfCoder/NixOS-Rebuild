{
  description = "My System's Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nur.url = "github:nix-community/NUR";
    
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs"; 
    };

    quickshell = {
      # add ?ref=<tag> to track a tag
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";

      # THIS IS IMPORTANT
      # Mismatched system dependencies will lead to crashes and other issues.
      inputs.nixpkgs.follows = "nixpkgs";
    };

    awww.url = "git+https://codeberg.org/LGFae/awww";
    qylock.url = "github:Darkkal44/qylock";
    elegant-grub2-themes = {
      url = "github:vinceliuice/elegant-grub2-themes";
    };
  };

  outputs = { self, nixpkgs, qylock, home-manager, ... }@inputs: {
    
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      
      specialArgs = { inherit inputs; }; 
      
      modules = [
        ./nixos/hardware-configuration.nix
        ./nixos/configuration.nix
        { nixpkgs.overlays = [ inputs.nur.overlays.default ]; }
        
        ##Grub theme
        inputs.elegant-grub2-themes.nixosModules.default
        ##SDDM theme
        qylock.nixosModules.default

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          
          home-manager.extraSpecialArgs = { inherit inputs; };

          home-manager.users.swami = import ./home-manager/home.nix;
        }
      ];
    };
  };
}
