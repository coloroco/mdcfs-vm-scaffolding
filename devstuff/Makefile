# asdf

ifeq (${DIR_BASE},)
$(error You forgot to set DIR_BASE)
endif

DIR:=$(shell dirname ${DIR_BASE})
BASE:=$(shell basename ${DIR_BASE})

ifneq ($(shell test -d ${DIR} && echo yes || echo no), yes)
$(error Directory ${DIR} does not exist)
endif

NET:=${BASE}
SUFFIX:=a
ORIGDOM:=${BASE}${SUFFIX}
ORIGQCOW2:=${DIR}/${ORIGDOM}.qcow2
ORIGBLOCK:=${DIR}/block${SUFFIX}.img

INSTALLER:=http://ftp.us.debian.org/debian/dists/buster/main/installer-amd64/
# see output of "osinfo-query os"
VARIANT:=debiantesting

echoenv:
	junk=ORIGDOM; echo $${!junk}

asdf:
	for V in BASE NET SUFFIX ORIGDOM ORIGQCOW2 ORIGBLOCK; do \
		echo $${V} = $${$${V}} ; \
	done ; return 0

# virt-clone walks domain disks in order (virsh dumpxml xxxxa) as
# source for the new copies.

orig:
	@# Keep stderr for the failure message
	@`virsh net-info ${NET} >&-` || exit 1
	@[ -f ${ORIGQCOW2} ] || qemu-img create -f qcow2 ${ORIGQCOW2} 4G
	@[ -f ${ORIGBLOCK} ] || fallocate -l 128M ${ORIGBLOCK}
	@# This will fail if domain is already declared
	virt-install --name ${ORIGDOM} \
		--virt-type kvm --vcpus 2 --ram 1024 \
		--disk path=${ORIGQCOW2},bus=virtio,format=qcow2 \
		--disk path=${ORIGBLOCK},bus=virtio,format=raw \
		--network network=${NET} --location ${INSTALLER} \
		--os-type linux --os-variant ${VARIANT} \
		--graphics spice --video qxl --channel spicevmc

clones:
	for C in b c d; do \
	    CLONE=${BASE}${C} ;\
	    set ;\
	    continue ;\
	    NEWQCOW2=${DIR}/${CLONE}.qcow2 ;\
	    NEWBLOCK=${DIR}/block${SUFFIX}.img ;\
	    virt-clone -o ${ORIGQCOW2} -n ${CLONE} -f ${NEWQCOW2} -f ${NEWBLOCK} ;\
	    sudo chmod +r ${NEWQCOW2} ${NEWBLOCK} ;\
	    sudo virt-sysprep -d ${CLONE} --hostname ${CLONE} \
		--operations dhcp-client-state,customize --hostname ;\
	done
