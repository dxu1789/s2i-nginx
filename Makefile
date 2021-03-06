
#IMAGE_NAME = flannon/s2i-nginx
#IMAGE_NAME = nginx-server
IMAGE_NAME = flannon/s2i-nginx

.PHONY: build
build:
	docker build -t $(IMAGE_NAME) .

.PHONY: test
test:
	docker build -t $(IMAGE_NAME)-candidate .
	IMAGE_NAME=$(IMAGE_NAME)-candidate test/run
