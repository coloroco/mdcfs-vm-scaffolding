# GFS2 - Global File System for Shared-Disk Storage

* https://en.wikipedia.org/wiki/GFS2
* https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/global_file_system_2/ch-overview-gfs2

GFS2 is a "shared disk" file system, meaning all nodes must reference the
same block device (actually, the gfs2 file system on that block device).
In a real system, a SAN (Storage Area Network) or multipath SCSI setup
would be used.  In VMs it's a little easier to spoof.

The history of GFS2 has brought it under Red Hat's "ownership" as the
primary maintainer.  An interesting aspect of GFS2 is the recommendation
for multiple instances: instead of one 10-TB system, consider making ten
1-TB systems.

These steps will create a cluster of three Debian VMs: gfs2a, gfs2b, and gfs2c
and give them a shared filesystem seen by each at /data.

<!------------------------------------------------------------------------>
---
### Licensing
GFS2 kernel components were adopted by kernel.org at 2.6.19 and are under
GPL 2.0.  Other user space components are LGPL.
<!------------------------------------------------------------------------>
---
### 1. Set up virtual network "gfs2"
Start by sourcing GFS2/GFS2.seed.sh into your shell, or
```
$ export DALI_DIR=GFS2 DALI_TAG=gfs2 DALI_ORIGINAL=a
$ export DALI_CLONES="b c"
```
Next, follow the [instructions in the main README](https://github.hpe.com/MDC-SW/mdcfs-vm-scaffolding/blob/master/README.md#create-the-libvirt-network) about creating the virtual network.

<!------------------------------------------------------------------------>
---
### 2. Create all nodes and reconfigure the clone block devices

* [Before setup](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/global_file_system_2/s1-ov-preconfig "Before setup")
* [Configuration considerations](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/global_file_system_2/ch-considerations "Configuration considerations")
* [GFS2 under Debian with DRBD](https://wiki.debian.org/kristian_jerpetjoen "GFS2 under Debian")
* man page for gfs2 (after installing gfs2-utils)

The Debian instructions (lenny/wheezy era) recommend cman, the "Cluster 
Manager" for member management, quorum checking, and the like.  At Buster
that's been replaced with the Corosync Cluster Engine.  Configuration there
is by IP address so all nodes need to be up and running first.  They
also use DRBD to create a shared block device, another interesting idea.
Here I'll stick with the (virtual) /dev/vdb.

Back to work: create all three nodes.
```
$ dali original
$ dali clone ALL
```
All three VMs need to point at the same block device.
```
$ virsh edit gfs2b
```
change "blockb.img" to "blocka.img"
```
$ virsh edit gfs2c
```
change "blockc.img" to "blocka.img"

The two files blockb.img and blockc.img are unused, just leave them be.
<!------------------------------------------------------------------------>
---
### 3. Reconfigure /data mount point
The node VMs must all be running:
```
$ dali start ALL
```
Sometimes it takes a few tens of seconds after the nodes are started for
DNS resolution to come up, so do a dummy command on all of them:
```
$ dali pssh echo
```
...until all three succeed.

Right now each node has its own block device and file system mounted at /data.
Fix the automatic ext4 mount of /dev/vdb1 as ext4 to /dev/vdb as gfs2.  Keep
the mount point.  "_netdev" puts a network up/down barrier around the mount.
```
$ dali pssh umount /data

$ dali pssh "sed --posix -i\.orig -e 's|^/dev/vdb1[[:space:]]*\(/.*\)[[:space:]]*ext4.*|/dev/vdb \1 gfs2 _netdev,defaults 0 2|' /etc/fstab"
```
<!------------------------------------------------------------------------>
---
### 4. Install and configure GFS2 and Corosync on all nodes
```
$ dali pssh DEBIAN_FRONTEND=noninteractive apt-get install -y gfs2-utils dlm-controld
```
Get the IP address for each node, needed for a configuration file.
```
$ dali pssh 'ip addr show | egrep "SUCCESS|192"'
```
Move the original cluster configuration file out of the way:
```
$ dali pssh mv /etc/corosync/corosync.conf /etc/corosync/corosync.conf.orig
```
Copy the template file somewhere and edit it with the correct IP addresses.
Then put it on each node.
```
$ cp GFS2/corosync.template /tmp/corosync.conf
$ vi /tmp/corosync.conf
$ dali pput /tmp/corosync.conf /etc/corosync/corosync.conf
$ dali cat /etc/corosync/corosync.conf
$ dali pssh 'echo "enable_fencing=0" >> /etc/default/dlm'
$ dali cat /etc/default/dlm
```
<!------------------------------------------------------------------------>
---
### 5. Enable and start GFS2 services on all nodes
Start the GFS2 service daemon and register the cluster, then verify:
```
$ dali pssh systemctl enable corosync
$ dali pssh systemctl start corosync
$ dali pssh systemctl enable dlm
$ dali pssh systemctl start dlm
$ dali pssh dlm_tool status
```
<!------------------------------------------------------------------------>
---
### 6. Set up the shared disk
On one of the nodes, format the disk for up to ten connecting nodes.
```
$ ssh gfs2a mkfs.gfs2 -O -p lock_dlm -t gfs2cluster:mdcfs -j 10 /dev/vdb
```
Finally, mount the disk on all three nodes.
```
$ dali pssh mount /data

$ dali pssh dlm_tool ls
```

Now all three VMs see the same storage in /data.  Files created on any node
should be seen on the other two.

Have fun!
