# Install some roles for zsh-galactica
cp -r roles/* ~/.config/zsh-galactica/roles

if [ -d ~/.config/zsh-galactica/roles ]; then
    echo "Roles installed successfully!"
else
    echo "Roles not installed!"
fi
