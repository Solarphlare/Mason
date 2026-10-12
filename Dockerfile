FROM debian:latest AS build

WORKDIR /tmp/depbuild

RUN apt-get update && apt-get install -y \
    curl \
    build-essential \
    make \
    cmake \
    pkg-config \
    libopus0 \
    git \
    libssl-dev \
    libopus-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists

RUN if [ "$(uname -m)" = "aarch64" ]; then \
        curl -fL https://dl.dpp.dev/latest/linux-rpi-arm64 -o dpp.deb; \
    else \
        curl -fL https://dl.dpp.dev -o dpp.deb; \
    fi && \
    dpkg -i dpp.deb

RUN curl -OL https://github.com/mongodb/mongo-cxx-driver/releases/download/r4.5.3/mongo-cxx-driver-r4.5.3.tar.gz && \
    tar -xzf mongo-cxx-driver-r4.5.3.tar.gz

WORKDIR /tmp/depbuild/mongo-cxx-driver-r4.5.3/build

RUN cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17

RUN cmake --build . && cmake --build . --target install

WORKDIR /tmp/build

COPY . .

RUN make -j4

FROM debian:latest AS runner

COPY --from=build /tmp/depbuild/dpp.deb /tmp/dpp.deb

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates /tmp/dpp.deb \
    && rm -f /tmp/dpp.deb \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /tmp/build/mason /opt/mason

RUN echo "/usr/local/lib" | tee /etc/ld.so.conf.d/local.conf
RUN ldconfig

ENTRYPOINT ["/opt/mason"]
