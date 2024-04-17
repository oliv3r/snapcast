# SPDX-License-Identifier: GPL-3.0-or-later
#
# Copyright (C) 2024 Olliver Schinagl <oliver@schinagl.nl>

ARG ALPINE_VERSION="latest"
ARG TARGET_ARCH="library"

FROM docker.io/${TARGET_ARCH}/alpine:${ALPINE_VERSION} AS builder

WORKDIR /src

COPY . /src/

RUN apk add --no-cache \
        'alsa-lib-dev' \
        'avahi-dev' \
        'boost-dev' \
        'cmake' \
        'expat-dev' \
        'flac-dev' \
        'g++' \
        'libvorbis-dev' \
        'opus-dev' \
        'samurai' \
        'soxr-dev' \
    && \
    cmake -B '.build' -G Ninja \
          -DCMAKE_BUILD_TYPE=None \
          -DCMAKE_INSTALL_PREFIX='/usr' \
          -DCMAKE_INSTALL_SYSCONFDIR='/etc' \
          -DBUILD_WITH_AVAHI=ON \
          -DBUILD_WITH_EXPAT=ON \
          -DBUILD_WITH_FLAC=ON \
          -DBUILD_WITH_OPUS=ON \
          -DBUILD_WITH_PULSE=ON \
          -DBUILD_WITH_TREMOR=ON \
          -DBUILD_WITH_VORBIS=ON \
          -DBUILD_TESTS=ON \
    && \
    cmake --build '.build' -j $(($(nproc) - 1)) && \
    './bin/snapcast_test' && \
    DESTDIR='/snapcast/server' cmake --install '.build' && \
    mkdir -p '/snapcast/client/usr/bin' && \
    mv '/snapcast/server/usr/bin/snapclient' '/snapcast/client/usr/bin/' && \
    mkdir -p '/snapcast/server/var/lib/snapserver' && \
    mv '/snapcast/server/etc/snapserver.conf' '/snapcast/server/var/lib/snapserver/snapserver.conf' && \
    ln -s '/var/lib/snapserver/snapserver.conf' '/snapcast/server/etc/snapserver.conf' && \
    rm -f -r '/snapcast/server/usr/share/man'


FROM docker.io/${TARGET_ARCH}/alpine:${ALPINE_VERSION} AS snapclient

LABEL maintainer="Olliver Schinagl <oliver@schinagl.nl>"

RUN apk add --no-cache \
        'alsa-lib' \
        'avahi-libs' \
        'dbus-libs' \
        'libflac' \
        'libgcc' \
        'libgomp' \
        'libintl' \
        'libogg' \
        'libstdc++' \
        'libvorbis' \
        'opus' \
        'soxr' \
        'tini' \
    && \
    addgroup -S 'snapcast' && \
    adduser -D -G 'snapcast' -h '/tmp' -s '/bin/nologin' -S 'snapcast' && \
    adduser 'snapcast' 'audio' && \
    adduser 'snapcast' 'usb'

COPY --from=builder "/snapcast/client/" "/"
COPY "./extras/container/snapclient-entrypoint.sh" "/init"

USER snapcast

ENTRYPOINT [ "/sbin/tini", "--", "/init" ]


FROM docker.io/${TARGET_ARCH}/alpine:${ALPINE_VERSION} AS snapserver

LABEL maintainer="Olliver Schinagl <oliver@schinagl.nl>"

EXPOSE 1704 \
       1705 \
       1780 \
       4953 \
       5000 \
       7000

COPY --from=builder "/snapcast/server" "/"

RUN apk add --no-cache \
        'alsa-lib' \
        'avahi-libs' \
        'dbus-libs' \
        'git' \
        'libexpat' \
        'libflac' \
        'libgcc' \
        'libgomp' \
        'libintl' \
        'libogg' \
        'libstdc++' \
        'libvorbis' \
        'opus' \
        'shairport-sync' \
        'socat' \
        'soxr' \
        'tini' \
    && \
    apk add --no-cache \
        --repository="$(sed '1 s|^\(.*alpine/\)\(.*\)$|\1edge/testing|;2,$d' "/etc/apk/repositories")" \
        'librespot' \
    && \
    addgroup -S 'snapserver' && \
    adduser -D -G 'snapserver' -h '/var/lib/snapserver/' -s '/bin/nologin' -S 'snapserver' && \
    chown -R 'snapserver:snapserver' '/var/lib/snapserver' && \
    install -d -m 775 -g 'snapserver' -o 'snapserver' '/var/lib/snapserver/.config' && \
    ln -s '..' '/var/lib/snapserver/.config/snapserver' && \
    install -d -m 775 -g 'snapserver' -o 'snapserver' '/var/run/snapcast/' && \
    install -d -m 775 -g 'snapserver' -o 'snapserver' '/var/run/snapserver/' && \
    sed -i \
        -e 's|^#codec = flac|codec = pcm|g' \
        -e 's|^#datadir = $|datadir = /var/lib/snapserver|g' \
        -e 's|^#enabled = true$|enabled = true|g' \
        -e 's|^#group = snapserver$|group = snapserver|g' \
        -e 's|^#port =|port =|g' \
        -e 's|^#user = snapserver$|user = snapserver|g' \
        -e 's|^source = pipe:///tmp/|source = pipe:///var/run/snapcast/|g' \
        -e '/^source = pipe:/a source = tcp://0.0.0.0:4953?name=snapserver&mode=server' \
        -e '/^source = pipe:/a #source = airplay1' \
        -e '/^source = pipe:/a #source = airplay2' \
        -e '/^source = pipe:/a #source = librespot' \
        '/var/lib/snapserver/snapserver.conf'

COPY "./extras/container/snapserver-entrypoint.sh" "/init"

VOLUME /var/run/snapcast
VOLUME /var/lib/snapserver
WORKDIR /var/lib/snapserver
USER snapserver

ENTRYPOINT [ "/sbin/tini", "--", "/init" ]
