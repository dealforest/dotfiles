#!/bin/sh


for file in .vimrc .vim .gvimrc .screenrc .inputrc .module-starter .gitignore .toprc .sqliterc .proverc .gdbinit .lldbinit .lldbinit-Xcode .gitconfig .railsrc .gemrc .tigrc .tmux .tmux.conf .pryrc .zsh.d .ackrc .Podfile .mongorc.js .zprofile
do
    rm -v ~/$file
    ln -sv $PWD/$file ~/$file
done

for file in zshrc zshenv
do
    rm -v ~/.$file
    ln -sv $PWD/.zsh.d/$file ~/.$file
done
