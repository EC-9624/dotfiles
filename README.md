# Dotfiles

Personal dotfiles managed with GNU Stow.

## Layout

- `home/`: files stowed into `$HOME`
- `packages/bundle`: Homebrew bundle for tools this config expects
- `dot`: helper for setup, Oh My Zsh bootstrap, restow, and basic checks
- `home/.zshenv`: minimal PATH and environment shared across zsh contexts

## Bootstrap

```bash
git clone <your-repo-url> ~/Code/dotfiles
cd ~/Code/dotfiles
./dot init
```

`./dot init` installs the Homebrew bundle, installs Bun, clones `~/.oh-my-zsh` when missing, and stows `home/` into `$HOME`.

## Commands

```bash
./dot init
./dot stow
./dot doctor
```
