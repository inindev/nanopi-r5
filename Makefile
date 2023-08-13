
LDIST-R5C ?= $(shell cat "debian/nanopi-r5c/make_debian_img.sh" | sed -n 's/\s*local deb_dist=.\([[:alpha:]]\+\)./\1/p')
LDIST-R5S ?= $(shell cat "debian/nanopi-r5s/make_debian_img.sh" | sed -n 's/\s*local deb_dist=.\([[:alpha:]]\+\)./\1/p')


all: uboot dtb debian
	@echo "all binaries ready"

debian: debian-r5c debian-r5s

debian-r5c: uboot dtb debian/nanopi-r5c/mmc_2g.img
	@echo "debian nanopi-r5c image ready"

debian-r5s: uboot dtb debian/nanopi-r5s/mmc_2g.img
	@echo "debian nanopi-r5s image ready"

dtb: dtb/rk3568-nanopi-r5c.dtb dtb/rk3568-nanopi-r5s.dtb
	@echo "device tree binaries ready"

uboot: uboot/idbloader-r5c.img uboot/u-boot-r5c.itb uboot/idbloader-r5s.img uboot/u-boot-r5s.itb
	@echo "u-boot binaries ready"

package-%: all
	@echo "building package for version $*"

	@rm -rfv distfiles
	@mkdir -v distfiles

	@cp -v uboot/idbloader-r5c.img uboot/u-boot-r5c.itb distfiles
	@cp -v dtb/rk3568-nanopi-r5c.dtb distfiles
	@cp -v debian/nanopi-r5c/mmc_2g.img distfiles/nanopi-r5c_$(LDIST-R5C)-$*.img
	@xz -zve8 distfiles/nanopi-r5c_$(LDIST-R5C)-$*.img

	@cp -v uboot/idbloader-r5s.img uboot/u-boot-r5s.itb distfiles
	@cp -v dtb/rk3568-nanopi-r5s.dtb distfiles
	@cp -v debian/nanopi-r5s/mmc_2g.img distfiles/nanopi-r5s_$(LDIST-R5S)-$*.img
	@xz -zve8 distfiles/nanopi-r5s_$(LDIST-R5S)-$*.img

	@cd distfiles ; sha256sum * > sha256sums.txt

clean:
	@rm -rfv distfiles
	sudo sh debian/nanopi-r5c/make_debian_img.sh clean
	sudo sh debian/nanopi-r5s/make_debian_img.sh clean
	sh dtb/make_dtb.sh clean
	sh uboot/make_uboot.sh clean
	@echo "all targets clean"

debian/nanopi-r5c/mmc_2g.img:
	sudo sh debian/nanopi-r5c/make_debian_img.sh nocomp

debian/nanopi-r5s/mmc_2g.img:
	sudo sh debian/nanopi-r5s/make_debian_img.sh nocomp

dtb/rk3568-nanopi-r5c.dtb dtb/rk3568-nanopi-r5s.dtb:
	sh dtb/make_dtb.sh cp

uboot/idbloader-r5c.img uboot/u-boot-r5c.itb uboot/idbloader-r5s.img uboot/u-boot-r5s.itb:
	sh uboot/make_uboot.sh cp


.PHONY: debian debian-r5c debian-r5s dtb uboot all package-* clean

