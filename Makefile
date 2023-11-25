
DEVICES:=$(wildcard [a-z]*)

MOUNTED:=$(subst /,,$(dir $(wildcard [a-z]*/.git)))
NOTMOUNTED:=$(subst /,,$(dir $(wildcard [a-z]*/.unmounted)))

.PHONY: mount umount

mount: $(addsuffix /.git,${NOTMOUNTED})

umount: $(addsuffix /.unmounted,${MOUNTED})

%/.git:
	mount $*

%/.unmounted:
	umount $*

mounted:
	@for d in ${DEVICES}; do \
		test -f $$d/.unmounted &&\
		printf ' %s\n' $$d ||\
		printf '+%s\n' $$d ; done

ssh:
	@test -n "${TODO}" || ( echo '*** You must provide TODO ***' && false )
	@for d in ${DEVICES}; do ssh $$d ${TODO} | sed 's/^/'$$d': /' ; done

versions: TODO = grep VERSION= /etc/os-release
versions: ssh

new:
	./SCRIPTS/new_device

