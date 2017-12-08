.PHONY: build dev nuke super-nuke upload

TAG ?= c7fb6660d096

help:
	@cat Makefile

update-tag:
	./update-dockerfile-includes $(TAG)

build:
	docker build -t jupyter/demo .

dev: ARGS?=
dev:
	docker run --rm -it -p 8889:8888 jupyter/demo $(ARGS)

upload:
	docker tag jupyter/demo jupyter/demo:$(TAG)
	docker push jupyter/demo
	docker push jupyter/demo:$(TAG)

super-nuke: nuke
	-docker rmi jupyter/demo

# Cleanup with fangs
nuke:
	-docker stop `docker ps -aq`
	-docker rm -fv `docker ps -aq`
	-docker images -q --filter "dangling=true" | xargs docker rmi

