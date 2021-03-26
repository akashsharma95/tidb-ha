# launch mysql primary
docker run -d --name mysql-primary -p 3306:3306 -e ALLOW_EMPTY_PASSWORD=yes bitnami/mysql:latest

# launch mysql secondary
docker run -d --name mysql-secondary -p 3306:3306 -e ALLOW_EMPTY_PASSWORD=yes bitnami/mysql:latest

# build haproxy image
docker build -t haproxy -f Dockerfile .

# run ha-proxy
docker run -d --name mysql-haproxy-lb --link mysql-primary:mysql-primary --link mysql-secondary:mysql-secondary haproxy:latest