
DEVICES:=$(wildcard [a-z]*)

MOUNTED:=$(subst /,,$(dir $(wildcard [a-z]*/.git)))
NOTMOUNTED:=$(subst /,,$(dir $(wildcard [a-z]*/.unmounted)))

.PHONY: mount umount mounted ssh versions new reload_%

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

status:
	@for d in ${DEVICES}; do \
		test -f $$d/.unmounted &&\
		printf 'not mounted: %s\n' $$d ||\
		(printf '\n##### %s #####\n' $$d && git -C $$d status || true) ; done

ssh:
	@test -n "${TODO}" || ( echo '*** You must provide TODO ***' && false )
	@for d in ${DEVICES}; do ssh $$d ${TODO} | sed 's/^/'$$d': /' ; done

versions: TODO = grep VERSION= /etc/os-release
versions: ssh

reload_%:
	@make TODO="service $* reload" ssh

new:
	./SCRIPTS/new_device

