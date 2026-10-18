#!/usr/bin/env python3
"""
Termux-Desktop-Awesome installer
--------------------------------
Run it from anywhere, after cloning the repository:

    git clone https://github.com/<your-user>/Termux-Desktop-Awesome
    cd Termux-Desktop-Awesome
    python install.py

Options:
    -y, --yes          answer "yes" to every question (non-interactive)
    --pokeget          install pokeget without asking
    --no-pokeget       skip pokeget without asking
    --no-packages      do not run pkg/pip (only copy the configuration)
    --force            run even if this does not look like Termux

Expected repository layout (everything is optional, missing items are skipped):

    install.py
    config/      awesome/  picom/  rofi/  cava/  audacious/  ...   (-> ~/.config)
                 awesome/layouts/                                   (-> awesome default theme)
                 awesome/scripts/  awesome/assets/  awesome/*.lua   (the Lua desktop)
                 panes  colortest  sfetch                           (-> $PREFIX/bin)
                 .themes  .icons  .cache  nvim
                 CaskaydiaCoveNerdFont-BoldItalic.ttf               (-> ~/.termux/font.ttf)
    fonts/       *.ttf  xfce4/  Bibata-Material-Cloud-Light/
"""

import argparse
import os
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from time import sleep

# --- Paths -------------------------------------------------------------------
REPO = Path(__file__).resolve().parent            # the cloned repository
HOME = Path.home()
PREFIX = Path(os.environ.get("PREFIX", "/data/data/com.termux/files/usr"))
BIN_PATH = PREFIX / "bin"
CONFIG = HOME / ".config"


# --- Color Settings ----------------------------------------------------------
class Colors:
    PINK = "\033[95m"
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    RED = "\033[91m"
    RESET = "\033[0m"


def info(msg):
    print(f"{Colors.BLUE}[+] {msg}{Colors.RESET}")


def warn(msg):
    print(f"{Colors.YELLOW}[!] {msg}{Colors.RESET}")


def fail(msg):
    print(f"{Colors.RED}[x] {msg}{Colors.RESET}")


# --- Helpers -----------------------------------------------------------------
def run(cmd):
    """Run a shell command. Returns True when it succeeded."""
    return subprocess.run(cmd, shell=True).returncode == 0


def ask_yes_no(question, assume_yes=False):
    if assume_yes:
        return True
    while True:
        answer = input(f"{Colors.YELLOW}{question} (yes/no): {Colors.RESET}").strip().lower()
        if answer in ("yes", "y"):
            return True
        if answer in ("no", "n"):
            return False
        print("Please answer 'yes' or 'no'.")


def src(*parts):
    return REPO.joinpath(*parts)


def copy_into(source: Path, dest_dir: Path, ignore=None):
    """Copy a file or a folder INTO dest_dir (keeping its name). Never touches the repo."""
    dest_dir.mkdir(parents=True, exist_ok=True)
    target = dest_dir / source.name
    try:
        if source.is_dir():
            copy_tree(source, target, ignore)
        else:
            shutil.copy2(source, target)
    except (OSError, shutil.Error) as e:
        warn(f"Some files of {source.name} could not be copied (continuing): {str(e)[:120]}")
    return target


def copy_tree(source: Path, target: Path, ignore=None):
    """copytree that KEEPS symlinks as symlinks (icon themes have broken/dangling ones, which
    made a plain copytree abort) and never stops because of a single bad file."""
    try:
        shutil.copytree(source, target, symlinks=True, dirs_exist_ok=True,
                        ignore=ignore, ignore_dangling_symlinks=True)
    except shutil.Error as e:
        # copytree reports every failed file at the end; the rest was copied already
        warn(f"{len(e.args[0])} file(s) of {source.name} were skipped (broken links).")


def append_once(path: Path, marker: str, block: str):
    """Append `block` to a text file unless `marker` is already in it (idempotent)."""
    try:
        text = path.read_text() if path.exists() else ""
        if marker in text.splitlines():
            return
        with path.open("a") as f:
            if text and not text.endswith("\n"):
                f.write("\n")
            f.write(f"\n{marker}\n{block}\n")
    except OSError as e:
        warn(f"Could not update {path}: {e}")


