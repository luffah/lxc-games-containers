#!/bin/sh
echo "= Setup user and groups for unprivileged container ="

sudo cp /etc/subuid /etc/subuid.bak
sudo cp /etc/subgid /etc/subgid.bak
echo "$USER:1000:1\n$USER:100000:65536" | sudo tee -a /etc/subuid /etc/subgid > /dev/null
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

CONTAINER_TEMPLATE_PATH=$(dirname $0)
CONTAINER_NAME=$(basename $CONTAINER_TEMPLATE_PATH)
echo "\nINSTALL ${CONTAINER_NAME} IN USER SPACE ? [type 'yes' to confirm]"
read REP

[ "$REP" = "yes" ] && lxc-create -n ${CONTAINER_NAME} -t download -- --dist ubuntu --realease bionic --arch i386
LXC_DIR="$HOME/.local/share/lxc"
LXC_DIR_GAME="$LXC_DIR/$CONTAINER_NAME"
LXC_DIR_CONTAINER="$HOME/$CONTAINER_NAME"
echo "\n- Setup LXC container config="
cd $CONTAINER_TEMPLATE_PATH
sed "s|LXC_DIR_CONTAINER|${LXC_DIR_CONTAINER}|g;s|LXC_DIR_GAME|${LXC_DIR_GAME}|g" config.template > config
cp config $LXC_DIR_GAME
cp pre-start.sh $LXC_DIR_GAME

echo "You have to copy the game in $LXC_DIR_GAME/home/"
