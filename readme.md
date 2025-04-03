
cloning on a new machine

    ssh-keygen -t rsa
    # add id_rsa.pub to github

    git clone --separate-git-dir=$HOME/.dotfiles git@github.com:HebelHuber/dotfiles.git $HOME/dotfiles-tmp
    alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
    config config status.showUntrackedFiles no
    config reset --hard    
    rm -r ~/dotfiles-tmp/
    . ~/.bashrc
    
Then any file within the home folder can be versioned with normal commands like:

    config status
    config add .vimrc
    config commit -m "Add vimrc"
    config add .config/redshift.conf
    config commit -m "Add redshift config"
    config push


To setup a new server with dockge, tailscale, cockpit and cloudflare tunnel, run
    
    sudo ~/tools/virgin-server-setup/setup-virgin-server.sh

## Setting up a new dotfiles repo

    git init --bare $HOME/.dotfiles
    alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
    config config status.showUntrackedFiles no
