FROM alpine:3.14

RUN apk update \
 && apk add sed xxd grep findutils file nmap-ncat socat jq bash file curl

WORKDIR /app
COPY . .

EXPOSE 1337
VOLUME /app/config
VOLUME /app/app

ENTRYPOINT /app/http.sh
