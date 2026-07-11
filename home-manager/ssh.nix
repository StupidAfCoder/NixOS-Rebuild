{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # Kills the default config warning
    settings = {
      # Fallback for all other hosts
      "*" = { }; 
      
      # Specific GitHub rules
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = "yes";
      };
    };
  };
}