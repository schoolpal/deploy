version: '3'
services:
  nginx:
    image: bj.dinner3000.com:5000/nginx-dev:latest
    ports:
      - "72:80"
    volumes:
      - /opt/schoolpal/src/site/target:/usr/share/nginx/html:ro
      - /opt/schoolpal/deploy/docker_images/nginx-dev/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - web
  web:
    image: bj.dinner3000.com:5000/web:latest
    ports:
      - "7280:8080"
    depends_on:
      - db
      - redis
  redis:
    image: bj.dinner3000.com:5000/redis-singleton:latest
  db:
    image: bj.dinner3000.com:5000/db:latest
