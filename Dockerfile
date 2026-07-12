FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --yes --no-install-recommends \
        automake \
        autotools-dev \
        bsdmainutils \
        build-essential \
        ca-certificates \
        libboost-chrono-dev \
        libboost-filesystem-dev \
        libboost-program-options-dev \
        libboost-system-dev \
        libboost-test-dev \
        libboost-thread-dev \
        libdb5.3++-dev \
        libevent-dev \
        libssl-dev \
        libtool \
        pkg-config \
        python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
COPY . .

RUN ./autogen.sh \
    && ./configure --with-gui=no --disable-bench --disable-man \
    && make -j"$(nproc)" \
    && make check -j"$(nproc)" VERBOSE=1 \
    && make install DESTDIR=/opt/dogecoin

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install --yes --no-install-recommends \
        ca-certificates \
        libboost-chrono1.83.0t64 \
        libboost-filesystem1.83.0 \
        libboost-program-options1.83.0 \
        libboost-system1.83.0 \
        libboost-thread1.83.0 \
        libdb5.3++t64 \
        libevent-2.1-7t64 \
        libevent-pthreads-2.1-7t64 \
        libssl3t64 \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 dogecoin

COPY --from=builder /opt/dogecoin/usr/local/ /usr/local/

RUN dogecoind --version \
    && dogecoind -help | grep -q -- '-disablewallet' \
    && dogecoin-cli --version \
    && dogecoin-tx -help

USER dogecoin
VOLUME ["/home/dogecoin/.dogecoin"]
EXPOSE 22555 22556 44555 44556 18444 18332

ENTRYPOINT ["dogecoind"]
CMD ["-printtoconsole"]
