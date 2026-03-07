```bash 
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





# Импорт GPG-ключа и добавление репозитория [[3]]
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg

sudo apt update
sudo apt install -y wezterm


curl -sS https://starship.rs/install.sh | sh

```