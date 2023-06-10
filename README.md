# nanopi-r5
#### *Stock Debian ARM64 Linux for the NanoPi R5C & R5S*

This stock Debian ARM64 Linux image is built directly from official packages using the Debian [Debootstrap](https://wiki.debian.org/Debootstrap) utility, see: https://github.com/inindev/nanopi-r5/blob/main/debian/make_debian_img.sh#L113

Being an unmodified Debian build, patches are directory available from the Debian repos using the stock **apt** package manager, see: https://github.com/inindev/nanopi-r5/blob/main/debian/make_debian_img.sh#L343

If you want to run true up-stream Debian Linux on your ARM64 device, this is the way to do it.

---
### debian bookworm setup

<br/>

**1. download the appropriate image**
```
(R5C) wget https://github.com/inindev/nanopi-r5/releases/download/v12.0/nanopi-r5c_bookworm.img.xz
(R5S) wget https://github.com/inindev/nanopi-r5/releases/download/v12.0/nanopi-r5s_bookworm.img.xz
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
sudo sh -c 'xzcat nanopi-r5s_bookworm.img.xz > /dev/sdX && sync'
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
(R5C) wget https://github.com/inindev/nanopi-r5/releases/download/v12.0/nanopi-r5c_bookworm.img.xz
(R5S) wget https://github.com/inindev/nanopi-r5/releases/download/v12.0/nanopi-r5s_bookworm.img.xz
sudo su
xzcat nanopi-r5s_bookworm.img.xz > /dev/mmcblk1
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

---
### booting from m.2 NVMe

<br/>

_Note 1: The case for the Nanopi R5S is small and limited on its ability to dissipate heat. I have tested two different Samsung NVMe M.2 devices: [Samsung 970 EVO Plus](https://www.amazon.com/gp/product/B07M7Q21N7), and the [Samsung 980](https://www.amazon.com/gp/product/B08V7GT6F3). Both function equally well in my testing. The Samsung 970 EVO Plus runs very hot (you do not like keeping your finger on it hot), while the Samsung 980 runs considerably cooler. I also found that a [1.5mm m.2 thermal pad](https://www.amazon.com/gp/product/B09DC772PR) fits well to help conduct heat from the NVMe device to the case. Finally, note that the Nanopi R5S supports a single channel [PCIe2.1 x1 device](https://wiki.friendlyelec.com/wiki/index.php/NanoPi_R5S), so neither of the two options above will reach anywhere near their performance potential._

_Note 2: Ideally u-boot would be configured to recognize the NVMe device and boot directly from it. The boot process would read u-boot from the internal eMMC device then load linux from NVMe. I spent considerable time attempting to get the device tree configuration to initialize the NVMe but have yet to be successful. Since Linux had no problems recognizing the device, I chose to put both u-boot and the contents of the boot directory on the internal eMMC device and let the linux bootstrap into NVMe. This is a very similar result and the eMMC is only used for bootstrapping which resolves any wear-leveling concerns to my satisfaction._

<br/>

**1. boot from mmc**

Hold down the ```mask``` button while powering on. After 5 seconds the mask button can be released and the device will run initial setup then reboot (this will only happen one time). Note that without a [serial terminal](https://www.amazon.com/dp/B09W2B61HW) it will be difficult to know when the reboot has completed. Waiting two minutes then powering down and booting again with the ```mask``` button again should be sufficient to reach the second boot.

The device is now booted.

<br/>

**2. connect with ssh**

Find the device ip address on the network and ssh in as ```debian``` and use a password of ```debian```. Reset the password when prompted.

At this point the following mmc devices will be present in the system (assuming the factory partitioning of the ```mmcblk1``` device):
```
$ ls -al /dev/mmcblk*
brw-rw---- 1 root disk 179, 768 May 31 23:56 /dev/mmcblk0
brw-rw---- 1 root disk 179, 769 May 31 23:56 /dev/mmcblk0p1
brw-rw---- 1 root disk 179,   0 May 31 23:56 /dev/mmcblk1
brw-rw---- 1 root disk 179, 256 May 31 23:56 /dev/mmcblk1boot0
brw-rw---- 1 root disk 179, 512 May 31 23:56 /dev/mmcblk1boot1
brw-rw---- 1 root disk 179,   1 May 31 23:56 /dev/mmcblk1p1
brw-rw---- 1 root disk 179,   2 May 31 23:56 /dev/mmcblk1p2
brw-rw---- 1 root disk 179,   3 May 31 23:56 /dev/mmcblk1p3
brw-rw---- 1 root disk 179,   4 May 31 23:56 /dev/mmcblk1p4
brw-rw---- 1 root disk 179,   5 May 31 23:56 /dev/mmcblk1p5
brw-rw---- 1 root disk 179,   6 May 31 23:56 /dev/mmcblk1p6
brw-rw---- 1 root disk 179,   7 May 31 23:56 /dev/mmcblk1p7
brw-rw---- 1 root disk 179,   8 May 31 23:56 /dev/mmcblk1p8
brw-rw---- 1 root disk 179,   9 May 31 23:56 /dev/mmcblk1p9
crw------- 1 root root 241,   0 May 31 23:56 /dev/mmcblk1rpmb
```

Using the ```df``` command, note that the system is currently booted from the external mmc device which is known as ```/dev/mmcblk0```
```
$ df
Filesystem     1K-blocks    Used Available Use% Mounted on
udev             1863508       0   1863508   0% /dev
tmpfs             382772     856    381916   1% /run
/dev/mmcblk0p1  60773088 1389860  56875528   3% /
tmpfs            1913860       0   1913860   0% /dev/shm
tmpfs               5120       0      5120   0% /run/lock
```
Note that the internal emmc device is ```/dev/mmcblk1```

If the m.2 nvme device (such as the samsung 980) is installed, it will also be visible:
```
$ ls -al /dev/nvme0n1*
brw-rw---- 1 root disk 259, 0 May 31 23:56 /dev/nvme0n1
brw-rw---- 1 root disk 259, 1 May 31 23:56 /dev/nvme0n1p1
```

<br/>

> The next steps are to copy the image to nvme, then move the files in the ```boot``` directory to the internal eMMC.

<br/>

**3. download the image**

Download to a temporary location on the booted mmc:
```
wget https://github.com/inindev/nanopi-r5/releases/download/v12.0/nanopi-r5s_bookworm.img.xz
```

<br/>

**4. image the nvme device** (as root, ```sudo su```)
```
xzcat nanopi-r5s_bookworm.img.xz > /dev/nvme0n1
```

<br/>

**5. partition the internal eMMC device** (as root, ```sudo su```)
```
cat << EOF | sfdisk /dev/mmcblk1
label: gpt
unit: sectors
first-lba: 2048
part1: start=32768, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, name=boot
EOF
```

When successful, the following output will be produced:
```
Checking that no-one is using this disk right now ... OK

Disk /dev/mmcblk1: 14.56 GiB, 15634268160 bytes, 30535680 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: 3ADEA03D-C612-46ED-CFF9-B79439F11561

Old situation:

Device           Start      End  Sectors  Size Type
/dev/mmcblk1p1   16384    24575     8192    4M unknown
/dev/mmcblk1p2   24576    32767     8192    4M unknown
/dev/mmcblk1p3   32768    40959     8192    4M unknown
/dev/mmcblk1p4   40960    73727    32768   16M unknown
/dev/mmcblk1p5   73728   155647    81920   40M unknown
/dev/mmcblk1p6  155648   221183    65536   32M unknown
/dev/mmcblk1p7  221184   286719    65536   32M unknown
/dev/mmcblk1p8  286720  1081343   794624  388M unknown
/dev/mmcblk1p9 1081344 30535646 29454303   14G unknown

>>> Script header accepted.
>>> Script header accepted.
>>> Script header accepted.
>>> Created a new GPT disklabel (GUID: 1B31A28B-53D5-C14D-9CE8-F3163BF58084).
/dev/mmcblk1p1: Created a new partition 1 of type 'Linux filesystem' and of size 14.5 GiB.
/dev/mmcblk1p2: Done.

New situation:
Disklabel type: gpt
Disk identifier: 1B31A28B-53D5-C14D-9CE8-F3163BF58084

Device         Start      End  Sectors  Size Type
/dev/mmcblk1p1 32768 30533631 30500864 14.5G Linux filesystem

The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```

<br/>

**6. format the new partition as ext4** (as root)
```
mkfs.ext4 /dev/mmcblk1p1
```

<br/>

**7. download and copy the u-boot bootloader to the internal eMMC**
```
wget https://github.com/inindev/nanopi-r5/releases/download/v12.0/idbloader-r5s.img
wget https://github.com/inindev/nanopi-r5/releases/download/v12.0/u-boot-r5s.itb
sudo dd bs=4K seek=8 if=idbloader-r5s.img of=/dev/mmcblk1
sudo dd bs=4K seek=2048 if=u-boot-r5s.itb of=/dev/mmcblk1
```

<br/>

> The remaining steps are to move the boot files from the nvme device to the internal eMMC and edit the boot script for this new layout.

<br/>

**8. create mount points and mount devices** (as root)
```
mkdir emmc
mount /dev/mmcblk1p1 emmc

mkdir nvme
mount /dev/nvme0n1p1 nvme
```

At this point both volumes are mounted and visible:
```
# ls -al emmc/
total 16
drwx------ 2 root root 16384 Jun  1 10:17 lost+found

# ls -al nvme/
total 76
lrwxrwxrwx  1 root root     7 May 31 23:03 bin -> usr/bin
drwxr-xr-x  2 root root  4096 May 31 23:09 boot
drwxr-xr-x  4 root root  4096 May 31 23:04 dev
drwxr-xr-x 55 root root  4096 May 31 23:10 etc
drwxr-xr-x  3 root root  4096 May 31 23:10 home
lrwxrwxrwx  1 root root     7 May 31 23:03 lib -> usr/lib
drwx------  2 root root 16384 May 31 23:01 lost+found
drwxr-xr-x  2 root root  4096 May 31 23:04 media
drwxr-xr-x  2 root root  4096 May 31 23:04 mnt
drwxr-xr-x  2 root root  4096 May 31 23:04 opt
drwxr-xr-x  2 root root  4096 Mar  2 13:55 proc
drwx------  3 root root  4096 May 31 23:09 root
drwxr-xr-x 11 root root  4096 May 31 23:09 run
lrwxrwxrwx  1 root root     8 May 31 23:03 sbin -> usr/sbin
drwxr-xr-x  2 root root  4096 May 31 23:04 srv
drwxr-xr-x  2 root root  4096 Mar  2 13:55 sys
drwxrwxrwt  2 root root  4096 May 31 23:10 tmp
drwxr-xr-x 11 root root  4096 May 31 23:04 usr
drwxr-xr-x 11 root root  4096 May 31 23:04 var
```

<br/>

**9. move the boot files from nvme to emmc**
```
# mv nvme/boot/* emmc/
```

The volumes should now look like:
```
# ls -al nvme/boot/
total 0

# ls -al emmc/
total 60800
-rw-r--r-- 1 root root       83 May  8 20:16 System.map-6.1.0-9-arm64
-rw-r--r-- 1 root root      769 May 31 23:09 boot.scr
-rw-r--r-- 1 root root      697 May 31 23:09 boot.txt
-rw-r--r-- 1 root root   291075 May  8 20:16 config-6.1.0-9-arm64
lrwxrwxrwx 1 root root       21 May 31 23:09 dtb -> rk3568-nanopi-r5s.dtb
lrwxrwxrwx 1 root root       24 May 31 23:08 initrd.img -> initrd.img-6.1.0-9-arm64
-rw-r--r-- 1 root root 29459178 May 31 23:09 initrd.img-6.1.0-9-arm64
lrwxrwxrwx 1 root root       24 May 31 23:08 initrd.img.old -> initrd.img-6.1.0-9-arm64
drwx------ 2 root root    16384 Jun  1 10:17 lost+found
-rwxr-xr-- 1 root root      255 May 31 23:09 mkscr.sh
-rw-r--r-- 1 root root   117417 May 31 23:09 rk3568-nanopi-r5s.dtb
lrwxrwxrwx 1 root root       21 May 31 23:08 vmlinuz -> vmlinuz-6.1.0-9-arm64
-rw-r--r-- 1 root root 32350144 May  8 20:16 vmlinuz-6.1.0-9-arm64
lrwxrwxrwx 1 root root       21 May 31 23:08 vmlinuz.old -> vmlinuz-6.1.0-9-arm64
```

<br/>

**10. change the boot script configuration**
```
# cat emmc/boot.txt
# after modifying, run ./mkscr.sh

part uuid ${devtype} ${devnum}:${distro_bootpart} uuid
setenv bootargs console=ttyS2,1500000 root=PARTUUID=${uuid} rw rootwait ipv6.disable=1 earlycon=uart8250,mmio32,0xfe660000

if load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /boot/vmlinuz; then
    if load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /boot/dtb; then
        fdt addr ${fdt_addr_r}
        fdt resize
        if load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} /boot/initrd.img; then
            booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r};
        else
            booti ${kernel_addr_r} - ${fdt_addr_r};
        fi;
    fi;
