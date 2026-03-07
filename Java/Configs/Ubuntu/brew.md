``` bash
 sudo apt install fish      # установка
which fish                                    # посмотри путь, обычно /usr/bin/fish
echo "/usr/bin/fish" | sudo tee -a /etc/shells
chsh -s /usr/bin/fish

curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher


# Умный автокомплит (z)
fisher install jethrokuan/z
```