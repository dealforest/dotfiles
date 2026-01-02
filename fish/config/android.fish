set -Ux JAVA_HOME ( /usr/libexec/java_home -v 17 )
fish_add_path $JAVA_HOME/bin

set -Ux ANDROID_HOME $HOME/Library/Android/sdk

# よく使うサブディレクトリを PATH へ
fish_add_path $ANDROID_HOME/emulator
fish_add_path $ANDROID_HOME/platform-tools
fish_add_path $ANDROID_HOME/cmdline-tools/latest/bin
