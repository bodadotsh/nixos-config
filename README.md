# nixos-config

## Prerequisites

- Nix (install through Determinate Systems) with flakes enabled
- macOS on Apple Silicon (`aarch64-darwin`)

## Normal workflow

After editing configuration under `hosts/`, `modules/`, or `overlays/`:

1. **Build and switch** (most common):

   ```sh
   nix run .#build-switch
   ```

2. **Build only** (validate changes without activating):

   ```sh
   nix run .#build
   ```

   This compiles the system closure and removes the `./result` symlink when done. Nothing is activated.

## Update inputs

Flake inputs (`nixpkgs`, `darwin`, `home-manager`, Homebrew taps, etc.) are pinned in `flake.lock`. To refresh them:

```sh
# Update all inputs
nix flake update
```

After updating, rebuild and switch. Review `flake.lock` changes before committing if you track this repo in git.

## Rollback

List available system generations:

```sh
sudo darwin-rebuild --list-generations
```

Roll back interactively (prompts for a generation number):

```sh
nix run .#rollback
```

## Cleanup

Remove system generations older than 7 days and collect unreachable store paths:

```sh
nix run .#clean
```

Home Manager and nix-darwin keep their own generation history; `darwin-rebuild --list-generations` shows system-level
generations.

## Pragmatic Nix

Although declarative nix is great, there are few things that are not managed through nix:

- cursor `agent` cli
- GitHub Desktop
- mise global config (e.g., output of `mise use --global`)
- AstroNvim's plugins (see "Neovim (AstroNvim)" below)
- Enabling the 1Password SSH Agent (Settings > Developer > "Use the SSH Agent" in the 1Password app), required once per
  machine for SSH-based git commit signing (see [modules/shared/home-manager.nix](modules/shared/home-manager.nix))

## Neovim (AstroNvim)

[AstroNvim](https://docs.astronvim.com/) is installed as a set of dotfiles rather than a Nix package, since it's
fundamentally a Lua config that expects to manage its own plugins. Nix and AstroNvim's own tooling split
responsibilities:

- **Nix-managed:**
  - The config itself lives in [modules/shared/config/nvim/](modules/shared/config/nvim/) (a checked-in copy of the
    [AstroNvim template](https://github.com/AstroNvim/template)) and is symlinked to `~/.config/nvim` by home-manager
    via [modules/shared/files.nix](modules/shared/files.nix).
  - `neovim` plus AstroNvim's CLI dependencies (`ripgrep`, `lazygit`, `fd`, `git`) live in
    [modules/shared/packages.nix](modules/shared/packages.nix).
  - The Nerd Font (`font-jetbrains-mono-nerd-font`, used for file icons/statusline) is a Homebrew cask in
    [modules/darwin/casks.nix](modules/darwin/casks.nix), wired into Ghostty's `font-family` in
    [modules/darwin/home-manager.nix](modules/darwin/home-manager.nix).
- **Left to AstroNvim's own tooling (pragmatic, not nix-managed):**
  - `lazy.nvim` installs AstroNvim core and all plugins by cloning them from git on first launch, and `mason.nvim`
    installs LSPs/formatters/DAPs on demand (`:LspInstall`, `:MasonInstall`). Reimplementing this in Nix (e.g. via
    `lazy-nix-helper.nvim`) was considered and skipped as unnecessary overhead for this setup.
  - Because `~/.config/nvim` is a read-only symlink into the nix store, `lazy.nvim`'s lockfile is redirected to the
    (writable, non-nix-managed) state dir in `lua/lazy_setup.lua` (`vim.fn.stdpath("state") .. "/lazy-lock.json"`)
    instead of its usual home inside the config directory.

To pin plugin versions across machines (the non-Nix equivalent of `flake.lock`), copy the generated lockfile into the
repo and commit it:

```sh
cp ~/.local/state/nvim/lazy-lock.json modules/shared/config/nvim/lazy-lock.json
```

To change the config itself, edit files under `modules/shared/config/nvim/` (not the symlinked `~/.config/nvim` path
directly) and run `nix run .#build-switch`.
