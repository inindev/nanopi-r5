# nanopi-r5
#### *Stock Debian ARM64 Linux for the NanoPi R5C & R5S*

This stock Debian ARM64 Linux image is built directly from official packages using the official Debian [Debootstrap](https://wiki.debian.org/Debootstrap) utility, see: https://github.com/inindev/nanopi-r5/blob/main/debian/make_debian_img.sh#L112

Being an official unmodified Debian build, patches are directory available from the Debian repos using the stock **apt** package manager, see: https://github.com/inindev/nanopi-r5/blob/main/debian/make_debian_img.sh#L348

If you want to run true up-stream Debian Linux on your ARM64 device, this is the way to do it.

---
### debian bookworm setup

<br/>

**1. download image**
```
wget https://github.com/inindev/nanopi-r5/releases/download/v12-rc2/nanopi-r5_bookworm-rc2.img.xz
```

<br/>

**2. determine the location of the target micro sd card**

 * before plugging-in device
```
ls -l /dev/sd*
ls: cannot access '/dev/sd*': No such file or directory
```

 * after plugging-in device
```
ls -l /dev/sd*
brw-rw---- 1 root disk 8, 0 Mar 19 21:08 /dev/sda
```
* note: for mac, the device is ```/dev/rdiskX```

<br/>

**3. in the case above, substitute 'a' for 'X' in the command below (for /dev/sda)**
```
sudo sh -c 'xzcat nanopi-r5_bookworm-rc2.img.xz > /dev/sdX && sync'
```

#### when the micro sd has finished imaging, eject and use it to boot the nanopi r5c or r5s to finish setup

<br/>

**4. login account**
```
user: debian
pass: debian
```

<br/>

**5. take updates**
```
sudo apt update
sudo apt upgrade
```

<br/>

**6. create new admin account**
```
sudo adduser <youruserid>
echo '<youruserid> ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/<youruserid>
sudo chmod 440 /etc/sudoers.d/<youruserid>
```

<br/>

**7. lockout and/or delete debian account**
```
sudo passwd -l debian
sudo chsh -s /usr/sbin/nologin debian
```

```
sudo deluser --remove-home debian
sudo rm /etc/sudoers.d/debian
```

<br/>

**8. change hostname (optional)**
```
sudo nano /etc/hostname
sudo nano /etc/hosts
```

<br/>


---
### booting directly to m.2 ssd from emmc or micro sd bootstrap

<br/>

The nanopi r5c & r5s boards always need to boot from internal emmc or removable micro sd card.
The minimum required binary for the emmc or micro sd is u-boot which can then boot an internal m.2 ssd.

<br/>

**1. download u-boot images**
```
wget https://github.com/inindev/nanopi-r5/releases/download/v12-rc2/idbloader.img
wget https://github.com/inindev/nanopi-r5/releases/download/v12-rc2/u-boot.itb
```

<br/>

**2. determine the location of the target micro sd card**

 * before plugging-in device:
```
ls -l /dev/sd*
ls: cannot access '/dev/sd*': No such file or directory
```

 * after plugging-in device:
```
ls -l /dev/sd*
brw-rw---- 1 root disk 8, 0 Mar 19 21:08 /dev/sda
```
* note: for mac, the device is ```/dev/rdiskX```

<br/>

**3. in the case above, substitute 'a' for 'X' in the command below (for /dev/sda)**
```
cat /dev/zero | sudo tee /dev/sdX
sudo dd bs=4K seek=8 if=rksd_loader.img of=/dev/sdX conv=notrunc
sudo dd bs=4K seek=2048 if=u-boot.itb of=/dev/sdX conv=notrunc,fsync
```

#### when the micro sd has finished imaging, eject and use it to boot the nanopi r5c or r5s

<br/>


---
### building debian bookworm arm64 for the nanopi r5c / r5s from scratch

<br/>

The build script builds native arm64 binaries and thus needs to be run from an arm64 device such as a raspberry pi4 running 
a 64 bit arm linux. The initial build of this project used a debian arm64 odroid m1, but now uses a nanopi r5s running 
stock debian bookworm arm64.

<br/>

**1. clone the repo**
```
git clone https://github.com/inindev/nanopi-r5.git
cd nanopi-r5
```

<br/>

**2. run the debian build script**
```
cd debian
sudo sh make_debian_img.sh
```
* note: edit the build script to change various options: ```nano make_debian_img.sh```

<br/>

**3. the output if the build completes successfully**
```
mmc_2g.img.xz
```

<br/>

