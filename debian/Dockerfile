# -- 1st stage: builder_A, run with host arch
FROM debian:bookworm as builder_A
ARG MODEL
ARG KERNEL_FW_URL
ARG KERNEL_FW_SHA256
ARG RELEASE_URL
WORKDIR /root
ADD env.sh tools.sh ./
COPY common/files files/
RUN mkdir steps
ADD steps/init_builder_A.sh steps/
RUN sh steps/init_builder_A.sh
ADD steps/download.sh steps/
RUN sh steps/download.sh "${KERNEL_FW_URL}" "${KERNEL_FW_SHA256}"
RUN sh steps/download.sh "${RELEASE_URL}/rk3568-nanopi-${MODEL}.dtb"
ADD steps/configure_files.sh steps/
RUN sh steps/configure_files.sh "${MODEL}"
ADD steps/install_firmware.sh steps/
RUN sh steps/install_firmware.sh
ADD steps/install_rootfs_1st_stage.sh steps/
RUN sh steps/install_rootfs_1st_stage.sh

# -- 2nd stage: finalize rootfs, run with arm64 arch transparently emulated by qemu
FROM --platform=linux/arm64/v8 scratch as rootfs_finalizer
COPY --from=builder_A /root/rootfs /
RUN /debootstrap/debootstrap --second-stage
WORKDIR /root
ADD env.sh tools.sh ./
RUN mkdir steps
ADD steps/create_user.sh steps/
RUN sh steps/create_user.sh
RUN rm -rf env.sh tools.sh steps    # cleanup
RUN rm -rf /var/cache/* /var/lib/apt/lists/*   # discard the cache

# -- 3rd stage: builder_B, run with host arch
FROM debian:bookworm as builder_B
ARG MODEL
ARG PARAMS
ARG RELEASE_URL
COPY --from=rootfs_finalizer / /root/rootfs
WORKDIR /root
COPY nanopi-${MODEL}/files files/
ADD env.sh tools.sh ./
RUN mkdir steps
ADD steps/init_builder_B.sh steps/
RUN sh steps/init_builder_B.sh
ADD steps/download.sh steps/
RUN sh steps/download.sh "${RELEASE_URL}/idbloader-${MODEL}.img"
RUN sh steps/download.sh "${RELEASE_URL}/u-boot-${MODEL}.itb"
ADD steps/finalize_rootfs.sh steps/
RUN sh steps/finalize_rootfs.sh ${MODEL} ${PARAMS}
COPY --from=builder_A /root/fs.uuid /root/
ADD steps/build_image.sh steps/
RUN sh steps/build_image.sh
