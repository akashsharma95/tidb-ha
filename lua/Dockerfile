FROM haproxy:2.3-alpine
RUN apk update
RUN apk add luarocks5.3 git mariadb-dev lua5.3-dev gcc musl-dev
RUN ln -s /usr/bin/luarocks-5.3 /usr/bin/luarocks
RUN luarocks install luasql-mysql MYSQL_INCDIR=/usr/include/mysql/
COPY lagcheck.lua /usr/local/etc/haproxy/lagcheck.lua
COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
