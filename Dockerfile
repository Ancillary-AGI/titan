# Multi-stage Dockerfile for Titan Browser

# Stage 1: Rust engine build
FROM rust:1.75 as rust-builder

WORKDIR /app/rust_engine
COPY rust_engine/ .

# Build Rust engine
RUN cargo build --release

# Stage 2: Flutter build
FROM ubuntu:22.04 as flutter-builder

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

# Enable Linux desktop
RUN flutter config --enable-linux-desktop

WORKDIR /app

# Copy Flutter project
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Copy Rust engine artifacts
COPY --from=rust-builder /app/rust_engine/target/release/ ./rust_engine/target/release/

# Build Flutter app
RUN flutter build linux --release

# Stage 3: Runtime
FROM ubuntu:22.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libgtk-3-0 \
    libblkid1 \
    liblzma5 \
    && rm -rf /var/lib/apt/lists/*

# Create app user
RUN useradd -m -s /bin/bash titan

WORKDIR /app

# Copy built application
COPY --from=flutter-builder /app/build/linux/x64/release/bundle/ .

# Set ownership
RUN chown -R titan:titan /app

USER titan

# Expose port for web interface (if needed)
EXPOSE 8080

# Run the application
CMD ["./titan_browser"]