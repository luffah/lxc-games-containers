#!/bin/bash
# default use current dir name as system container name
CONTAINER_TEMPLATE_PATH="${CONTAINER_TEMPLATE_PATH:-$(dirname $0)}"
CONTAINER_NAME=${CONTAINER_NAME:-$(basename $CONTAINER_TEMPLATE_PATH)}
LXC_DIR="${LXC_DIR:-$HOME/.local/share/lxc}"

# PATH OF THE SYSTEM LXC CONTAINER
LXC_DIR_SYSTEM="$LXC_DIR/$CONTAINER_NAME"
# PATH OF THE GAME LXC CONTAINER
LXC_GAME_CONTAINER_NAME="${LXC_GAME_CONTAINER_NAME:-$CONTAINER_NAME}"
LXC_DIR_GAME="${LXC_DIR_GAME:-$HOME/$LXC_GAME_CONTAINER_NAME}"

case $1)
  user)
    echo "= Setup user and groups for unprivileged container ="

    sudo cp /etc/subuid /etc/subuid.bak
    sudo cp /etc/subgid /etc/subgid.bak
    echo "$USER:$UID:1\n$USER:100000:65536" | sudo tee -a /etc/subuid /etc/subgid > /dev/null
    echo "\n-USERS IDS-"
    sort /etc/subuid | uniq | sudo tee /etc/subuid
    echo "\n-GROUPS IDS-"
    sort /etc/subgid | uniq | sudo tee /etc/subgid


    if ! grep $USER /etc/lxc/lxc-usernet; then
      echo "$USER          veth         lxcbr0     1" | sudo tee -a /etc/lxc/lxc-usernet > /dev/null
    fi

    mkdir -p $HOME/.local/share/lxc
    mkdir -p $HOME/.config/lxc

    if [ ! -f "$HOME/.config/lxc/default.conf" ]; then
      cat <<EOF > $HOME/.config/lxc/default.conf
lxc.net.0.type = empty
lxc.apparmor.profile = generated
lxc.apparmor.allow_nesting = 1
lxc.idmap = u 0 100000 65536
lxc.idmap = g 0 100000 65536
EOF
    fi
    ;;
  system_container)
    echo "\nINSTALL ${CONTAINER_NAME} IN USER SPACE ? [type 'yes' to confirm]"
    read REP
    [ "$REP" = "yes" ] && lxc-create -n ${CONTAINER_NAME} -t download -- --dist ubuntu --realease bionic --arch i386
    ;;
  game_container)
    echo "\n= Setup LXC container config="
    cd $CONTAINER_TEMPLATE_PATH
    sed "s|LXC_DIR_CONTAINER|${LXC_DIR_CONTAINER}|g;s|LXC_DIR_GAME|${LXC_DIR_GAME}|g;s|USER_UID|${USER_UID}|g" config.template > $LXC_DIR_GAME/config
    sed "s|LXC_GAME_CONTAINER_NAME|${LXC_GAME_CONTAINER_NAME}|g;" start.sh > $LXC_DIR_GAME/start.sh
    cp pre-start.sh $LXC_DIR_GAME
    cp start.sh $LXC_DIR_GAME
    echo "You have to copy/install the game in $LXC_DIR_GAME/home/"
    ;;
esac
