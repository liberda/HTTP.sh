FROM alpine:3.21

RUN apk upgrade -U && apk add bash sed grep nmap-ncat socat file findutils jq curl argon2

WORKDIR /app
COPY . .

EXPOSE 1337
VOLUME /app/app
VOLUME /app/config
VOLUME /app/storage
VOLUME /app/secret

CMD ["/app/http.sh"]
