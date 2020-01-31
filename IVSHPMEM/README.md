# Emulated NVDIMM for a shared DAX block device

* [https://docs.pmem.io/getting-started-guide/creating-development-environments/virtualization/qemu]
* [https://qemu.weilnetz.de/doc/qemu-doc.html]

NVDIMM emulation has been supported in QEMU since version 2.6 (as has hotplug
memory additions in "slots").  This sets aside a file-backed memory object
marking its space in the guest as Type 12 memory (NVDIMM).  Then the standard
pmem.ko module can be used to adopt it as a DAX device.  If the same backing
file is used in multiple VMs then the DAX device is shared.  This is the
environment needed for MDCfs development extending OCFS2.

The "standard" block files (blocka.img, etc) are not used.

<!------------------------------------------------------------------------>
---
### Licensing

All the pieces are GPL v2.

<!------------------------------------------------------------------------>
---
### 1. Set up virtual network "ivp"
Start by sourcing IVSHPMEM/IVSHPMEM.seed.sh into your shell, or
```
$ export DALI_DIR=IVSHPMEM DALI_TAG=ivp DALI_ORIGINAL=a DALI_CLONES="b c"
```
Next, follow the [instructions in the main README](https://github.hpe.com/MDC-SW/mdcfs-vm-scaffolding/blob/master/README.md#create-the-libvirt-network) about creating the virtual network.
<!------------------------------------------------------------------------>
---
### 2. Create and enable a file on the host for the PMEM backing store

Create a file of the desired DAX block device size somewhere and change 
ownership and permissions for use by QEMU:

```
$ fallocate -l 1G $DALI_DIR/FAM
$ chgrp libvirt-qemu $DALI_DIR/FAM
$ chmod 664 $DALI_DIR/FAM
```
"FAM" is used (instead of NVDIMM) for combined use in a FAME/F.E.E. host.

By default apparmor restricts the files used by libvirt and this backing file
is outside that restriction.  [Here is a decent introduction to apparmor](https://ubuntuforums.org/showthread.php?t=1008906).  apparmor must either be disabled
(not the the best idea) or modified.  Enable the file use in Apparmor by 
extending the "profile" template for libvirt.  This template file is copied
to a per-UUID file for each VM.  Edit /etc/apparmor.d/libvirt/TEMPLATE.QEMU
and add the line
```
	"/home/YOURNAME/**/FAM rw",
```
between the curly braces, after the #include.  A syntax error here will not
show up until the VM is started, AND THE ERROR MESSAGES MAY NOT BE HELPFUL.

<!------------------------------------------------------------------------>
---
### 3. Create the first node and give it an NVDIMM memory object device
```
$ dali original
```

#### A) Edit the domain XML and replace the "domain" line:

```
<domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
```

#### B) Immediately before the &lt;memory... line, add this:
```
  <maxMemory slots='2' unit='KiB'>2097152</maxMemory>
```
This can be done with --memory arguments to virtinstall but then requires
a minimal numa setup (see the next subsection).

#### C) In the &lt;cpu&gt; section, add these lines
```
    <numa>
      <cell id='0' cpus='0' memory='1048576' unit='KiB'/>
    </numa>
```
This can PROBABLY be done with --cpu arguments to virtinstall but I have
not worked out the right voodoo.

#### D) At the end, after &lt;/devices&gt; add these lines
```
  <qemu:commandline>
    <qemu:arg value='-M'/>
    <qemu:arg value='nvdimm=on'/>
    <qemu:arg value='-object'/>
    <qemu:arg value='memory-backend-file,mem-path=/home/YOU/some/where/FAM,size=1G,id=FAM,share=on'/>
    <qemu:arg value='-device'/>
    <qemu:arg value='nvdimm,memdev=FAM'/>
  </qemu:commandline>
```
The -M argument enables the marking of the memory area as Type 12, and matches
the device type in the last line of this stanza.  If you look at a running
VM command line you'll see two "-M" directives.

Adjust the "mem-path".  The file name must be "FAM" to agree with the setting
previously added to the libvirt apparmor profile.

<!------------------------------------------------------------------------>
---
### 4. Reconfigure the PMEM device on the original host

Start the VM to insure all paths, etc. are correct.
(Bizarre) error messages about the FAM file are mostly likely from syntax
errors in the apparmor profile (see the previous section).  

Log into the guest "ivpa" and execute lsblock to verify the existence of
a "pmem" block device.  Once that's verified, check the NVDIMM status.
```
root@ivpa:~# apt-get install -y ndctl
:
root@ivpa:~# ndctl list
[
  {
    "dev":"namespace0.0",
    "mode":"XXXXX",
    "size":1073741824,
    "blockdev":"pmem0"
  }
]
```
If the mode is not "fsdax", 
[https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/managing_storage_devices/using-nvdimm-persistent-memory-storage_managing-storage-devices](reconfigure the NVDIMM block device to be so:)
```
# ndctl create-namespace --reconfig=namespace0.0 --mode=fsdax --force
```
The output should be
```
{
  "dev":"namespace0.0",
  "mode":"fsdax",
  "map":"dev",
  "size":"1006.00 MiB (1054.87 MB)",
  "uuid":"blahblahblah-blah-blah-blah-blahblah",
  "sector_size":512,
  "blockdev":"pmem0",
  "numa_node":0
}
```

This node is ready for prime time!  Shut it down for cloning.
<!------------------------------------------------------------------------>
---
### 5. Unleash the clones
Back on the host,
```
$ dali clone ALL
```

This section will expand over time to bring in the OCFS2 extension and do
kernel development.  Stay tuned.


