DOCKER_REGISTRY := bhiravabhatla
IMAGE_NAME := jaeger-es-rollover-init
IMAGE_TAG := 1.1
ROLLOVER_IMAGE_VERSION := latest

build:
	 docker image build . --no-cache --build-arg ROLLOVER_IMAGE_VERSION=$(ROLLOVER_IMAGE_VERSION) -t $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

init:
	docker run -it --rm --net=host bhiravabhatla/jaeger-es-rollover-init:latest init $(ES_HOST) $(ILM_POLICY)

publish: build
	docker push $(DOCKER_REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)