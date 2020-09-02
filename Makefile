DOCKER_REGISTRY := bhiravabhatla
IMAGE_NAME := jaeger-es-rollover-init
IMAGE_TAG := 1.0
ROLLOVER_IMAGE_VERSION := latest

build:
	 docker image build . --no-cache --build-arg ROLLOVER_IMAGE_VERSION=$(ROLLOVER_IMAGE_VERSION) -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

run:
	docker run -it --rm --net=host bhiravabhatla/jaeger-es-rollover-init:latest init $(ES_HOST)

publish:
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)