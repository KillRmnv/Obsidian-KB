```bash
#!/bin/bash

# Обновление системы
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget gpg software-properties-common apt-transport-https

# 1. GIT, C++, PIP, MAVEN, GRADLE
sudo apt install -y git build-essential python3-pip maven gradle
python3 -m venv myenv
source myenv/bin/activate
# zev
pip install zev

# 2. DOCKER
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
fi

# 3. PYTHON (использование deadsnakes для свежих версий)
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt update
sudo apt install -y python3.12 python3.12-venv

# 4. JDK
sudo apt install -y openjdk-25-jdk openjdk-25-source
sudo apt install openjdk-21-jdk

# JAVA_HOME без .bashrc
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# Проверить
$JAVA_HOME/bin/java -version  # Java 21
# 5. POSTGRES
sudo apt install -y postgresql postgresql-contrib
# 16. NODE.JS (LTS версия)
# Устанавливаем официальный скрипт настройки репозитория NodeSource
sudo curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs

# 17. PGADMIN 4 (Desktop версия)
# Добавляем публичный ключ репозитория
sudo curl -fsSL https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
# Добавляем сам репозиторий
sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
sudo apt update
# Устанавливаем версию для рабочего стола (desktop mode)
sudo apt install -y pgadmin4-desktop

# 6. NEOVIM & NEOVIDE
sudo add-apt-repository ppa:neovim-ppa/unstable -y
sudo apt update
sudo apt install -y neovim
# Neovide (через cargo, если есть, или скачивание бинарника)
wget https://github.com/neovide/neovide/releases/latest/download/neovide-linux-x86_64.tar.gz
tar -xvf neovide-linux-x86_64.tar.gz
sudo mv neovide /usr/local/bin/
rm neovide-linux-x86_64.tar.gz

# 7. ZED EDITOR
sudo curl -f https://zed.dev/install.sh | sh


# 9. OBSIDIAN (AppImage или Deb)
 wget https://github.com/obsidianmd/obsidian-releases/releases/download/v1.12.4/obsidian_1.12.4_amd64.deb
sudo apt install -y ./obsidian_1.12.4_amd64.deb
 rm obsidian_1.12.4_amd64.deb

# 10. WIRESHARK
sudo apt install -y wireshark
# Настройка прав для непривилегированного пользователя
sudo dpkg-reconfigure wireshark-common

# 11. TeXStudio
sudo add-apt-repository ppa:sunderme/texstudio -y
sudo apt update
sudo apt install -y texstudio



# 14. Hugging Face CLI & OpenCode
pip install -U "huggingface_hub[cli]"
# Для opencode обычно используется специфичный скрипт или pip, если это клиент

sudo curl -fsSL https://opencode.ai/install | bash

#qwen code
sudo curl -fsSL https://qwen-code-assets.oss-cn-hangzhou.aliyuncs.com/installation/install-qwen.sh | bash

#mistral vibe
sudo curl -LsSf https://mistral.ai/vibe/install.sh | bash

# OpenBLAS
sudo apt update
sudo apt install libopenblas-dev libopenblas0

#Rust Cargo
sudo apt update
sudo apt install -y build-essential curl pkg-config libssl-dev

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

source $HOME/.cargo/env

rustup update


#models
git clone https://github.com/arimxyer/models
cd models
cargo build --release
./target/release/models


#also install Lm Studio via Browser https://lmstudio.ai/

#btop https://github.com/aristocratos/btop
brew install btop
#tree
sudo apt install tree
#batcat
sudo apt install bat


#superfile
bash -c "$(curl -sLo- https://superfile.dev/install.sh)"

#ripgrep
 sudo apt-get install ripgrep

 #fd
 sudo apt install fd-find


#pass
 sudo apt-get install pass


#fzf
sudo apt install fzf
sudo apt install pipx

#tldr
pipx install tldr



#lazygit
brew install lazygit


#posting
# quickly install uv on MacOS/Linux
sudo curl -LsSf https://astral.sh/uv/install.sh | sh

# install Posting (will also quickly install Python 3.13 if needed)
uv tool install --python 3.13 posting


#oxker
cargo install oxker


sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates


mkdir -p ~/.local/share/fonts
cd /tmp
wget -O JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
unzip JetBrainsMono.zip -d ~/.local/share/fonts/
rm JetBrainsMono.zip
fc-cache -fv



# Добавляем в PATH (если ~/.local/bin нет в PATH)
if ! grep -q '.local/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi


curl -sS https://starship.rs/install.sh | sh

sudo apt update
sudo apt install -y libfuse2 libgtk-4-1 libadwaita-1-0 libvte-2.91-0


#warp https://www.warp.dev/download

#kaggle
pip install kaggle


sudo apt install gnome-shell-extension-manager


#chrome https://www.google.com/chrome/?spm=a2ty_o01.29997173.0.0.3b6f5171xSzZ54

sudo apt install flatpak

sudo apt install gnome-software-plugin-flatpak
fish_add_path -g ~/.npm-global/bin
exec fish
#cline
npm install -g cline
#kilocode
npm install -g @kilocode/cli

sudo apt install net-tools

# macOS / Linux git lfs
curl -LsSf https://astral.sh/uv/install.sh | sh
sudo apt install git-lfs
git lfs install


sudo apt update
sudo apt install -y mpv libmpv-dev meson ninja-build gcc git pkg-config libwayland-dev wayland-protocols libpipewire-0.3-dev libsystemd-dev


git clone --single-branch https://github.com/GhostNaN/mpvpaper
# Build
cd mpvpaper
meson setup build --prefix=/usr/local
ninja -C build
# Install
ninja -C build install

#zoxide
brew install zoxide
#CoolReader
sudo apt update && sudo apt install flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# flatpak install flathub io.gitlab.coolreader_ng.crqt-ng

brew install dust

sudo apt update && sudo apt install klavaro


mkdir app
cd app
git clone https://github.com/ggerganov/llama.cpp
cd llama.cpp

mkdir -p build && cd build
cmake .. -DLLAMA_AVX2=ON -DLLAMA_F16C=ON -DLLAMA_FMA=ON -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j12


```
