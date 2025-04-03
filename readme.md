
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


## TODO

- Automate cf tunnel and hostname creation. It is unclear to me how i can enable Access Rules for the hostnames
    - https://www.mediarealm.com.au/articles/cloudflare-tunnel-setup-api/
    - https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-remote-tunnel-api/
    - This would query the user for cf API token instead of tunnel token
- Automate tailscale key creation, same as with cloudflare
    - use one-off keys for that
    - https://tailscale.com/api#tag/keys/POST/tailnet/{tailnet}/keys
    - https://tailscale.com/api#tag/devices/POST/device/{deviceId}/name
