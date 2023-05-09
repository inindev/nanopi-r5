# nanopi-r5
#### *Stock Debian ARM64 Linux for the NanoPi R5C & R5S*

This stock Debian ARM64 Linux image is built directly from official packages using the Debian [Debootstrap](https://wiki.debian.org/Debootstrap) utility, see: https://github.com/inindev/nanopi-r5/blob/main/debian/make_debian_img.sh#L119

Being an unmodified Debian build, patches are directory available from the Debian repos using the stock **apt** package manager, see: https://github.com/inindev/nanopi-r5/blob/main/debian/make_debian_img.sh#L358

If you want to run true up-stream Debian Linux on your ARM64 device, this is the way to do it.

---
### debian bookworm setup

<br/>

**1. download the appropriate image**
```
(R5C) wget https://github.com/inindev/nanopi-r5/releases/download/v12-rc4/nanopi-r5c_bookworm-rc4.img.xz
(R5S) wget https://github.com/inindev/nanopi-r5/releases/download/v12-rc4/nanopi-r5s_bookworm-rc4.img.xz
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
sudo sh -c 'xzcat nanopi-r5s_bookworm-rc4.img.xz > /dev/sdX && sync'
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
### booting from internal eMMC

<br/>

Imaging the internal eMMC device involves booting from a removable MMC card and imaging the internal eMMC device. When booted, the removable MMC device is seen as ```/dev/mmcblk0``` and the internal eMMC device is seen as ```/dev/mmcblk1```

<br/>

**1. boot from removable MMC**

Using the steps in the first section above, create a removable MMC card and boot using it. Note: If the internal eMMC device already has a bootable image on it, it will prefer to boot from that. To force the nanopi5 to boot from the removable MMC card you just made, hold the ```mask``` button down before applying power. Once successfully booted to the removable MMC, you will be able to see this by using the ```df``` command which will show /dev/mmcblk0p1 as the booted partition.

<br/>

**2. download the appropriate image to the booted MMC card and image the internal eMMC**
```
(R5C) wget https://github.com/inindev/nanopi-r5/releases/download/v12-rc4/nanopi-r5c_bookworm-rc4.img.xz
(R5S) wget https://github.com/inindev/nanopi-r5/releases/download/v12-rc4/nanopi-r5s_bookworm-rc4.img.xz
sudo su
xzcat nanopi-r5s_bookworm-rc4.img.xz > /dev/mmcblk1
```

<br/>

Once imaging completes, shutdown, remove the MMC card and it will then boot using the internal eMMC device.

Note: Once booted, ```sudo apt update``` then ```sudo apt upgrade``` to get the latest updates from the debian repositories.

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

