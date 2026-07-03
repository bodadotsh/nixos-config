{ config, pkgs, lib, home-manager, ... }:

let
  user = "mini";
in
{
  imports = [
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  # System-level (nix-darwin) fish integration: generates /etc/fish/config.fish
  # to source the nix environment (PATH, NIX_PROFILES, etc.), the same way
  # /etc/zshenv already does for zsh. Without this, any fish process not
  # spawned through a login shell that runs path_helper (e.g. Ghostty's
  # `command = fish`) won't see nix/home-manager-installed packages on PATH.
  programs.fish.enable = true;

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix {};
    # Prebuilt bottle avoids the slow from-source Rust build nixpkgs'
    # `mise` derivation requires when aarch64-darwin isn't yet cached
    # upstream (see modules/shared/home-manager.nix for shell activation).
    brews = [ "mise" ];
    # onActivation.cleanup = "uninstall";

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    # If you have previously added these apps to your Mac App Store profile (but not installed them on this system),
    # you may receive an error message "Redownload Unavailable with This Apple ID".
    # This message is safe to ignore. (https://github.com/dustinlyons/nixos-config/issues/83)
    masApps = {
      "Amphetamine" = 937984704;
      "Bear: Markdown Notes" = 1091189122;
      "uBlock Origin Lite" = 6745342698;
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    # Back up (rather than fail on) pre-existing plain files that collide with
    # files home-manager wants to manage, e.g. fish's own default config.fish.
    backupFileExtension = "backup";
    users.${user} = { pkgs, config, lib, ... }:{
      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix {};
        # Equivalent of appending `export PATH=...`/`fish_add_path` to the
        # respective rc files; home-manager renders this into both
        # ~/.zshrc (via programs.zsh.enable) and fish's conf.d.
        sessionPath = [ "$HOME/.local/bin" ];
        stateVersion = "26.05";
      };
      programs = {
        # Fish's generateCompletions (on by default) sets this to true via
        # mkDefault so `apropos`-based completions can be indexed. But since
        # stateVersion 26.05, programs.man.package defaults to null on
        # Darwin (nixpkgs' GNU man-db breaks apropos/whatis on macOS), which
        # makes generateCaches a no-op and prints a warning. Explicitly
        # disable it rather than installing the broken package.
        man.generateCaches = false;
      } // import ../shared/home-manager.nix { inherit config pkgs lib; };

      xdg.configFile = (import ../shared/files.nix { inherit config pkgs; }) // {
        # Ghostty defaults to the login shell ($SHELL), which stays zsh above.
        # Override just Ghostty's shell to fish without touching the system login shell.
        "ghostty/config".text = ''
          command = ${pkgs.fish}/bin/fish --login --interactive
          font-family = "JetBrainsMono Nerd Font"
        '';
      };

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = false;
    };
  };

}
