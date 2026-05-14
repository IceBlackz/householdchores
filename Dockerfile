FROM ghcr.io/cirruslabs/flutter:stable AS web-builder

WORKDIR /app

# Copy dependency manifests first so Docker can cache the pub get layer.
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

# Copy the rest of the frontend source and generate localizations.
COPY frontend/ .
RUN flutter gen-l10n

# Build the release web app. The PWA service worker is disabled because stale
# offline app-shell caches can otherwise keep serving old Flutter builds.
RUN flutter build web --release --pwa-strategy=none && \
    APP_VERSION="$(grep '^version:' pubspec.yaml | awk '{print $2}' | tr -d '\r')" && \
    BUILD_ID="$(date -u +%Y%m%d%H%M%S)" && \
    printf '{"version":"%s","buildId":"%s","builtAt":"%s"}\n' "$APP_VERSION" "$BUILD_ID" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > build/web/version.json && \
    printf '%s\n' \
      'self.addEventListener("install", () => self.skipWaiting());' \
      'self.addEventListener("activate", (event) => {' \
      '  event.waitUntil((async () => {' \
      '    await self.registration.unregister();' \
      '    const clients = await self.clients.matchAll({ type: "window" });' \
      '    for (const client of clients) client.navigate(client.url);' \
      '  })());' \
      '});' \
      > build/web/flutter_service_worker.js

# Also build the Android APK and publish it through the web install page.
RUN flutter build apk --release && \
    mkdir -p build/web/downloads && \
    cp build/app/outputs/flutter-apk/app-release.apk build/web/downloads/householdchores-latest.apk

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

FROM nginx:alpine AS app

RUN apk add --no-cache ca-certificates

COPY --from=pocketbase /pb/pocketbase /pb/pocketbase
COPY backend/pb_migrations /pb/pb_migrations
COPY backend/pb_hooks /pb/pb_hooks
COPY --from=web-builder /app/build/web /usr/share/nginx/html
COPY backend/nginx.all-in-one.conf /etc/nginx/conf.d/default.conf
COPY backend/all-in-one-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/pb/pb_data"]
EXPOSE 80 9010

ENTRYPOINT ["/entrypoint.sh"]
