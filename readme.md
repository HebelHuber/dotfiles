
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

    git clone --separate-git-dir=~/.dotfiles git@github.com:HebelHuber/dotfiles.git ~

For posterity, note that this will fail if your home directory isn't empty.
To get around that, clone the repo's working directory into a temporary directory first and then delete that directory,

    git clone --separate-git-dir=$HOME/.dotfiles git@github.com:HebelHuber/dotfiles.git $HOME/dotfiles-tmp
    config config status.showUntrackedFiles no
    rm -r ~/dotfiles-tmp/
    alias config='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
    config reset --hard

To setup a new server with dockge, tailscale, cockpit and cloudflare tunnel,
run `sudo ~/.dotfiles/virgin-server-setup/setup-virgin-server.sh`
