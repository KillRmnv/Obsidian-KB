``` bash
#jq or go to github page and check for latest
mkdir -p ~/bin
wget https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-linux-amd64 -O ~/bin/jq
chmod +x ~/bin/jq
~/bin/jq --version
# Ожидаемый вывод: jq-1.8.1
# Проверьте, есть ли ~/bin уже в PATH
echo $PATH | grep -o "$HOME/bin"

# Если нет — добавьте в ~/.bashrc или ~/.zshrc
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

# Примените изменения
source ~/.bashrc
```