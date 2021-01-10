FROM alpine:3.12

RUN apk update \
 && apk add coreutils grep nmap-ncat socat jq bash file curl

WORKDIR /app
COPY . .

EXPOSE 1337
VOLUME /app/config
VOLUME /app/app

ENTRYPOINT /app/http.sh
