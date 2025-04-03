
## Setting up a new dotfiles repo

    git init --bare $HOME/.dotfiles
    alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
    config config status.showUntrackedFiles no

where my ~/.dotfiles directory is a git bare repository.
Then any file within the home folder can be versioned with normal commands like:

    config status
    config add .vimrc
    config commit -m "Add vimrc"
    config add .config/redshift.conf
    config commit -m "Add redshift config"
    config push

## cloning on a new machine

    git clone --separate-git-dir=$HOME/.dotfiles git@github.com:HebelHuber/dotfiles.git $HOME/dotfiles-tmp
    git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME config status.showUntrackedFiles no
    git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME reset --hard    
    rm -r ~/dotfiles-tmp/
    . ~/.bashrc

To setup a new server with dockge, tailscale, cockpit and cloudflare tunnel,
run `sudo ~/tools/virgin-server-setup/setup-virgin-server.sh`
