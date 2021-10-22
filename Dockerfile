FROM ubuntu:focal

ARG USERNAME=user
ARG HOMEDIR=/work

## SYSTEM SETUP

ENV DEBIAN_FRONTEND=noninteractive

RUN { \
      echo 'Acquire::http::Pipeline-Depth 0;'; \
      echo 'Acquire::http::No-Cache true;'; \
      echo 'Acquire::BrokenProxy    true;'; \
    } > /etc/apt/apt.conf.d/99fixbadproxy

RUN sed -ie 's/archive\.ubuntu\.com/jp\.archive\.ubuntu\.com/g' /etc/apt/sources.list

RUN apt-get update \
  && apt-get install -y \
    build-essential \
    llvm-7-dev \
    lld-7 \
    clang-7 \
    nasm \
    acpica-tools \
    uuid-dev \
    git \
    python3-distutils \
    ca-certificates \
    curl \
    vim \
    sudo \
    cmake \
  && apt-get clean -y

RUN for item in \
    llvm-PerfectShuffle \
    llvm-ar \
    llvm-as \
    llvm-bcanalyzer \
    llvm-cat \
    llvm-cfi-verify \
    llvm-config \
    llvm-cov \
    llvm-c-test \
    llvm-cvtres \
    llvm-cxxdump \
    llvm-cxxfilt \
    llvm-diff \
    llvm-dis \
    llvm-dlltool \
    llvm-dwarfdump \
    llvm-dwp \
    llvm-exegesis \
    llvm-extract \
    llvm-lib \
    llvm-link \
    llvm-lto \
    llvm-lto2 \
    llvm-mc \
    llvm-mca \
    llvm-modextract \
    llvm-mt \
    llvm-nm \
    llvm-objcopy \
    llvm-objdump \
    llvm-opt-report \
    llvm-pdbutil \
    llvm-profdata \
    llvm-ranlib \
    llvm-rc \
    llvm-readelf \
    llvm-readobj \
    llvm-rtdyld \
    llvm-size \
    llvm-split \
    llvm-stress \
    llvm-strings \
    llvm-strip \
    llvm-symbolizer \
    llvm-tblgen \
    llvm-undname \
    llvm-xray \
    ld.lld \
    lld-link \
    clang \
    clang++ \
    clang-cpp \
  ; do \
    update-alternatives --install "/usr/bin/${item}" "${item}" "/usr/bin/${item}-7" 50 \
  ; done

## DLANG

RUN mkdir -p /opt/ldc
RUN curl -L https://github.com/ldc-developers/ldc/releases/download/v1.27.1/ldc2-1.27.1-linux-x86_64.tar.xz \
  | tar xpJv -C /opt/ldc
RUN ln -s ldc2-1.27.1-linux-x86_64 /opt/ldc/current
ENV PATH=$PATH:/opt/ldc/current/bin

## USER SETUP

RUN useradd -d $HOMEDIR $USERNAME
RUN mkdir -p $HOMEDIR
RUN chown $USERNAME $HOMEDIR
RUN echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

## ENV SETUP

USER $USERNAME
WORKDIR $HOMEDIR

### EDK II
RUN git clone --recursive https://github.com/tianocore/edk2.git edk2 \
 && (cd edk2 && git checkout 38c8be123aced4cc8ad5c7e0da9121a181b94251) \
 && make -C edk2/BaseTools/Source/C

### MikanOS libs
RUN mkdir -p mikanos_libs
RUN curl -L https://github.com/uchan-nos/mikanos-build/releases/download/v2.0/x86_64-elf.tar.gz \
  | tar xzv -C mikanos_libs

### PATH
ENV CPPFLAGS="\
  -I$HOMEDIR/mikanos_libs/x86_64-elf/include/c++/v1 \
  -I$HOMEDIR/mikanos_libs/x86_64-elf/include \
  -I$HOMEDIR/mikanos_libs/x86_64-elf/include/freetype2 \
  -I$HOMEDIR/edk2/MdePkg/Include \
  -I$HOMEDIR/edk2/MdePkg/Include/X64 \
  -nostdlibinc \
  -D__ELF__ \
  -D_LDBL_EQ_DBL \
  -D_GNU_SOURCE \
  -D_POSIX_TIMERS \
  -DEFIAPI='__attribute__((ms_abi))'"
ENV LDFLAGS="-L$HOMEDIR/mikanos_libs/x86_64-elf/lib"

### .bashrc
COPY docker.bashrc $HOMEDIR/.bashrc

## RUN

#USER $USERNAME
#WORKDIR ${HOMEDIR}
CMD ["bash"]
