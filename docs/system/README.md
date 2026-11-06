# System and maintenance

## install.sh

| Command | Does |
| --- | --- |
| `./install.sh` | Full install |
| `./install.sh dotfiles` | Copy configs from the repo to `~` |
| `./install.sh save` | Copy the live configs into `dotfiles/` (do this after changing anything) |
| `./install.sh nvim` | Plugins, parsers, LSPs |
| `./install.sh sddm` | Login screen theme (sudo) |
| `./install.sh boot` | GRUB theme and Plymouth splash |
| `./install.sh extras` | Firewall, zram, fallback kernel, battery limit |
| `./install.sh data` | SQL / Docker profile and the tools that make their output readable (lazydocker, dive, fx, csvlens…) |
| `./install.sh ssh-key '<pubkey>'` | Authorize a public key for remote login (no sudo) |
| `./install.sh ssh` | Key-only sshd (root and passwords off, `AllowUsers`, rate limit in nftables) (sudo); then forward the router port to this PC |
| `./install.sh tts` | Piper natural voices |
| `./install.sh gaming` | Steam, GameMode, MangoHud |
| `./install.sh claude` | Claude Code settings and status line |
| `./install.sh wipe --dry-run` | Preview the factory reset (destructive without the flag) |

Anything that needs sudo is run by you: `! ./install.sh <cmd>`.

## Updating

`update` (alias for `scripts/update.sh`): shows Arch news first, takes a
package + `/etc` snapshot and a Timeshift rollback point, updates repos and AUR,
then rebuilds what is needed. The bar shows pending updates.

## Backup

```sh
backup setup           # first time: authorize Google Drive, create the repo
backup run             # backup now (a daily timer also runs it)
backup status          # last backup and size
backup list            # versions
backup restore latest ~/restored
```

Keep the repository password (`~/.config/restic/password`) in KeePassXC; without
it nothing can be recovered.

## Testing a full install

`test/vm.sh` boots a QEMU/KVM Arch VM (ssh `localhost:2222`, user `tester`) to run
the installer safely.

## GPU

Everything long-running is wrapped in `scripts/igpu.sh` so only Hyprland holds
the NVIDIA device and the dGPU can sleep. Use `prime-run` for games that need it.

## Repo workflow

Live files are the source of truth: edit, test, `./install.sh save`, commit,
push.
