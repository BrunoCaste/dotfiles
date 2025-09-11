{
  description = "Circus - NixOS & home-manager dotfiles for the clown troupe";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    hyprpaper = {
      url = "github:hyprwm/hyprpaper";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";

      lib = nixpkgs.lib.extend (final: prev: import ./lib prev);

      overlays = lib.loadOverlays { inherit inputs; dir = ./overlays; };

      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };

      # Load NixOS modules
      circusNixos = lib.loadModules {
        platform = "nixos";
        dir = ./modules/nixos;
      };
      circusHome = lib.loadModules {
        platform = "home";
        dir = ./modules/home;
      };

      defaultUser = "bruno";
      
      mkHost = hostname: lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs lib; };
        modules = [
          ./hosts/nixos/${hostname}
          home-manager.nixosModules.home-manager
          {
            nixpkgs.config.allowUnfree = true;
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit hostname inputs pkgs; };
              users.${defaultUser} = {
                home = {
                  username = defaultUser;
                  homeDirectory = "/home/${defaultUser}";
                };
              };
            };
          }
        ] ++ circusNixos ++ circusHome;
      };

    in {
      inherit lib;

      packages.${system} = lib.loadPackages {
        inherit pkgs;
        dir = ./packages;
      };

      nixosConfigurations = lib.mapAttrs (name: _:
        mkHost name
      ) (builtins.readDir ./hosts/nixos);

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          nixos-rebuild
          home-manager
          git
        ];
        shellHook = ''
          echo "🎪 Welcome to the Circus configuration!"
        '';
      };

      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
