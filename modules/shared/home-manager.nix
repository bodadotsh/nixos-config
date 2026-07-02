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
    # Keyless commit/tag signing via sigstore's gitsign: no GPG key to
    # generate or back up, identity is proven via an OIDC login (GitHub)
    # instead. First sign of each session pops a browser window; note
    # GitHub doesn't render these as "Verified" since it doesn't yet trust
    # sigstore's CA (see https://github.com/sigstore/gitsign#readme).
    signing = {
      format = "x509";
      signByDefault = true;
      signer = "${pkgs.gitsign}/bin/gitsign";
    };
    settings = {
      user.name = name;
      user.email = email;
      init.defaultBranch = "main";
      core.autocrlf = "input";
      pull.rebase = true;
      rebase.autoStash = true;
      # Pre-select the GitHub OIDC flow so the browser auth redirects
      # straight to GitHub instead of showing a provider picker.
      gitsign.connectorID = "https://github.com/login/oauth";
    };
  };

  fish = {
    enable = true;
    shellAliases = {
      ga = "git add .";
      gf = "git fetch && git pull";
      gm = "git switch main";
      gs = "git status";
    };
    # mise (https://mise.jdx.dev) is installed via Homebrew (see
    # modules/darwin/home-manager.nix `homebrew.brews`) rather than nixpkgs:
    # nixpkgs' `mise` is built from source via rustPlatform.buildRustPackage
    # (incl. its test suite), and aarch64-darwin builds are frequently
    # missing from cache.nixos.org, forcing a slow local Rust compile on
    # every nixpkgs bump. Homebrew ships a prebuilt bottle for Apple
    # Silicon, so we only wire up shell activation here.
    interactiveShellInit = ''
      mise activate fish | source
    '';
  };

  # Managed by home-manager so it picks up `home.sessionPath` etc. below
  # (mirrors the fish integration above; nix-darwin already sets zsh as
  # the login shell in modules/darwin/home-manager.nix).
  zsh = {
    enable = true;
    initContent = ''
      eval "$(mise activate zsh)"
    '';
  };

  starship = {
    enable = true;
    enableFishIntegration = true;
  };
}
