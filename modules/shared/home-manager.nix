{ config, pkgs, lib, ... }:

let name = "boda";
    user = "mini";
    email = "6238558+bodadotsh@users.noreply.github.com";
    # SSH public key registered as a "Signing Key" on github.com/settings/keys.
    # The matching private key lives only in 1Password and is never written
    # to disk; op-ssh-sign talks to the 1Password app directly to sign.
    signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICwt0mTeMPycM9Uni+rAs7A+1EcI7qpzgcF0hRhr4scH";
in
{
  git = {
    enable = true;
    ignores = [ "*.swp" ];
    lfs = {
      enable = true;
    };
    # Sign commits/tags with the key above via the 1Password SSH agent.
    # One-time manual step required: in the 1Password app, Settings >
    # Developer > enable "Use the SSH Agent" (not declarable via nix).
    # 1Password then prompts for Touch ID/unlock on each signature.
    signing = {
      format = "ssh";
      key = signingKey;
      signByDefault = true;
      signer =
        if pkgs.stdenv.hostPlatform.isDarwin
        then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        else "/opt/1Password/op-ssh-sign";
    };
    settings = {
      user.name = name;
      user.email = email;
      init.defaultBranch = "main";
      core.autocrlf = "input";
      # Explicit store path (rather than relying on macOS's bundled
      # /usr/bin/vim, which isn't version-pinned) so commit messages open
      # in the nix-managed vim from modules/shared/packages.nix.
      core.editor = "${pkgs.vim}/bin/vim";
      pull.rebase = true;
      rebase.autoStash = true;
      # Lets `git log --show-signature` / `git verify-commit` validate SSH
      # signatures locally. GitHub verifies independently server-side, so
      # this is only for local verification.
      gpg.ssh.allowedSignersFile = toString (pkgs.writeText "allowed-signers" "${email} ${signingKey}\n");
    };
  };

  # Point ssh (and hence git-over-ssh and `gpg.ssh.program` above) at the
  # 1Password SSH agent socket, so it can offer keys stored in 1Password
  # for both authentication and commit signing.
  ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      IdentityAgent =
        if pkgs.stdenv.hostPlatform.isDarwin
        then ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''
        else "~/.1password/agent.sock";
    };
  };

  fish = {
    enable = true;
    shellAliases = {
      ga = "git add .";
      gf = "git fetch && git pull";
      gm = "git switch main";
      gp = "git push";
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
