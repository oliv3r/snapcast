#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Copyright (C) 2023 Olliver Schinagl <oliver@schinagl.nl>
#
# A beginning user should be able to docker run image bash (or sh) without
# needing to learn about --entrypoint
# https://github.com/docker-library/official-images#consistency

set -eu

bin='snapserver'
conf='/etc/snapserver.conf'

if [ -s '/var/lib/snapserver/snapserver.conf' ]; then
	conf='/var/lib/snapserver/snapserver.conf'
fi

airplay1_keep='true'
if [ -n "${AIRPLAY1_REPLACE:-}" ]; then
	unset airplay1_keep
fi

airplay2_keep='true'
if [ -n "${AIRPLAY2_REPLACE:-}" ]; then
	unset airplay2_keep
fi

librespot_keep='true'
if [ -n "${LIBRESPOT_REPLACE:-}" ]; then
	unset librespot_keep
fi

sed \
    -e '/#Dummy placeholder/d' \
    ${AIRPLAY1:+-e "s|^${airplay1_keep:+#}source = airplay1|source = airplay:///usr/bin/shairport-sync?name=${AIRPLAY1}|g"} \
    ${AIRPLAY2:+-e "s|^${airplay2_keep:+#}source = airplay2|source = airplay:///usr/bin/shairport-sync?name=${AIRPLAY2}|g"} \
    ${LIBRESPOT:+-e "s|^${librespot_keep:+#}source = librespot|source = librespot:///usr/bin/librespot?name=${LIBRESPOT}|g"} \
"${conf}" > '/var/run/snapserver/snapserver.conf'

# run command if it is not starting with a "-" and is an executable in PATH
if [ "${#}" -le 0 ] || \
   [ "${1#-}" != "${1}" ] || \
   [ -d "${1}" ] || \
   ! command -v "${1}" > '/dev/null' 2>&1; then
	entrypoint='true'

	bin="${bin} --config /var/run/snapserver/snapserver.conf"
fi

exec ${entrypoint:+${bin:?}} "${@}"

exit 0
