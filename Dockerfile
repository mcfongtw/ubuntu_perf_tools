#
# Existing Tags:
# mcfongtw/phusion_perf_platform:latest
# mcfongtw/phusion_perf_platform:16.04
#
FROM phusion/baseimage:master

MAINTAINER Michael Fong <mcfong.open@gmail.com>
########################################################
# Make sure the basic folder is setup, with permission nukes
RUN mkdir /workspace && chmod -R 0777 /workspace ;
	
WORKDIR /workspace

ENV HOME /workspace

#######################################################
# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

#######################################################
# Activate debug symbol repository for ubuntu xenial
# https://wiki.ubuntu.com/Kernel/Systemtap
#
## Copy repository config
COPY dbgsym.list /etc/apt/sources.list.d/dbgsym.list

## GPG key import
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C8CAB6595FDFF622

RUN apt-get update

#######################################################
# Linux kernel header
RUN apt-get install -y linux-headers-`uname -r`

#######################################################
# Linux kernel debug symbol
# 
#RUN apt-get update && \
#       apt-get install -y linux-image-`uname -r`-dbgsym linux-headers-`uname -r` linux-image-extra-`uname -r` && \
#        apt-get clean;
#######################################################
# Other system debug symbol
#RUN apt-get update && \
#        apt-get install -y libc6-dbgsym && \
#        apt-get clean;

#######################################################
# perf related
#
RUN apt-get install -y linux-tools-common linux-tools-generic linux-tools-`uname -r`
#
# Set permission to collect perf stat
# -1 - Not paranoid at all
RUN echo 'kernel.perf_event_paranoid = -1' > /etc/sysctl.d/perf.conf
##########################################
# Systemtap related

RUN apt-get install -y gcc systemtap systemtap-sdt-dev elfutils

#######################################################
# systemtap package on apt is out of date on 16.04.3, kernel v4.10 HWE
# Ubuntu bug: https://bugs.launchpad.net/ubuntu/+source/systemtap/+bug/1718537
#             https://bugs.launchpad.net/ubuntu/+source/systemtap/+bug/1683876
# Stackoverflow: https://stackoverflow.com/questions/46047270/systemtap-error-on-ubuntu
# 
##########################################

# Install build-required packages
#RUN apt-get update && \
#        apt-get install -y build-essential gettext elfutils libdw-dev python wget tar && \
#        apt-get clean;

# Build from source - systemtap-3.1
#ARG stap_src_version=3.1

#RUN wget https://sourceware.org/systemtap/ftp/releases/systemtap-${stap_src_version}.tar.gz
#RUN tar xzvf systemtap-${stap_src_version}.tar.gz

# Instruction: https://sourceware.org/git/?p=systemtap.git;a=blob_plain;f=README;hb=HEAD
#RUN cd systemtap-${stap_src_version}/ && \
#         ./configure && \
#         make all && \
#         make install ;
##########################################
RUN mkdir -p stap-scripts/

COPY stap-scripts/* /workspace/stap-scripts/

#######################################################
# Sysbench related
RUN apt-get install -y sysbench
#######################################################
# Misc utilities
RUN apt-get install -y vim git unzip tar wget curl cmake

#######################################################
# FlameGraph
RUN git clone --depth=1 https://github.com/brendangregg/FlameGraph /workspace/FlameGraph

########################################################
# SSH Setting
#
# Enable the SSH server from base image

RUN rm -f /etc/service/sshd/down

# Regenerate SSH host keys. baseimage-docker does not contain any, so you
# have to do that yourself. You may also comment out this instruction; the
# init system will auto-generate one during boot.
RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Enabling the insecure key permanently for demo purposes
RUN /usr/sbin/enable_insecure_key

RUN echo 'root:docker' | chpasswd

# XXX: Allow root login 
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

RUN sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
########################################################
# Setup entry point

COPY docker-entrypoint.sh /workspace/docker-entrypoint.sh

# standard_init_linux.go:190: exec user process caused "exec format error"
RUN chmod +x /workspace/docker-entrypoint.sh

ENTRYPOINT ["/workspace/docker-entrypoint.sh"]

########################################################
# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
