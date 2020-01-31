alias ll="ls -l"
alias lsf="ls -CF"
alias psg="ps -ef | fgrep -v ']$' | grep -i"

alias ma='make all'
alias mc='make clean'
alias mca='make clean all'

# Pass through some, to invoke dpkg-buildpackage -b -rfakeroot -us -uc -i
alias jfbi='debuild -i -uc -us -b && dh_clean'

export LIBVIRT_DEFAULT_URI=qemu:///system

alias sane='stty sane'

alias pep8='python3 /usr/lib/python3/dist-packages/pep8.py'

# export LIBVIRT_DEFAULT=qemu:///system
function virt-console() {
    nohup virt-viewer --connect qemu:///system $1 >/dev/null 2>&1 &
}

export CURRDB=~/4nodes512B.db
alias jfdi="sqlite3 \$CURRDB"

alias mountimg="sudo mount -oloop,offset=1M"

export EDITOR=vi
set -o vi

alias vstatus='virsh list --all'

function _vloopy() {
	RET=0
	CMD=$1
	shift
	while [ "$1" ]; do
		V $CMD $1
		[ $? -ne 0 ] && RET=1
		shift
	done
	return $RET
}

function vstart() {		# bash doesn't do one-liners
	_vloopy start $*
	return $?
}
function vdestroy() {
	_vloopy destroy $*
	return $?
}
function vrestart() {
	_vloopy destroy $*
	_vloopy start $*
	return $?
}

function vshutdown() {
	_vloopy shutdown $*
	return $?
}
