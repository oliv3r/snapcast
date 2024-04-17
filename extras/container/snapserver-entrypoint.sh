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

# run command if it is not starting with a "-" and is an executable in PATH
if [ "${#}" -le 0 ] || \
   [ "${1#-}" != "${1}" ] || \
   [ -d "${1}" ] || \
   ! command -v "${1}" > '/dev/null' 2>&1; then
	entrypoint='true'

	sed -i \
	    -e '/#Dummy placeholder/d' \
	    ${AIRPLAY1:+-e "s|^#source = airplay1|source = airplay:///usr/bin/shairport-sync?name=${AIRPLAY1}|g"} \
	    ${AIRPLAY2:+-e "s|^#source = airplay2|source = airplay:///usr/bin/shairport-sync?name=${AIRPLAY2}|g"} \
	    ${LIBRESPOT:+-e "s|^#source = librespot|source = librespot:///usr/bin/librespot?name=${LIBRESPOT}|g"} \
	'/var/lib/snapserver/snapserver.conf'
fi

exec ${entrypoint:+${bin:?}} "${@}"

exit 0
