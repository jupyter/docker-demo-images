images: minimal-image demo-image

minimal-image:
	docker build -t jupyter/minimal common/

demo-image: minimal-image
	docker build -t jupyter/demo .

# Cleanup with fangs
nuke:
	-docker stop `docker ps -aq`
	-docker rm -fv `docker ps -aq`
	-docker images -q --filter "dangling=true" | xargs docker rmi

.PHONY: nuke
