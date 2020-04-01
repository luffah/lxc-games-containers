#!/bin/bash
[ -z "${BASH}" ] && echo "This script shall be run with /bin/bash (not $_)" && exit
_lxc_template_path=$(realpath $(dirname $0))
_lxc_name=$(basename $_lxc_template_path)
_lxc_net_type=veth
_lxc_net_link=lxcbr0
_lxc_dist=ubuntu
_lxc_dist_release=bionic
_lxc_arch=i386
_lxc_version=$(lxc-create --version | cut -d. -f1)
_game_source=

INI_FILE=config.ini

# Setting Parameters
# OVERIDE VALUES WITH THE INI FILE (require bash)
while IFS='= ' read var val; do
    if [[ $var == \[*] ]]; then
      section=$var
    elif [[ $val ]]; then
      declare "_${section:1:-1}_$var=$val"
    fi
done < $INI_FILE
# ELSE USE DEFAULTS RULES
#    SUBUID = UID + 000
#    USER = current user
#    UID = id USER
if [ -z "$_lxc_user_id" ]; then 
  if [ -z "$_lxc_user_name" ]; then
    _lxc_user_name=$USER
    _lxc_user_id=$UID
    [ -z "$_lxc_user_home" ] && _lxc_user_home=$HOME
  else
    _lxc_user_id=$(grep ^${_lxc_user_name}: | cut -d: -f3)
  fi
elif [ -z "${_lxc_user_name}" ] ;then
    _lxc_user_name=$(grep x:${_lxc_user_id}: | cut -d: -f1)
fi
[ -z "$_lxc_user_home" ] && _lxc_user_home=/home/${_lxc_user_name}
[ -z "$_lxc_user_subid" ] && _lxc_user_subid="${_lxc_user_id}000"
[ -z "$_lxc_template_name" ] && _lxc_template_name=config.template.${_lxc_version}

echo "= Setup user and groups for unprivileged container ="
echo

sudo cp /etc/subuid /etc/subuid.bak
sudo cp /etc/subgid /etc/subgid.bak
echo -e "${_lxc_user_name}:${_lxc_user_id}:1\n$USER:${_lxc_user_subid}:65536" | sudo tee -a /etc/subuid /etc/subgid > /dev/null
echo "\n-USERS IDS-"
sort /etc/subuid | uniq | sudo tee /etc/subuid
echo "\n-GROUPS IDS-"
sort /etc/subgid | uniq | sudo tee /etc/subgid


if ! grep ${_lxc_user_name} /etc/lxc/lxc-usernet; then
  echo "${_lxc_user_name}          ${_lxc_net_type}         ${_lxc_net_link}     1" | sudo tee -a /etc/lxc/lxc-usernet > /dev/null
fi

mkdir -p ${_lxc_user_home}/.local/share/lxc
mkdir -p ${_lxc_user_home}/.config/lxc

if [ ! -f "${_lxc_user_home}/.config/lxc/default.conf" ]; then
cat <<EOF > ${_lxc_user_home}/.config/lxc/default.conf
lxc.net.0.type = empty
lxc.apparmor.profile = generated
lxc.apparmor.allow_nesting = 1
lxc.idmap = u 0 ${_lxc_user_subid} 65536
lxc.idmap = g 0 ${_lxc_user_subid} 65536
EOF
fi

echo "\nINSTALL ${_lxc_name} IN USER SPACE ? [type 'yes' to confirm]"
read REP

[ "$REP" = "yes" ] && lxc-create -n ${_lxc_name} -t download -- --dist ${_lxc_dist} --release ${_lxc_dist_release} --arch ${_lxc_arch}
LXC_DIR="${_lxc_user_home}/.local/share/lxc"
LXC_DIR_GAME="$LXC_DIR/${_lxc_name}"
LXC_DIR_CONTAINER="$HOME/${_lxc_name}"
echo "\n- Setup LXC container config="
cd ${_lxc_template_path}
sed "s|LXC_DIR_CONTAINER|${LXC_DIR_CONTAINER}|g;s|LXC_DIR_GAME|${LXC_DIR_GAME}|g" ${_lxc_template_name} > config
cp config $LXC_DIR_GAME
cp pre-start.sh $LXC_DIR_GAME

mkdir -p $LXC_DIR_GAME/home/
if [ -e "${_game_source}" ]; then
  cp ${game_source} $LXC_DIR_GAME/home/
else
  echo "You have to copy the game in $LXC_DIR_GAME/home/"
fi
