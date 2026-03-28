FROM alpine:latest

ARG PB_VERSION=0.36.8

RUN apk add --no-cache unzip ca-certificates

ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
RUN unzip /tmp/pb.zip -d /pb/

EXPOSE 9010

# Updated command for PocketBase v0.23+ (admin -> superuser)
CMD sh -c "/pb/pocketbase superuser upsert \"$ADMIN_EMAIL\" \"$ADMIN_PASSWORD\" || true ; /pb/pocketbase serve --http=0.0.0.0:9010"