fi
```

<br/>

- [ ] By default, the linux kernel command line is being passed the root volume of the boot device ```root=PARTUUID=${uuid}```
- [ ] This needs to be changed to the nvme root volume ```root=/dev/nvme0n1p1```
- [ ] Additionally, during boot, the ```vmlinuz, dtb, and initrd.img``` files will be found in the root of the emmc boot volume (remove ```\boot``` from their paths)

<br/>

Putting this all-together:
```
# after modifying, run ./mkscr.sh

setenv bootargs console=ttyS2,1500000 root=/dev/nvme0n1p1 rw rootwait ipv6.disable=1 earlycon=uart8250,mmio32,0xfe660000

if load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /vmlinuz; then
    if load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /dtb; then
        fdt addr ${fdt_addr_r}
        fdt resize
        if load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} /initrd.img; then
            booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r};
        else
            booti ${kernel_addr_r} - ${fdt_addr_r};
        fi;
    fi;
fi
```

The script ```mkscr.sh``` compiles ```boot.txt``` into ```boot.scr```:
```
cd emmc
./mkscr.sh
```

<br/>

**11. create fstab**

The final step is to edit the ```/etc/fstab``` file with the nvme and emmc boot volume:
```
cd nvme/etc
nano fstab
/dev/nvme0n1p1	/	ext4	rw,relatime		0  1
/dev/mmcblk1p1	/boot	ext4	rw,relatime		0  0
```

<br/>

**12. setup is now complete and the system is ready for use**

unmount the two volumes and reboot the device (be sure to remove the external mmc card)
```
umount emmc
umount nvme
shutdown -h now
```