def backup_existing(path: Path):
    if path.exists() or path.is_symlink():
        stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = path.with_name(f"{path.name}.bak-{stamp}")
        path.rename(backup)
        warn(f"Existing {path} moved to {backup}")


def looks_like_termux():
    return Path("/data/data/com.termux").exists() or "com.termux" in str(PREFIX)


# --- Steps -------------------------------------------------------------------
def install_packages(install_pokeget):
    # NOTE: eww is gone: bar, dashboard, menus, notifications and powermenu are Lua now.
    base = (
        "x11-repo tur-repo python python-pip git wget curl termux-x11-nightly pulseaudio "
        "firefox zsh kitty termux-api virglrenderer-android fontconfig-utils freetype xfce4 "
        "jq lxappearance neovim-nightly rust chafa flameshot pygobject xorg-xsetroot xorg-xrdb"
    )
    apps = (
        "audacious cava awesome rofi thunar picom neofetch feh starship lsd w3m"
    )
    info("Installing necessary packages...")
    if not run(f"pkg install -y {base}"):
        warn("Some base packages failed to install (continuing).")
    if not run(f"pkg install -y {apps}"):
        warn("Some desktop packages failed to install (continuing).")
    if not run("pip install pyxdg pywal"):
        warn("pip could not install pyxdg/pywal (continuing).")

    if install_pokeget:
        info("Installing pokeget...")
        run("cargo install pokeget")
    else:
        info("Skipping pokeget.")


def deploy_config():
    config_src = src("config")
    if not config_src.is_dir():
        warn("No 'config' folder next to install.py: nothing to copy.")
        return

    CONFIG.mkdir(parents=True, exist_ok=True)
    (HOME / ".local/share/nvim").mkdir(parents=True, exist_ok=True)

    # Never overwrite the user's awesome setup silently
    if src("config", "awesome").is_dir():
        old_rc, new_rc = CONFIG / "awesome/rc.lua", src("config", "awesome", "rc.lua")
        same = old_rc.is_file() and new_rc.is_file() and old_rc.read_bytes() == new_rc.read_bytes()
        if not same:
            backup_existing(CONFIG / "awesome")

    config_items = [
        "audacious", "awesome", "cava", "flameshot", "gtk-3.0", "neofetch",
        "picom", "rofi", "Thunar", "Wallpaper", "xfce4", "starship.toml",
        "folder_icon.sh",
    ]
    for item in config_items:
        path = src("config", item)
        if path.exists():
            copy_into(path, CONFIG)

    folder_icon = CONFIG / "folder_icon.sh"
    if folder_icon.exists():
        folder_icon.chmod(0o755)

    # Scripts used by the Lua widgets (poweroff.sh, buttons.sh, cover.sh, ...)
    scripts = CONFIG / "awesome" / "scripts"
    if scripts.is_dir():
        for sh_file in scripts.glob("*.sh"):
            sh_file.chmod(0o755)

    # config/awesome/layouts  ->  $PREFIX/share/awesome/themes/default/layouts
    layouts_src = src("config", "awesome", "layouts")
    if layouts_src.is_dir():
        theme_dir = PREFIX / "share/awesome/themes/default"
        if not theme_dir.is_dir():
            warn(f"{theme_dir} does not exist yet (is the 'awesome' package installed?). Creating it.")
        copy_into(layouts_src, theme_dir)
        info(f"Layouts copied to {theme_dir / 'layouts'}")

    # Executables -> $PREFIX/bin
    for exe in ("panes", "colortest", "sfetch"):
        exe_path = src("config", exe)
        if exe_path.exists():
            BIN_PATH.mkdir(parents=True, exist_ok=True)
            shutil.copy2(exe_path, BIN_PATH / exe)
            (BIN_PATH / exe).chmod(0o755)

    # Dot folders that live directly in $HOME
    for item in (".themes", ".icons", ".cache"):
        path = src("config", item)
        if path.exists():
            copy_into(path, HOME)

    if src("config", "nvim").is_dir():
        copy_into(src("config", "nvim"), HOME / ".local/share")


