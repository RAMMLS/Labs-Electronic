FROM gradle:8.7-jdk8 AS builder

ARG CIRCUITJS_COMMIT=5bdb1296ce6a82f79515f4f1dd1b9a86e03236f7

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/pfalstad/circuitjs1.git /src \
    && git -C /src checkout "${CIRCUITJS_COMMIT}"

WORKDIR /src
RUN gradle compileGwt --console plain --no-daemon \
    && gradle makeSite --console plain --no-daemon

FROM nginx:1.27-alpine

COPY --from=builder /src/site/ /usr/share/nginx/html/
COPY circuits/ /usr/share/nginx/html/circuitjs1/circuits/
COPY web/index.html /usr/share/nginx/html/index.html
COPY web/test.html /usr/share/nginx/html/test.html
COPY web/service-worker.js /usr/share/nginx/html/service-worker.js
COPY web/nginx.conf /etc/nginx/conf.d/default.conf

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD wget -q -O /dev/null http://127.0.0.1/health || exit 1
