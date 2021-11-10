FROM alpine:3.14

RUN apk update \
 && apk add sed xxd grep findutils file nmap-ncat socat jq bash file curl

WORKDIR /httpsh
COPY . .

EXPOSE 1337
VOLUME /httpsh/config
VOLUME /httpsh/app
VOLUME /httpsh/storage
VOLUME /httpsh/secret

CMD ["/httpsh/http.sh"]