def ensure_rubato():
    """lib/rubato is a git SUBMODULE upstream: a plain `git clone` of the repo leaves it EMPTY and
    the animations silently do nothing. If timed.lua is missing, fetch rubato here."""
    dest = CONFIG / "awesome/lib/rubato"
    if (dest / "timed.lua").is_file() or not (CONFIG / "awesome").is_dir():
        return
    info("lib/rubato is empty (git submodule). Downloading rubato...")
    if dest.is_dir() and not any(dest.iterdir()):
        dest.rmdir()
    if dest.exists():
        warn(f"{dest} is not empty but has no timed.lua; skipping download.")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    if run(f"git clone --depth 1 https://github.com/andOrlando/rubato {dest}"):
        shutil.rmtree(dest / ".git", ignore_errors=True)    # plain files, not a nested repo
    else:
        warn("Could not download rubato (no internet / git?). Animations will use the built-in "
             "engine. Later: git clone --depth 1 https://github.com/andOrlando/rubato " + str(dest))


def patch_rubato():
    """rubato needs an integer for the timer interval on Lua 5.3+/5.4 (Termux):
    initial_dt * 1000  ->  math.floor(initial_dt * 1000)   (same as the manual sed, idempotent)."""
    timed = CONFIG / "awesome/lib/rubato/timed.lua"
    if not timed.is_file():
        return
    text = timed.read_text()
    if "initial_dt * 1000" in text and "math.floor(initial_dt * 1000)" not in text:
        timed.write_text(text.replace("initial_dt * 1000", "math.floor(initial_dt * 1000)"))
        info("Patched lib/rubato/timed.lua (integer timer interval).")


def migrate_legacy_eww():
    """If an old ~/.config/eww exists, bring its scripts/assets to the Lua setup.
    Nothing is overwritten and nothing is deleted."""
    legacy = CONFIG / "eww"
    awesome = CONFIG / "awesome"
    if not legacy.is_dir() or not awesome.is_dir():
        return
    info("Old ~/.config/eww found: copying its scripts and assets to ~/.config/awesome ...")
    for sub in ("scripts", "assets"):
        origin = legacy / sub
        if not origin.is_dir():
            continue
        dest = awesome / sub
        dest.mkdir(parents=True, exist_ok=True)
        for item in origin.iterdir():
            if item.name == "logger.sh" and sub == "scripts":
                continue                      # keep the new logger.sh
            target = dest / item.name
            if target.exists():
                continue                      # like `cp -rn`
            if item.is_dir():
                copy_tree(item, target)
            else:
                shutil.copy2(item, target)
    for sh_file in (awesome / "scripts").glob("*.sh"):
        sh_file.chmod(0o755)


def install_fonts_and_cursor():
    fonts = src("fonts")
    if fonts.is_dir():
        # xfce4 settings -> ~/.local/share/xfce4
        if (fonts / "xfce4").is_dir():
            copy_into(fonts / "xfce4", HOME / ".local/share")

        # Cursor theme: Termux icons path + ~/.icons (awesome's rc.lua also looks there)
        cursor = fonts / "Bibata-Material-Cloud-Light"
        if cursor.is_dir():
            copy_into(cursor, PREFIX / "share/icons")
            copy_into(cursor, HOME / ".icons")

        # Remaining fonts -> ~/.local/share/fonts   (xfce4 and cursor are not fonts)
        skip = shutil.ignore_patterns("xfce4", "Bibata-Material-Cloud-Light")
        copy_tree(fonts, HOME / ".local/share/fonts", skip)
        run("fc-cache -fv > /dev/null")

    # Termux terminal font
    font_src = src("config", "CaskaydiaCoveNerdFont-BoldItalic.ttf")
    if font_src.exists():
        (HOME / ".termux").mkdir(parents=True, exist_ok=True)
        shutil.copy2(font_src, HOME / ".termux/font.ttf")
        # NO se llama termux-reload-settings aquí: relanza la actividad de Termux y en algunos
        # equipos (Android 12) la app se cierra con "Wrong state class ... View State", matando
        # el instalador a medias. Se hace al final y solo si se pide con --reload.


