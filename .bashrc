# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Enter Arch when login
if command -v distrobox > /dev/null 2>&1; then
    if [ -t 1 ] && [ -z "$DISTROBOX_ENTERD" ]; then
        distrobox enter arch-dev
    fi
fi

# Pacman
if command -v pacman > /dev/null 2>&1; then
    function pacin() {
        sudo pacman -S "$@"
	if [ $? -eq 0 ]; then
            echo "Updating pkglist.txt..."
	    pacman -Qqe > ~/dotfiles/pkglist.txt

	    echo "-----------------------------"
	    cd ~/dotfiles
	    git status
	    cd - > /dev/null
	fi
    }
fi
