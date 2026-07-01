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

# Update a single input
nix flake update nixpkgs
nix flake update darwin
nix flake update home-manager
```

After updating, rebuild and switch:

```sh
nix run .#build-switch
```

Review `flake.lock` changes before committing if you track this repo in git.

## Rollback

List available system generations:

```sh
darwin-rebuild --list-generations
```

Roll back interactively (prompts for a generation number):

```sh
nix run .#rollback
```

Or switch to a specific generation directly:

```sh
sudo darwin-rebuild switch --flake .#aarch64-darwin --switch-generation <N>
```

## Cleanup

Remove system generations older than 7 days and collect unreachable store paths:

```sh
nix run .#clean
```

Additional manual cleanup:

```sh
# Remove all generations except the current one
sudo nix-collect-garbage -d

# See what would be deleted first
nix-store --gc --print-dead
```

Home Manager and nix-darwin keep their own generation history; `darwin-rebuild --list-generations` shows system-level generations.

## Flake apps

| App | Command | Description |
|-----|---------|-------------|
| `apply` | `nix run .#apply` | First-time personalization of user placeholders |
| `build` | `nix run .#build` | Build system without switching |
| `build-switch` | `nix run .#build-switch` | Build and activate a new generation |
| `rollback` | `nix run .#rollback` | Interactive rollback to a prior generation |
| `clean` | `nix run .#clean` | Garbage-collect generations older than 7 days |

## Layout

```
.
├── apps/aarch64-darwin/   # Shell scripts invoked by flake apps
├── flake.nix              # Inputs, outputs, and app definitions
├── flake.lock             # Pinned input revisions
├── hosts/darwin/          # Machine-specific nix-darwin configuration
├── modules/
│   ├── darwin/            # macOS-only modules (dock, casks, etc.)
│   └── shared/            # Config shared across platforms
└── overlays/              # nixpkgs overlays applied on every build
```

See also the READMEs in `modules/shared/`, `modules/darwin/`, and `overlays/` for module-level detail.

## Extras

There are few things are not managed through nix:

- GitHub Desktop
- cursor `agent` cli