def setup_shells():
    info("Setting up Shell environment...")
    cargo_export = "export PATH=$PATH:$HOME/.cargo/bin"

    shell_configs = [
        HOME / ".bashrc",
        HOME / ".zshrc",
        PREFIX / "etc/bash.bashrc",
        PREFIX / "etc/zshrc",
    ]
    for rc in shell_configs:
        if not rc.exists():
            continue
        append_once(rc, "# CARGO", cargo_export)
        if "bash" in rc.name:
            append_once(rc, "# STARSHIP", 'eval "$(starship init bash)"')
        elif "zsh" in rc.name:
            append_once(rc, "# STARSHIP", 'eval "$(starship init zsh)"')

    # Fish (different syntax)
    fish_dir = CONFIG / "fish"
    fish_dir.mkdir(parents=True, exist_ok=True)
    fish_config = fish_dir / "config.fish"
    if fish_config.exists():
        append_once(fish_config, "# CARGO", "set -gx PATH $PATH $HOME/.cargo/bin")
        append_once(fish_config, "# STARSHIP", "starship init fish | source")


# --- Main --------------------------------------------------------------------
def parse_args():
    p = argparse.ArgumentParser(description="Termux-Desktop-Awesome installer")
    p.add_argument("-y", "--yes", action="store_true", help="answer yes to every question")
    g = p.add_mutually_exclusive_group()
    g.add_argument("--pokeget", action="store_true", help="install pokeget without asking")
    g.add_argument("--no-pokeget", action="store_true", help="skip pokeget without asking")
    p.add_argument("--no-packages", action="store_true", help="skip pkg/pip, only copy configs")
    p.add_argument("--reload", action="store_true",
                   help="run termux-reload-settings at the very end (can close Termux on some phones)")
    p.add_argument("--force", action="store_true", help="run even if this is not Termux")
    return p.parse_args()


def main():
    args = parse_args()
    os.chdir(REPO)       # works no matter where the script is launched from

    run("clear")
    print(f"{Colors.PINK}=== Termux-Desktop-Awesome Installer ==={Colors.RESET}")

    if not looks_like_termux() and not args.force:
        fail("This installer is meant for Termux. Use --force to run it anyway.")
        sys.exit(1)

    install_pokeget = False
    if not args.no_packages:
        if args.pokeget:
            install_pokeget = True
        elif args.no_pokeget:
            install_pokeget = False
        else:
            print(f"{Colors.YELLOW}[!] Warning: 'pokeget' compiles with cargo and is a HEAVY package.")
            print(f"    It may take a long time and consume a lot of storage and battery.{Colors.RESET}")
            install_pokeget = ask_yes_no("Do you want to install pokeget?", args.yes)

    info("Preparing the environment......")
    sleep(1)

    if not args.no_packages:
        install_packages(install_pokeget)

    deploy_config()
    migrate_legacy_eww()
    ensure_rubato()
    patch_rubato()
    install_fonts_and_cursor()
    setup_shells()

    print(f"{Colors.GREEN}[✓] Installation finished!{Colors.RESET}")
    if args.reload:
        run("termux-reload-settings")
    else:
        warn("To apply the new Termux font/colors: close Termux completely (swipe it away) and "
             "open it again. (termux-reload-settings was NOT run on purpose; use --reload to run it.)")
    print(f"{Colors.BLUE}    Start the desktop with:{Colors.RESET}")
    print("      termux-x11 :0 &   then   DISPLAY=:0 awesome")
    print(f"{Colors.BLUE}    If awesome restarts once on the first launch, that is the cursor theme "
          f"being applied (see ~/.cache/awesome-cursor.log).{Colors.RESET}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.PINK}[!] Installation cancelled {Colors.RESET}")
        sys.exit(0)
