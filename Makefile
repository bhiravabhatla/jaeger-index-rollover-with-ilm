DOCKER_REGISTRY := bhiravabhatla
IMAGE_NAME := jaeger-es-rollover-init
IMAGE_TAG := 1.2
ROLLOVER_IMAGE_VERSION := latest

build:
	 docker image build . --no-cache --build-arg ROLLOVER_IMAGE_VERSION=$(ROLLOVER_IMAGE_VERSION) -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

init:
	docker run -it -e INDEX_PREFIX="test" -e USE_ILM='true' --rm --net=host bhiravabhatla/jaeger-es-rollover-init:$(IMAGE_TAG) init $(ES_HOST)

publish: build
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)