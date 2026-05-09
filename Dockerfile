FROM ghcr.io/cirruslabs/flutter:stable AS web-builder

WORKDIR /app

# Copy dependency manifests first so Docker can cache the pub get layer.
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

# Copy the rest of the frontend source and generate localizations.
COPY frontend/ .
RUN flutter gen-l10n

# Build the release web app.
RUN flutter build web --release

FROM nginx:alpine AS web

COPY --from=web-builder /app/build/web /usr/share/nginx/html
COPY backend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

FROM alpine:latest AS pocketbase

ARG PB_VERSION=0.38.0

RUN apk add --no-cache \
    ca-certificates \
    unzip

ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pocketbase.zip
RUN unzip /tmp/pocketbase.zip -d /pb/ && rm /tmp/pocketbase.zip

WORKDIR /pb

COPY backend/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9010

ENTRYPOINT ["/entrypoint.sh"]
