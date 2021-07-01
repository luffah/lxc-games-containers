```
MOST GAMES ON LINUX ARE BUILT FOR UBUNTU.
THIS REPOSITORY CONTAINS LXC CONFIGURATIONS 
THAT ALLOWS TO PLAY GAMES WITH A SIMPLE LXC CONTAINER.
```
Each game is associated to a directory with following structure.

# Install main container
```
GAMENAME/
   config
   pre-start.sh
   setup.sh
   start_game.sh
```
Where GAMEDIR is empty.


# Install games after first config
Use /path/to/container/$

lxc-execute -n gameu -- su ubuntu -l -c "Undertale/start.sh"

# Alternative to LXC
Using LXC is a way more clean, but i made a script that doesn't require LXC and all the config part. 
See https://github.com/luffah/u_chroot_start
```sh
# if the main container is in common_unprivileged and Undertale installed in adifferent home
chroot_start.sh ../common_unprivileged/ubuntu_bionic home:/home/ubuntu /home/ubuntu "Undertale/start.sh"
```
