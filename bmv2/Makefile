SHELL = bash
SRC=basic_mirror

.PHONY: all clean

all: ${SRC}.json

${SRC}.json: ${SRC}.p4
	docker run --rm \
		--user $(shell id -u):$(shell id -g) \
		-v $(shell pwd):/tmp/src \
		gitlab.inf.elte.hu:5050/p4/aqm/p4c p4c --target bmv2 --arch v1model --std p4-16\
			-o /tmp/src/${SRC} /tmp/src/${SRC}.p4

clean:
	-rm -rf $(SRC)

