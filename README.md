# Create VM cluster to explore distributed file systems

The Linux Advanced Software Development (ASD) team in Fort Collins is
developing a new file system for load-store memory semantic fabrics.
The file system is currently known as MDCfs.  Our theory is that an
existing Linux cluster/parallel/shared disk file system exists that
we can extend to have a load-store back end.  This will be much simpler
than developing a file system from scratch as we did for The Machine.

We are not necessarily shooting for the be-all, end-all filesystem of all
time.  We must cover the first generation of HPE products with a memory-semantic 
fabric (probably Gen-Z) and the fabric hardware connected to it, primarily
storage memory modules.  We anticipate that scale to be less than a petabyte
and a few dozen compute actors for the first two years after release.

The following file systems are of interest:

* [BeeGFS (parallel)](BeeGFS/README.md)
* [GFS2 (shared disk)](GFS2/README.md)
* [OCFS2 (shared disk)](OCFS2/README.md)
* [OrangeFS (parallel)](OrangeFS/README.md)

I developed a script to create "clusters" of virtual machines.  Some of
these file systems expect at least one of the nodes to have a block device
or extra file system mounted to it.  The setup script creates a linked
set of VMs, each with an "external disk" formatted in ext4 mounted at /data.
Each VM is installed with a copy of Debian 10 "Buster" and a reasonable 
build and development environment.

**Details are given below to get started on a new cluster.**  To reproduce
my efforts on targeted file systems, use the specialized instructions for
each FS in the links above.

There's one [additional cluster: shared PMEM / DAX](IVSHPMEM/README.md) can
be used for kernel development of MDCfs.

---

# dali - rhymes with Dolly

The ```dali``` script found in this repo does the heavy lifting.  First 
establish your file system of interest and create a directory to contain the
artifacts (VM images and extra "block device" files).  Set a few of the
environment variables below and you're on your way!

<!-- this is the only way to get a border, markdown eats style tags -->

<table border='1' cellpadding='5'>
<tr><th>Variable</th><th align='center'>Required?</th><th>Purpose</th><th>Default value</th></tr>
<tr>
<td> DALI_DIR </td>
<td align='center'> Y </td>
<td> Relative directory path (usually at same level as this repo) in which to store artifacts. </td>
<td> &nbsp; </td>
</tr><tr>
<td> DALI_TAG </td>
<td align='center'> Y </td>
<td> Short phrase which serves as the base name for all VMs. </td>
<td> &nbsp; </td>
</tr><tr>
<td> DALI_ORIGINAL </td>
<td align='center'> N </td>
<td> Short phrase is the suffix for the original VM done with "virt-install". </td>
<td> a </td>
</tr><tr>
<td> DALI_CLONES </td>
<td align='center'> N </td>
<td> Space-separated list of short phrases for the clones made with "virt-clone" of the original. </td>
<td> "b c d" </td>
</tr><tr>
<td> DALI_NETWORK </td>
<td align='center'> N </td>
<td> The name of the virtual network used by the VM cluster. </td>
<td> $DALI_TAG </td>
</tr><tr>
<td> http_proxy </td>
<td align='center'> N </td>
<td> Standard definition, used by apt tools. </td>
<td> &nbsp; </td>
</tr><tr>
<td> LIBVIRT_DEFAULT_URI </td>
<td align='center'> N </td>
<td> Standard definition, used by libvirt tools like ```virsh```. </td>
<td> qemu:///system </td>
</tr>
</table>

The first two variables MUST be set.  If others are not set, you will end
up with four VMs named "${DALI_TAG}a" through "${DALI_TAG}d".  While "a"
is considered the original, it has no special configuration over the other
three clones.  Each VM has a root user with a minimal bash configuration.
ssh is configured with a phraseless keypair.

Follow the instructions below to get started and create the required virtual
network.  It's copied from the libvird "default" network.  Details for 
several file systems are in separate READMEs for each FS listed above.

---

# Set the mandatory environment variables

Use of this repo and script assumes you already have the standard libvirt
environment and tools installed.  Let's set up a cluster for studying the
hypothetical XYZZY file system after starting with the environment.

1. export DALI_DIR=XYZZY
1. export DALI_TAG=xyzzy
1. export DALI_ORIGINAL=1
1. export DALI_CLONES="2 3"

These could go in a seed file for future reference.  Now use them.

---

# Create the libvirt network

