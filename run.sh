# launch mysql primary
docker run --rm -d --name mysql-primary -p 4000:3306 -e ALLOW_EMPTY_PASSWORD=yes bitnami/mysql:latest

# launch mysql secondary
docker run --rm -d --name mysql-secondary -p 4001:3306 -e ALLOW_EMPTY_PASSWORD=yes bitnami/mysql:latest

# build haproxy image
docker build -t haproxy -f Dockerfile .

# run ha-proxy
docker run --rm -d --name mysql-haproxy-lb --link mysql-primary:mysql-primary --link mysql-secondary:mysql-secondary -p 4002:4002 -p 8404:8404 haproxy:latest