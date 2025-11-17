sudo zypper install zsh git
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

zed ~/.zshrc
sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc
source ~/.zshrc

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

sudo reboot
echo $SHELL
