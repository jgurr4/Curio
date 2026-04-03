ARG REVEAL_VERSION=5.2.1

FROM alpine:3.21 AS reveal_vendor
ARG REVEAL_VERSION

RUN apk add --no-cache curl tar

WORKDIR /tmp
RUN curl -fsSL "https://github.com/hakimel/reveal.js/archive/refs/tags/${REVEAL_VERSION}.tar.gz" -o reveal.tar.gz \
  && tar -xzf reveal.tar.gz \
  && mv reveal.js-* reveal.js

FROM nginx:alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . /usr/share/nginx/html
COPY --from=reveal_vendor /tmp/reveal.js/dist /usr/share/nginx/html/vendor/reveal.js/dist
COPY --from=reveal_vendor /tmp/reveal.js/plugin /usr/share/nginx/html/vendor/reveal.js/plugin
COPY --from=reveal_vendor /tmp/reveal.js/LICENSE /usr/share/nginx/html/vendor/reveal.js/LICENSE
