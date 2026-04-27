FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV FLUTTER_VERSION=3.22.0
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="${FLUTTER_HOME}/bin:${FLUTTER_HOME}/bin/cache/dart-sdk/bin:${PATH}"
ENV ANDROID_SDK_ROOT=/opt/android-sdk

# System dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} \
    https://github.com/flutter/flutter.git ${FLUTTER_HOME}

RUN flutter precache --web --no-android --no-ios
RUN flutter doctor --android-licenses || true
RUN flutter config --no-analytics

WORKDIR /app

COPY budget/pubspec.yaml budget/pubspec.lock ./
RUN flutter pub get

COPY budget/ .

EXPOSE 8080

CMD ["flutter", "run", "-d", "web-server", \
     "--web-port=8080", "--web-hostname=0.0.0.0"]
