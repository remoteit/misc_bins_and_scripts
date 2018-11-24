Precompiled connectd bins
=========================

Precompiled Bins for different OS and Architectures Version 4.4

Version 4.4
===========

-   Multiple P2P connections to one service connection fix.

-   Service only logs in once at startup.

Version 4.3
===========

-   Version Reporting.

-   Copyright Update.

Version 4.2
===========

-   Zero window starvation fix.

-   Spelling error fix

-   CPU utilization reduction

-   NATPMP windows corner case fix

Version 4.1
===========

-   Ping time control for P2P links optimized and fixed

-   !! return codes always returned correctly

-   !! return codes have numeric values added

-   Suppress output now works for -nc

Version 4.0
===========

-   In version 4.0 we change the binary names to connectd.

-   Ping time control for P2P links

-   Command line configuration via base64 blobs (-e option)

-   Nat Checker (-nat)

-   Bug fixes

bintester script -
==================

Download and run the bintester to find the best daemon for ARM and MIPS
platforms

-   cd /tmp

-   sudo wget
    https://github.com/weaved/misc_bins_and_scripts/raw/master/connectd/bintester

-   sudo chmod +x bintester

-   ./bintester arch

where arch is either arm or mips

Precompiled Bin Description
===========================

If none of these run, let us know and we will help you build it for your
platform.

Currently here are:

-   connectd.arm-android: ELF 32-bit LSB executable, ARM, EABI5 version 1
    (SYSV), dynamically linked, interpreter /system/bin/linker, stripped

-   connectd.arm-android_static: ELF 32-bit LSB executable, ARM, EABI5 version 1
    (SYSV), statically linked, stripped

-   connectd.arm-gnueabi: ELF 32-bit LSB executable, ARM, EABI5 version 1
    (SYSV), dynamically linked, interpreter /lib/ld-linux.so.3, for GNU/Linux
    2.6.16, stripped

-   connectd.arm-gnueabi_static: ELF 32-bit LSB executable, ARM, EABI5 version 1
    (SYSV), statically linked, for GNU/Linux 2.6.16, stripped

-   connectd.arm-linaro-pi: ELF 32-bit LSB executable, ARM, EABI5 version 1
    (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for
    GNU/Linux 2.6.26, BuildID[sha1]=729676c05f64adcf1e85798cb45451238a3c5831,
    stripped

-   connectd.arm-linaro-pi_static: ELF 32-bit LSB executable, ARM, EABI5 version
    1 (SYSV), statically linked, for GNU/Linux 2.6.26,
    BuildID[sha1]=c0c847d07f78d2db60786f891427fe67532e3cce, stripped

-   connectd.arm-v5t_le: ELF 32-bit LSB executable, ARM, EABI4 version 1 (SYSV),
    dynamically linked, interpreter /lib/ld-linux.so.3, for GNU/Linux 2.4.17,
    stripped

-   connectd.arm-v5t_le_static: ELF 32-bit LSB executable, ARM, EABI4 version 1
    (SYSV), statically linked, for GNU/Linux 2.4.17, stripped

-   connectd.exe: PE32 executable (console) Intel 80386, for MS Windows

-   connectd.mips-24kec: ELF 32-bit LSB executable, MIPS, MIPS32 rel2 version 1
    (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, stripped

-   connectd.mips-24kec_static: ELF 32-bit LSB executable, MIPS, MIPS32 rel2
    version 1 (SYSV), statically linked, stripped

-   connectd.mips-34kc: ELF 32-bit MSB executable, MIPS, MIPS32 rel2 version 1
    (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, stripped

-   connectd.mips-34kc_static: ELF 32-bit MSB executable, MIPS, MIPS32 rel2
    version 1 (SYSV), statically linked, stripped

-   connectd.mipsel-bmc5354: ELF 32-bit LSB executable, MIPS, MIPS-I version 1
    (SYSV), dynamically linked, interpreter /lib/ld.so.1, for GNU/Linux 2.2.15,
    stripped

-   connectd.mipsel-bmc5354_static: ELF 32-bit LSB executable, MIPS, MIPS-I
    version 1 (SYSV), statically linked, for GNU/Linux 2.2.15, stripped

-   connectd.mipsel-gcc342: ELF 32-bit LSB executable, MIPS, MIPS-II version 1
    (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, stripped

-   connectd.mipsel-gcc342_static: ELF 32-bit LSB executable, MIPS, MIPS-II
    version 1 (SYSV), statically linked, stripped

-   connectd.mips-gcc-4.7.3: ELF 32-bit LSB executable, MIPS, MIPS-I version 1
    (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, stripped

-   connectd.mips-gcc-4.7.3_static: ELF 32-bit LSB executable, MIPS, MIPS-I
    version 1 (SYSV), statically linked, stripped

-   connectd.ppc-gnuspe: ELF 32-bit MSB executable, PowerPC or cisco 4500,
    version 1 (SYSV), dynamically linked, interpreter /lib/ld.so.1, for
    GNU/Linux 2.6.10, stripped

-   connectd.ppc-gnuspe_static: ELF 32-bit MSB executable, PowerPC or cisco
    4500, version 1 (SYSV), statically linked, for GNU/Linux 2.6.10, stripped

-   connectd.x86_64-etch: ELF 64-bit LSB executable, x86-64, version 1 (SYSV),
    dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux
    2.6.0, stripped

-   connectd.x86_64-osx: Mach-O 64-bit x86_64 executable

-   connectd.x86_64-ubuntu16.04: ELF 64-bit LSB executable, x86-64, version 1
    (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for
    GNU/Linux 2.6.32, BuildID[sha1]=cc6257764467476a65c7e4122dc15b0656c5bbf4,
    stripped

-   connectd.x86_64-ubuntu16.04_static: ELF 64-bit LSB executable, x86-64,
    version 1 (GNU/Linux), statically linked, for GNU/Linux 2.6.32,
    BuildID[sha1]=dedba3b764a173c041abbafa63104169b4a71c4c, stripped

-   connectd.x86-etch: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV),
    dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux 2.4.1,
    stripped

-   connectd.x86-linaro_uClibc: ELF 32-bit LSB executable, Intel 80386, version
    1 (SYSV), dynamically linked, interpreter /lib/ld-uClibc.so.0, stripped

-   connectd.x86-linaro_uClibc_static: ELF 32-bit LSB executable, Intel 80386,
    version 1 (SYSV), statically linked, stripped

-   connectd.x86-osx: Mach-O i386 executable

-   connectd.x86-ubuntu16.04: ELF 32-bit LSB executable, Intel 80386, version 1
    (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux
    2.6.32, BuildID[sha1]=0fb817a660a4906ba36f6a061a6811b9fc28dbf4, stripped

-   connectd.x86-ubuntu16.04_static: ELF 32-bit LSB executable, Intel 80386,
    version 1 (GNU/Linux), statically linked, for GNU/Linux 2.6.32,
    BuildID[sha1]=af2acdef19a2ae8c5927acbf234643fedee043c3, stripped