Convention is to use a lower-case network name.  It will be a NAT isolation
network with an RFC 1918 address space.

1. ```mkdir XYZZY```
1. ```virsh net-dumpxml default > XYZZY/xyzzy.net.xml```
1. ```ip addr show | grep 192.168``` and look at the current networks, you'll need this in a minute.
1. Edit XYZZY/xyzzy.net.xml:
    1. Remove UUID line
    1. Change "name" and "bridge name" to the value of $DALI_TAG
    1. Change the third octet of "ip address" to something unused in your overall networking setup. 
    1. Save and exit the editor
1. ```virsh net-define XYZZY/xyzzy.net.xml```
1. ```virsh net-start xyzzy```
1. ```virsh net-autostart xyzzy```
1. ```ip addr show``` and look for your new network

---

# Configure easy ssh access to the VMs from your host

Each VM is has a phraseless public key in /root/.ssh/authorized_keys.
[Grab the private key from this repo](https://github.hpe.com/MDC-SW/mdcfs-vm-scaffolding/blob/master/homedir/.ssh/id_rsa.nophrase "id_rsa.nophrase")
and put it in your personal .ssh directory.  Add the following stanza to
your .ssh/config:

```
Host bg* gfs2* ocfs2* orange* xyzzy*
	User root
	IdentityFile ~/.ssh/id_rsa.nophrase
```

Now manually reconfigure DNS name resolution.  If /etc/resolv.conf on your
system is a symlink, copy it into a standalone file.  Add a new
"nameserver" clause with the 192.168.X.1 address you chose above, insure it's the
FIRST nameserver.  Then protect the file via "sudo chattr +i /etc/resolv.conf".
That keeps your host's DHCP client from overwriting it on an hourly basis.  It
also assumes your DHCP/DNS setup is reasonably stable :-)

Once the VMs are up and running you can log into them with ```ssh <hostname>```

---

# Create and customize the original VM

With the environment variables DALI_DIR, DALI_TAG, DALI_ORIGINAL, and
DALI_CLONES set, make the original VM:

```$ dali original```

dali invokes virt-install which is pointed at an internal HPE Debian repo
in Fort Collins.  This cold install should take less than ten minutes
depending on the HPE network speed.

The virt-install also references a Debian preseed file to set up
the primary disk image at "/" and the secondary disk at "/data".  The
following artifacts will appear in directory XYZZY:

* xyzzy1.img, the VM root disk image with Debian 10.  Note the name is based on "${DALI_TAG}${DALI_ORIGINAL}".
* block1.raw, the secondary disk mounted at /data in the VM xyzzya
* xyzzy1.env.sh, the full set of environment variables used at the last run of dali

Running ```virsh list --all``` should show your new VM.  At this point you
can start it and log into it, making any customizations you want to see
in all the VMs.  This could include adding more packages, setting up other
configs, etc.

When finished, shut down the VM with ```shutdown -h```.

---

# Create the clones

```$ dali clone ALL```

Makes VMs and their artifact files in XYZZY from $DALI_CLONES: xyzzy2
and xyzzy3.

---

# Other dali directives

You've seen ```dali original``` and ```dali clone ALL```, there are more.

Note that many of the "name" arguments below only need the "suffix"
of a VM host.  For example, if DALI_TAG is XYZZY and your VMs are 
xyzzy1, xyzzy2, and xyzz3, the name argument is just "1", "2", or "3".
DALI_TAG is prepended for you.

Run ```dali``` with no directives to get the current list.  Details:

```dali clone <src> <dest>``` creates one new clone "dest" based
on "src".  For example, ```dali clone 3 bizmumble``` would create a new
VM with the full name "xyzzybizmumble" derived from "xyzzy3"

```dali remove <name>``` removes that clone and its artifacts.  If name is ALL
then all $DALI_CLONES are removed, leaving $DALI_ORIGINAL.

```dali start <name>``` issues ```virsh start``` for that clone.  If name is ALL then all VMs are started, including $DALI_ORIGINAL.

```dali shutdown <name>``` tries to ssh to that VM and run "shutdown -h 0".
It's a much more graceful way than "destroy".  If name is ALL, hit all VMs.

```dali destroy <name>``` issues ```virsh destroy <name>``` which will always work but is a little harsh.  If name is ALL, you get the drill.

```dali pssh <bash command to be run on VM>``` uses parallel-ssh to run the
command on all VMs.  This assume "parallel-ssh" is installed on your host :-)
