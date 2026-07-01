{ config, pkgs, lib, ... }:

let name = "boda";
    user = "mini";
    email = "6238558+bodadotsh@users.noreply.github.com"; in
{
  git = {
    enable = true;
    ignores = [ "*.swp" ];
    lfs = {
      enable = true;
    };
    settings = {
      user.name = name;
      user.email = email;
      init.defaultBranch = "main";
      core.autocrlf = "input";
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  fish = {
    enable = true;
  };

  starship = {
    enable = true;
    enableFishIntegration = true;
  };
}
