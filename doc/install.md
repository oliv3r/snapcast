# Install Linux packages

Snapcast packages are available for several Linux distributions:

- [Containers](#containers)
- [Debian](#debian)
- [OpenWrt](#openwrt)
- [Alpine Linux](#alpine-linux)
- [Archlinux](#archlinux)
- [Void Linux](#void-linux)

## Containers

Snapcast containers can be used with container runtimes such as podman and
docker. Using [docker](https://docker.com) as example, running snapserver is
as simple as

```
docker run --rm --interactive --tty ghcr.io/badaix/snapcast/snapserver:latest
```

To properly use snapcast with avahi and the like, a few more volumes will be
needed, `/var/run/dbus` and `/var/run/avahi-daemon`. To share and expose the
snapcast fifo a volume for this is also needed, `/var/run/snapcast` is the
directory holding the fifo by default. Finally also
[snapweb](https://github.com/badaix/snapweb) can be made available using a
volume. To persist configuration another docker volume is required.

Editing configuration requires to edit the configuration files within the
persistent volume, and starting to container with the argument `/bin/sh` will
open a shell to the container, without starting `snapserver` itself. Thus a
full example would look like:

```
docker run --rm \
           --interactive \
           --tty \
           --volume /var/run/dbus:/var/run/dbus:rw \
           --volume /var/run/avahi-daemon:/var/run/avahi-daemon:rw \
           --volume snapweb:/usr/share/snapservert/snapweb \
           --volume snapserver:/var/lib/snapserver \
           --volume snapfifo:/var/run/snapcast \
           ghcr.io/badaix/snapcast/snapserver:latest /bin/sh
```

> __Note:__ Due to dockerization, it is not expected that anything on the host
> would want to access the snapfifo. To do so anyway, the snapfifo can also
> be a bind-mount instead, e.g. `--volume /var/run/snapcast:/var/run/snapcast`
> and can be used as `/var/run/snapcast/snapfifo` on the host as normal.

### Compose
Instead of manually running these things, compose can be used as well. A loose
compose file could be:

```yaml
networks:
  snapserver: {}

volumes:
  snapserver:
  snapfifo:
  snapweb:

services:
  snapweb:
    image: ghcr.io/badaix/snapweb/snapweb:latest
    volumes:
      - snapweb:/snapweb
    restart: no

  snapserver:
    image: ghcr.io/badaix/snapcast/snapserver:latest
    depends_on:
      - snapweb
    volumes:
      - /var/run/dbus:/var/run/dbus:rw
      - /var/run/avahi-daemon:/var/run/avahi-daemon:rw
      - snapweb:/usr/share/snapserver/snapweb
      - snapserver:/var/lib/snapserver
      - snapfifo:/var/run/snapcast
    networks:
      - snapserver
    ports:
      - "1704:1704/tcp"
      - "1705:1705/tcp"
      - "1780:1780/tcp"
      - "4953:4953/tcp"
      - "5000:5000/tcp"
      - "7000:7000/tcp"
    restart: unless-stopped
```

> __Note:__ Locking down the container using `cap_deny: all`, ulimits etc is
> left as an exercise to the reader.

## Debian

For Debian (and Debian-based systems, such as Ubuntu, Linux Mint, elementary OS) download the package for your CPU architecture from the [latest release page](https://github.com/badaix/snapcast/releases/latest).

e.g. for Raspberry Pi `snapclient_0.x.x_armhf.deb`, for laptops `snapclient_0.x.x_amd64.deb`

### using apt 1.1 or later

    sudo apt install </path/to/snapclient_0.x.x_[arch].deb>

or

    sudo apt install </path/to/snapserver_0.x.x_[arch].deb>

### using dpkg

Install the package:

    sudo dpkg -i </path/to/snapclient_0.x.x_[arch].deb>

or

    sudo dpkg -i </path/to/snapserver_0.x.x_[arch].deb>

Install missing dependencies:

    sudo apt-get -f install

## OpenWrt

On OpenWrt do:

    opkg install snapclient_0.x.x_ar71xx.ipk

## Alpine Linux

On Alpine Linux do:

    apk add snapcast

Or, for just the client:

    apk add snapcast-client

Or, for just the server:

    apk add snapcast-server

## Gentoo Linux

On Gentoo Linux do:

    emerge --ask media-sound/snapcast

## Archlinux

On Archlinux, Snapcast is available through the AUR.  To install, use your favorite AUR helper, or do:

    git clone https://aur.archlinux.org/snapcast
    cd snapcast
    makepkg -si

## Void Linux

To install the client:

    # xbps-install snapclient

To install the server:

    # xbps-install snapserver
