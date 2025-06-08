FROM alpine:3.14 AS install-deps

RUN apk update && \
    apk add --no-cache alpine-sdk boost-dev bzip2-dev gmp-dev zlib-dev \
    libbz2 mariadb-connector-c-dev cmake

FROM install-deps AS build

WORKDIR /app

COPY . .

WORKDIR /app/bncsutil
RUN mkdir build && \
    cmake -G "Unix Makefiles" -B./build -H./ && \
    cd build && make && make install

WORKDIR /app/StormLib
RUN mkdir build && \
    cmake -G "Unix Makefiles" -B./build -H./ && \
    cd build && make && make install

WORKDIR /app/CascLib
RUN mkdir build && \
    cmake -G "Unix Makefiles" -B./build -H./ && \
    cd build && make && make install

WORKDIR /app/ghost
RUN make

FROM alpine:3.14 AS final

LABEL version="1.5.4"
LABEL author="Fatorin"
LABEL description="Support for Warcraft III 1.28f."

WORKDIR /app

COPY --from=build /app/ghost/ghost++ /app/ghost++
COPY --from=build /usr/local/lib/ /usr/local/lib/
COPY --from=build /usr/local/include/ /usr/local/include/
COPY --from=build /usr/lib/libboost_filesystem.so.1.76.0 /usr/lib/
COPY --from=build /usr/lib/libboost_thread.so.1.76.0 /usr/lib/
COPY --from=build /usr/lib/libstdc++.so.6 /usr/lib/
COPY --from=build /usr/lib/libgcc_s.so.1 /usr/lib/
COPY --from=build /app/config/ /app/

RUN apk update && apk add --no-cache bzip2 gmp zlib libbz2 mariadb-connector-c

CMD ["/app/ghost++"]
