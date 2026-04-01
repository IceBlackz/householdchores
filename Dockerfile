# ============================================================
# Stage 1 — Build the Flutter web app
# ============================================================
# Uses the official cirruslabs Flutter image.
# Pin to a specific tag for reproducible builds, e.g.:
#   ghcr.io/cirruslabs/flutter:3.29.0
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app

# Copy dependency manifests first so Docker can cache the pub get layer.
# This layer is only invalidated when pubspec files change.
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get

# Copy the rest of the source.
# .dockerignore excludes .dart_tool/ so package_config.json is
# freshly generated above with correct Linux paths — not copied
# from the Windows host where it contains C:\Users\... paths.
COPY frontend/ .

# Explicitly generate l10n files before building.
# The generated app_localizations*.dart files are excluded by
# .dockerignore so this always produces a clean Linux build.
RUN flutter gen-l10n

# Build the release web app
RUN flutter build web --release

# ============================================================
# Stage 2 — Serve with nginx
# ============================================================
FROM nginx:alpine

# Files are owned by root inside the image — no permission issues.
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY backend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80