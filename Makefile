.PHONY: debian  debian-r5c debian-r5s dtb uboot all clean

all: uboot dtb debian
	@echo "image build complete"

debian: debian-r5c debian-r5s
	xz -z8v debian/nanopi-r5c/mmc_2g.img
	xz -z8v debian/nanopi-r5s/mmc_2g.img

debian-r5c:
	sudo sh debian/nanopi-r5c/make_debian_img.sh nocomp

debian-r5s:
	sudo sh debian/nanopi-r5s/make_debian_img.sh nocomp

dtb:
	sh dtb/make_dtb.sh

uboot:
	sh uboot/make_uboot.sh cp

clean:
	sudo sh debian/make_debian_img.sh clean
	sh dtb/make_dtb.sh clean
	sh uboot/make_uboot.sh clean

