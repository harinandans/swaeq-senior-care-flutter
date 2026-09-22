# syntax=docker/dockerfile:1
#
# SwaEQ Senior Care → Android APK for linux/amd64 (AWS x86).
#
# Transfer this folder to an x86 server, then:
#   docker build -t swaeq-senior-apk .
#   docker build --build-arg API_BASE_URL=https://your-api.example.com -t swaeq-senior-apk .
#
# Extract APK:
#   docker run --rm -v "$PWD:/host" swaeq-senior-apk \
#     cp /out/swaeq-senior.apk /host/swaeq-senior.apk

FROM --platform=linux/amd64 ghcr.io/cirruslabs/flutter:stable

ARG API_BASE_URL=https://5on0mm6m5d.execute-api.ap-south-1.amazonaws.com

ENV DEBIAN_FRONTEND=noninteractive \
    PUB_CACHE=/root/.pub-cache \
    API_BASE_URL=${API_BASE_URL}

WORKDIR /app

COPY pubspec.yaml pubspec.lock ./
RUN flutter config --no-analytics \
 && flutter pub get

COPY . .

RUN flutter pub get \
 && flutter build apk --release \
      --dart-define=API_BASE_URL=${API_BASE_URL} \
 && mkdir -p /out \
 && cp build/app/outputs/flutter-apk/app-release.apk /out/swaeq-senior.apk \
 && ls -lh /out/swaeq-senior.apk

CMD ["ls", "-lh", "/out/swaeq-senior.apk"]
