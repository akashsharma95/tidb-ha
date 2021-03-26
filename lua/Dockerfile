FROM haproxy:2.3-alpine
RUN apk update && apk add git unzip luarocks && luarocks install luasql-mysql
COPY lagcheck.lua /usr/local/etc/haproxy/lagcheck.lua
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
