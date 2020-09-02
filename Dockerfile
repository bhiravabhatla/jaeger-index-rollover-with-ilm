ARG ROLLOVER_IMAGE_VERSION
FROM jaegertracing/jaeger-es-rollover:${ROLLOVER_IMAGE_VERSION}
COPY esRollover.py /es-rollover/
COPY ./mappings/* /mappings/