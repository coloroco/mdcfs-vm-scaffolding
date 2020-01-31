# OrangeFS - A "Scale-out Network" File System

* http://www.orangefs.org/

OrangeFS is a "parallel" file system: the data is spread out across multiple
OS instances and presented as a shared global space.

These steps will create a cluster of XXXX VMs...
* one
* two
* three

The clients will see a single global file system space mounted at /data.

<!------------------------------------------------------------------------>
---
### Licensing
OrangeFS kernel components were adopted by kernel.org at 4.6 and are under
GPL 2.0.  Other user space components are LGPL.
<!------------------------------------------------------------------------>
---
### 1. Set up virtual network "orange"
Start by sourcing OrangeGFS/OrangeGFS.seed.sh into your shell, or
```
$ export DALI_DIR=OrangeFS DALI_TAG=orange DALI_ORIGINAL=a
$ export DALI_CLONES="b c"
```
Next, follow the [instructions in the main README](https://github.hpe.com/MDC-SW/mdcfs-vm-scaffolding/blob/master/README.md#create-the-libvirt-network) about creating the virtual network.
<!------------------------------------------------------------------------>
---
### 2. Create and configure the original, then create clones
* http://docs.orangefs.com/home/index.html which gets to
* http://docs.orangefs.com/v_2_9/index.htm

Create, start, and log into the first node.
```
$ dali original
$ virsh start orangea
$ ssh orangea
```
libc6-dev gets libio.h on Ubuntu/RHEL/SLES/CentOS, but NOT Debian.  It's a
glibc internal-only library.  Odd.  On the VM, this will fail at the "make".
```
# apt install automake build-essential bison flex libattr1 libattr1-dev
# apt install linux-headers-amd64
# wget http://download.orangefs.org/current/source/orangefs-2.9.7.tar.gz
# tar -zxvf orangefs.2.9.7.tar.gz
# cd orangefs.2.9.7
# ./configure --prefix=/opt/orangefs --with-kernel=/lib/modules/`uname -r`/build --with-db-backend=lmdb
# make
# make install
# make kmod
# make kmod_prefix=/opt/orangefs kmod_install
```

