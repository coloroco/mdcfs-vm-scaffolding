# BeeGFS - The "Leading" Parallel Cluster File System

* https://www.beegfs.io/content/
* https://www.beegfs.io/wiki/FAQ

BeeGFS is a "parallel" file system: the data is spread out across multiple
OS instances and presented as a shared global space.  BeeGFS has several
classes of actors in a deployment: management, metadata, data, and admin
servers set up to deliver a global file system to clients.  In a production
setting the number and location of these actors is tuned but for this
experiment it will be much simpler and more explicit.

These steps will create a cluster of seven VMs whose names are derived from
the BeeGFS Debian packages:
* Management: bgmgmtd (the original)
* Metadata: bgmeta
* Storage: bgstorage1 and bgstorage2
* Clients: bgclient1 and bgclient2
* Administration/monitoring: bgadmon

The clients will see a single global file system space mounted at /data.

<!------------------------------------------------------------------------>
---
### Licensing
BeeGFS is provided by a third party, ThinkParQ, spun off from the original
developer, Fraunhofer.  Kernel components for clients are licensed under
GPL 2.0.  Other components are under various licenses such as MIT, LGPL,
and BSD.  [https://www.beegfs.io/docs/BeeGFS_EULA.txt](BeeGFS has an EULA)
which is a standard copyleft statement.  Most features are free for use
except for those deemed "Enterprise Features" which require a purchase:
  - Mirroring
  - High Availability
  - Quota Enforcement
  - Access Control Lists (ACLs)
  - Storage Pool
They may also be enabled for a 60-day trial.  These conditions will be 
evaluated further should BeeGFS become the primary choice for an MDCfs base.
<!------------------------------------------------------------------------>
---
### 1. Set up virtual network "bg"
Start by sourcing BeeGFS/BeeGFS.seed.sh into your shell, or
```
$ export DALI_DIR=BeeGFS DALI_TAG=bg DALI_ORIGINAL=mgmtd
$ export DALI_CLONES="meta admon storage1 storage2 client1 client2"
```
Next, follow the [instructions in the main README](https://github.hpe.com/MDC-SW/mdcfs-vm-scaffolding/blob/master/README.md#create-the-libvirt-network) about creating the virtual network.
<!------------------------------------------------------------------------>
---
### 2. Create and configure the original, then create clones
* https://www.beegfs.io/wiki/DownloadInstallationPackages
Create and configure the original for the BeeGFS repo but install nothing yet.
```
$ dali original
$ virsh start bgmgmtd
$ ssh bgmgmtd
```
On the VM, 
```
# wget -O /etc/apt/sources.list.d/BeeGFS.list https://www.beegfs.io/release/latest-stable/dists/beegfs-deb9.list
# wget -q https://www.beegfs.io/release/latest-stable/gpg/DEB-GPG-KEY-beegfs -O- | apt-key add -
# apt-get update
# shutdown -h 0
```
Make one clone image to save time for subsequent retries or extensions:
```
$ dali clone mgmtd spare
```
Now clone and start the remaining actors:
```
$ dali clone ALL
$ dali start ALL
```
<!------------------------------------------------------------------------>
---
### 3. Install and configure node-specific packages

* https://www.beegfs.io/wiki/ManualInstallation
* https://www.beegfs.io/wiki/ManualInstallWalkThrough

In the web docs,

| Node name | VM name | Service ID | Additional Info |
|:---------:|:------- |:----------:|:---------------:|
| node01    | bgmgmtd |      1     | |
| node02    | bgmeta  |      2     | |
| node03    | bgstorage1<br>bgstorage2 | 3<br>4 | target ID = 301<br>target ID = 401 |
| node04    | bgclient1<br>bgclient2 | | |
| node05    | bgadmon         | | |

```
$ ssh bgmgmtd DEBIAN_FRONTEND=noninteractive apt-get install -y beegfs-mgmtd
$ ssh bgmgmtd /opt/beegfs/sbin/beegfs-setup-mgmtd -p /data/beegfs_mgmtd
 
$ ssh bgmeta DEBIAN_FRONTEND=noninteractive apt-get install -y beegfs-meta
$ ssh bgmeta /opt/beegfs/sbin/beegfs-setup-meta -p /data/beegfs_meta -s 2 -m bgmgmtd

$ ssh bgstorage1 DEBIAN_FRONTEND=noninteractive apt-get install -y beegfs-storage
$ ssh bgstorage2 DEBIAN_FRONTEND=noninteractive apt-get install -y beegfs-storage
$ ssh bgstorage1 /opt/beegfs/sbin/beegfs-setup-storage -p /data/beegfs_storage -s 3 -i 301 -m bgmgmtd
$ ssh bgstorage2 /opt/beegfs/sbin/beegfs-setup-storage -p /data/beegfs_storage -s 4 -i 401 -m bgmgmtd

$ ssh bgclient1 DEBIAN_FRONTEND=noninteractive apt-get install -y beegfs-client beegfs-helperd beegfs-utils
$ ssh bgclient2 DEBIAN_FRONTEND=noninteractive apt-get install -y beegfs-client beegfs-helperd beegfs-utils
$ ssh bgclient1 /opt/beegfs/sbin/beegfs-setup-client -m bgmgmtd
$ ssh bgclient2 /opt/beegfs/sbin/beegfs-setup-client -m bgmgmtd

$ ssh bgadmon DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-11-jre-headless beegfs-admon
```
A config file on bgadmon must be edited manually.
```
$ ssh bgadmon
# vi /etc/beegfs/geegfs-admon.conf
:
set sysMgmtdHost=bgmgmtd
:
# exit
```

Config files and subdirs on VMs after those setup commands.

https://www.beegfs.io/wiki/BasicConfigurationFirstStartup
```
bgVM	File in /etc/beegfs	Parameter		Value
--------------------------------------------------------------------------
mgmtd	beegfs-mgmtd.conf	storeMgmtDirectory	/data/beegfs-mgmtd

meta	beegfs-meta.conf	sysMgmtdHost		bgmgmtd
				storeMetaDirectory	/data/beegfs-meta

storage	beefs-storage.conf	sysMgmtdHost		bgmgmtd
				storeStorageDirectory	/data/beegfs-storage

client	beegfs-client.conf	sysMgmtdHost		bgmgmtd
	beegfs-mount.conf	default settings are ok, /mnt is handled

admon	beegfs-meta.conf	sysMgmtdHost		bgmgmtd
```

<!------------------------------------------------------------------------>
---
### 4. Resync all systems

https://www.beegfs.io/wiki/ManualInstallWalkThrough#service_startup

Final client startup can take tens of seconds.
```
$ ssh bgmgmtd systemctl restart beegfs-mgmtd

$ ssh bgmeta systemctl restart beegfs-meta

$ ssh bgstorage1 systemctl restart beegfs-storage
$ ssh bgstorage2 systemctl restart beegfs-storage

$ ssh bgclient1 systemctl restart beegfs-helperd
$ ssh bgclient2 systemctl restart beegfs-helperd

$ ssh bgclient1 systemctl restart beegfs-client
$ ssh bgclient2 systemctl restart beegfs-client

$ ssh bgadmon systemctl restart beegfs-admon
```
