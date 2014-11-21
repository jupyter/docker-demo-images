images: demo-image minimal-image

demo-image: Dockerfile
	docker build -t jupyter/demo .

minimal-image: common/Dockerfile
	docker build -t jupyter/minimal common/

cleanup:
	-docker stop `docker ps -aq`
	-docker rm   `docker ps -aq`
	-docker images -q --filter "dangling=true" | xargs docker rmi

.PHONY: cleanup
