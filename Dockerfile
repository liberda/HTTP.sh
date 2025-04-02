FROM alpine:3.21

RUN apk upgrade -U && apk add bash sed grep nmap-ncat socat file findutils jq curl argon2

WORKDIR /httpsh
COPY . .

EXPOSE 1337
VOLUME /httpsh/app
VOLUME /httpsh/config
VOLUME /httpsh/storage
VOLUME /httpsh/secret

CMD ["/httpsh/http.sh"]
