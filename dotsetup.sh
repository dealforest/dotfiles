#!/bin/sh

for file in .vimrc .vim .gvimrc .screenrc .inputrc .module-starter .gitignore .toprc .sqliterc .proverc .gdbinit .lldbinit .lldbinit-Xcode .gitconfig .railsrc .gemrc .tigrc .tmux.conf .pryrc .zsh.d .ackrc .Podfile .mongorc.js .zprofile .peco .xvimrc .lldb .commit_template .ripgreprc
do
    rm -v ~/$file
    ln -sv $PWD/$file ~/$file
done

for file in zshrc zshenv
do
    rm -v ~/.$file
    ln -sv $PWD/.zsh.d/$file ~/.$file
done

for dir in nvim
do
    rm -v ~/.config/$dir
    ln -sv $PWD/$dir ~/.config/$dir
done

rm -v ~/Library/Application\ Support/com.mitchellh.ghostty/config
ln -sv $PWD/ghostty/config $PWD/Library/Application\ Support/com.mitchellh.ghostty/config
