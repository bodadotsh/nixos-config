{ pkgs, config, ... }:

{
  # Non-Nix, static configuration files managed by home-manager.
  # Add entries here as `"<path relative to $HOME>".text = ...;` or
  # `"<path>".source = ...;`.

  # AstroNvim config, checked into this repo like any other dotfile.
  # See modules/shared/config/nvim/ for the actual Lua files. The whole
  # directory is one read-only symlink into the nix store; lazy.nvim's
  # lockfile is redirected elsewhere in lua/lazy_setup.lua since it needs to
  # write to it (see comment there).
  "nvim".source = ./config/nvim;
}
