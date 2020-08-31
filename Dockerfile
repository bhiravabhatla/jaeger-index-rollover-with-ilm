FROM jaegertracing/jaeger-es-rollover
COPY esRollover.py /es-rollover/
COPY ./mappings/* /mappings/