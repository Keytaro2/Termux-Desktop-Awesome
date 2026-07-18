import os
import sys
from time import sleep

# --- Color Settings ---
class Colors:
    PINK = '\033[95m'
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    RESET = '\033[0m'

def run(cmd):
    os.system(cmd)

def main():
    run("clear")
    print(f"{Colors.PINK}=== Termux-Desktop-Awesome Installer ==={Colors.RESET}")
    print(f"{Colors.BLUE}[+] Preparing the environment...... {Colors.RESET}")
    sleep(1)

    # 1. Installation of Dependencies
    apps = " audacious cava eww rofi awesome thunar picom neofetch feh starship kitty lsd w3m"
    print(f"{Colors.BLUE}[+] Installing necessary packages...{Colors.RESET}")
    run("pkg install x11-repo python python-pip git wget curl termux-x11-nightly pulseaudio firefox tur-repo zsh kitty termux-api virglrenderer-android fontconfig-utils freetype xfce4 jq lxappearance neovim-nightly rust chafa flameshot pygobject -y")
    run(f"pkg install {apps} -y")
    run("pip install pyxdg pywal")
    run("cargo install pokeget")

    # 2. Creating base directories
    run("mkdir -p ~/.config")
    run("mkdir -p ~/.local/share/")
    run("mkdir -p ~/.local/share/nvim")

    # 3. Deploy configurations (.config)
    config_items = [
        "audacious", "awesome", "cava", "eww", "flameshot", 
        "gtk-3.0", "neofetch", "picom", "rofi", "Thunar", 
        "Wallpaper", "xfce4", "starship.toml"
    ]
    for item in config_items:
        path = f"config/{item}"
        if os.path.exists(path):
            run(f"cp -r {path} ~/.config/")

    # 4. Move Executables to /usr/bin/
    executables = ["panes", "colortest", "sfetch"]
    BIN_PATH = "/data/data/com.termux/files/usr/bin"
    for exe in executables:
        exe_path = f"config/{exe}"
        if os.path.exists(exe_path):
            run(f"cp {exe_path} {BIN_PATH}/")
            run(f"chmod +x {BIN_PATH}/{exe}")

    # 5. Fonts and Appearance
    
    # Mover xfce4 directamente desde la carpeta fonts del repositorio
    if os.path.exists("fonts/xfce4"):
        run("mv fonts/xfce4 ~/.local/share/")

    # Copiar el resto de las fuentes (xfce4 ya no estará aquí)
    if os.path.isdir("fonts"):
        run("cp -r fonts ~/.local/share/")
        run("fc-cache -fv > /dev/null")

    dot_items = [".themes", ".icons", ".cache"]
    for item in dot_items:
        path = f"config/{item}"
        if os.path.exists(path):
            run(f"cp -r {path} ~/")

    if os.path.exists("config/nvim"):
        run("cp -r config/nvim ~/.local/share/")

    # 6. Source for Termux
    font_src = "config/CaskaydiaCoveNerdFont-BoldItalic.ttf"
    if os.path.exists(font_src):
        run("mkdir -p ~/.termux")
        run(f"cp {font_src} ~/.termux/font.ttf")
        run("termux-reload-settings")

    # 7. Shell Configurations (Cargo PATH and Starship)
    print(f"{Colors.BLUE}[+] Setting up Shell environment...{Colors.RESET}")
    
    cargo_export = 'export PATH=$PATH:$HOME/.cargo/bin'
    
    # List of configuration files to update
    shell_configs = [
        os.path.expanduser("~/.bashrc"),
        os.path.expanduser("~/.zshrc"),
        "/data/data/com.termux/files/usr/etc/bash.bashrc",
        "/data/data/com.termux/files/usr/etc/zshrc"
    ]
    
    for rc in shell_configs:
        if os.path.exists(rc):
            # Cargo setup
            run(f"grep -qxF '# CARGO' {rc} || echo '\n# CARGO\n{cargo_export}' >> {rc}")
            
            # Starship setup (checks if file name is bash or zsh to use correct init)
            if "bash" in rc:
                run(f"grep -qxF '# STARSHIP' {rc} || echo '\n# STARSHIP\neval \"$(starship init bash)\"' >> {rc}")
            elif "zsh" in rc:
                run(f"grep -qxF '# STARSHIP' {rc} || echo '\n# STARSHIP\neval \"$(starship init zsh)\"' >> {rc}")

    # Fish configuration (separate due to different syntax)
    fish_config = os.path.expanduser("~/.config/fish/config.fish")
    run("mkdir -p ~/.config/fish")
    fish_cargo = 'set -gx PATH $PATH $HOME/.cargo/bin'
    fish_starship = 'starship init fish | source'
    
    if os.path.exists(fish_config):
        run(f"grep -qxF '# CARGO' {fish_config} || echo '\n# CARGO\n{fish_cargo}' >> {fish_config}")
        run(f"grep -qxF '# STARSHIP' {fish_config} || echo '\n# STARSHIP\n{fish_starship}' >> {fish_config}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.PINK}[!] Installation cancelled {Colors.RESET}")
        sys.exit(0)
