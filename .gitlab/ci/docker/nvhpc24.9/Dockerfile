# https://catalog.ngc.nvidia.com/orgs/nvidia/containers/nvhpc/tags
FROM kitware/nvidia-nvhpc:24.9-devel-cuda_multi-ubuntu24.04
MAINTAINER Brad King <brad.king@kitware.com>

COPY install_deps.sh /root/install_deps.sh
RUN sh /root/install_deps.sh
