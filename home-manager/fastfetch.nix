{ pkgs, ... }:
{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "nixos_small";
        padding = {
          top = 1;
          right = 4;
        };
      };
      display = {
        separator = "  "; # Clean whitespace separator
        color = {
          keys = "magenta"; # Inherits your Wallust magenta
          title = "blue"; # Inherits your Wallust blue
        };
      };
      modules = [
        {
          type = "title";
          format = "{1}@{2}";
        }
        {
          type = "custom";
          format = "───────────────";
        }
        {
          type = "os";
          key = "system ";
        }
        {
          type = "kernel";
          key = "kernel ";
        }
        {
          type = "packages";
          key = "pkgs   ";
          format = "{1} (nix)";
        }
        {
          type = "shell";
          key = "shell  ";
        }
        {
          type = "wm";
          key = "wm     ";
        }
        {
          type = "terminal";
          key = "term   ";
        }
        {
          type = "uptime";
          key = "uptime ";
        }
        {
          type = "custom";
          format = "───────────────";
        }
        {
          type = "colors";
          symbol = "square";
        }
      ];
    };
  };
}
