# OCFS2 - The Oracle Cluster File System

[https://manpages.debian.org/buster/ocfs2-tools/ocfs2.7.en.html]

OCFS2 is a "shared disk" file system, meaning all nodes must reference the
same block device (actually, the ocfs2 file system on that block device).
In a real system, a SAN (Storage Area Network) or multipath SCSI setup
would be used.  In VMs it's a little easier to spoof.

These steps will create a cluster of three VMs: ocfs2a, ocfs2b, and ocfs2c
and give them a shared filesystem seen by each at /data.

<!------------------------------------------------------------------------>
---
### Licensing
OCFS2 is provided by Oracle and all components are GPL v 2.0.

https://oss.oracle.com/projects/ocfs2/

<!------------------------------------------------------------------------>
---
### 1. Set up virtual network "ocfs2"
Start by sourcing OCFS2/OCFS2.seed.sh into your shell, or
```
$ export DALI_DIR=OCFS2 DALI_TAG=ocfs2 DALI_ORIGINAL=a DALI_CLONES="b c"
```
Next, follow the [instructions in the main README](https://github.hpe.com/MDC-SW/mdcfs-vm-scaffolding/blob/master/README.md#create-the-libvirt-network) about creating the virtual network.
<!------------------------------------------------------------------------>
---
### 2. Create all nodes and reconfigure the clone block devices
```
$ dali original
$ dali clone ALL
```
All three VMs need to point at the same block device.
```
$ virsh edit ocfs2b
```
change "blockb.img" to "blocka.img"
```
$ virsh edit ocfs2c
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
Fix the automatic ext4 mount of /dev/vdb1 as ext4 to /dev/vdb as ocfs2.  Keep
the mount point.  "_netdev" puts a network up/down barrier around the mount.
```
$ dali pssh umount /data

$ dali pssh "sed --posix -i\.orig -e 's|^/dev/vdb1[[:space:]]*\(/.*\)[[:space:]]*ext4.*|/dev/vdb \1 ocfs2 _netdev,defaults 0 2|' /etc/fstab"

```
<!------------------------------------------------------------------------>
---
### 4. Install and configure OCFS2 on all nodes
```
$ dali pssh DEBIAN_FRONTEND=noninteractive apt-get install -y ocfs2-tools
```
Get the IP address for each node, needed for the configuration step.
```
$ dali pssh 'ip addr show | egrep "SUCCESS|192"'
```
Do cluster configuration on the first node, then copy it around.
```
$ ssh ocfs2a
```
You are now inside the first VM.
```
# o2cb add-cluster mdcfs
# o2cb add-node mdcfs ocfs2a --ip 192.168.xxx.yyy --number 1
# o2cb add-node mdcfs ocfs2b --ip 192.168.xxx.yyy --number 2
# o2cb add-node mdcfs ocfs2c --ip 192.168.xxx.yyy --number 3

# o2cb list-cluster mdcfs
(verify the output)

# scp /etc/ocfs2/cluster.conf ocfs2b:/etc/ocfs2
# scp /etc/ocfs2/cluster.conf ocfs2c:/etc/ocfs2

# exit
```
<!------------------------------------------------------------------------>
---
### 5. Enable and start OCFS2 services on all nodes
Start the OCFS2 service daemon and register the cluster.
```
$ dali pssh systemctl enable o2cb
$ dali pssh systemctl start o2cb
$ dali pssh o2cb register-cluster mdcfs
```
Fix up the boot time configuration.
```
$ dali pssh "sed -i\.orig -e 's/\(^O2CB_ENABLED=\).*/\1true/' -e 's/\(^O2CB_BOOTCLUSTER=\).*/\1mdcfs/' /etc/default/o2cb"
```
<!------------------------------------------------------------------------>
---
### 6. Set up the shared disk
On one of the nodes, format the disk for up to four connecting nodes:
```
$ ssh ocfs2a mkfs.ocfs2 -L mdcfs -N 4 /dev/vdb
```
By default, heartbeat mode is local so the "add-heartbeat" command is not
necessary.  For reference, it would be "o2cb add-heartbeat mdcfs /dev/vdb".
Finally, mount the disk on all three nodes.
```
$ dali pssh mount /data
```

Now all three VMs see the same storage in /data.  Files created on any node
should be seen on the other two.

Have fun!

