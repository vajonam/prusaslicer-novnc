# ORIGINAL REPO  https://github.com/damanikjosh/virtualgl-turbovnc-docker/blob/main/Dockerfile 
ARG UBUNTU_VERSION=22.04

FROM nvidia/opengl:1.2-glvnd-runtime-ubuntu${UBUNTU_VERSION}
LABEL authors="vajonam, Michael Helfrich - helfrichmichael"

ARG VIRTUALGL_VERSION=3.1.1-20240228
ARG TURBOVNC_VERSION=3.1.1-20240127
ENV DEBIAN_FRONTEND noninteractive
ARG PUID=1000
ARG PGID=1000

# Install some basic dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget xorg xauth gosu supervisor x11-xserver-utils libegl1-mesa libgl1-mesa-glx \
    locales-all libpam0g libxt6 libxext6 dbus-x11 xauth x11-xkb-utils xkb-data python3 xterm novnc \
    lxde gtk2-engines-murrine gnome-themes-standard gtk2-engines-pixbuf gtk2-engines-murrine arc-theme \
    freeglut3 libgtk2.0-dev libwxgtk3.0-gtk3-dev libwx-perl libxmu-dev libgl1-mesa-glx libgl1-mesa-dri  \
    xdg-utils locales locales-all pcmanfm jq curl git bzip2 gpg-agent software-properties-common \
    # Packages needed to support the AppImage changes. The libnvidia-egl-gbm1 package resolves an issue 
    # where GPU acceleration resulted in blank windows being generated.
    libwebkit2gtk-4.0-dev libnvidia-egl-gbm1 \
    && mkdir -p /usr/share/desktop-directories \
    # Install Firefox without Snap.
    && add-apt-repository ppa:mozillateam/ppa \
    && apt update \
    && apt install -y firefox-esr --no-install-recommends \
    # Clean everything up.
    && apt autoclean -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# Install VirtualGL and TurboVNC
RUN wget -qO /tmp/virtualgl_${VIRTUALGL_VERSION}_amd64.deb https://packagecloud.io/dcommander/virtualgl/packages/any/any/virtualgl_${VIRTUALGL_VERSION}_amd64.deb/download.deb?distro_version_id=35\
    && wget -qO /tmp/turbovnc_${TURBOVNC_VERSION}_amd64.deb https://packagecloud.io/dcommander/turbovnc/packages/any/any/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download.deb?distro_version_id=35 \
    && dpkg -i /tmp/virtualgl_${VIRTUALGL_VERSION}_amd64.deb \
    && dpkg -i /tmp/turbovnc_${TURBOVNC_VERSION}_amd64.deb \
    && rm -rf /tmp/*.deb

# Install Prusaslicer.
WORKDIR /slic3r
ADD get_latest_orcalslicer_release.sh /slic3r
RUN chmod +x /slic3r/get_latest_orcalslicer_release.sh \
  && latestSlic3r=$(/slic3r/get_latest_orcalslicer_release.sh url) \
  && slic3rReleaseName=$(/slic3r/get_latest_orcalslicer_release.sh name) \
  && curl -sSL ${latestSlic3r} > ${slic3rReleaseName} \
  && rm -f /slic3r/releaseInfo.json \
  && chmod +x /slic3r/${slic3rReleaseName} \
  && /slic3r/${slic3rReleaseName} --appimage-extract \
  && rm -f /slic3r/${slic3rReleaseName} \
  && rm -rf /var/lib/apt/lists/* \
  && apt-get autoclean \
  && groupadd -g ${PGID} slic3r \
  && useradd -u ${PUID} -g slic3r --create-home --home-dir /home/slic3r slic3r \
  && mkdir -p /slic3r \
  && mkdir -p /configs \
  && mkdir -p /prints/ \
  && chown -R slic3r:slic3r /slic3r/ /home/slic3r/ /prints/ /configs/ \
  && locale-gen en_US \
  && mkdir /configs/.local \
  && mkdir -p /configs/.config/ \
  && ln -s /configs/.config/ /home/slic3r/ \
  && mkdir -p /home/slic3r/.config/ \
  && echo "XDG_DOWNLOAD_DIR=\"/prints/\"" >> /home/slic3r/.config/user-dirs.dirs \
  && echo "file:///prints prints" >> /home/slic3r/.gtk-bookmarks

# Generate key for noVNC and cleanup errors.
RUN openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/novnc.pem -out /etc/novnc.pem -days 365 -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=localhost" \
    && rm /etc/xdg/autostart/lxpolkit.desktop \
    && mv /usr/bin/lxpolkit /usr/bin/lxpolkit.ORIG

ENV PATH ${PATH}:/opt/VirtualGL/bin:/opt/TurboVNC/bin

ADD entrypoint.sh /entrypoint.sh
ADD supervisord.conf /etc/

# Add a default file to resize and redirect, and adjust icons for noVNC.
ADD vncresize.html /usr/share/novnc/index.html
ADD icons/prusaslicer-16x16.png /usr/share/novnc/app/images/icons/novnc-16x16.png
ADD icons/prusaslicer-24x24.png /usr/share/novnc/app/images/icons/novnc-24x24.png
ADD icons/prusaslicer-32x32.png /usr/share/novnc/app/images/icons/novnc-32x32.png
ADD icons/prusaslicer-48x48.png /usr/share/novnc/app/images/icons/novnc-48x48.png
ADD icons/prusaslicer-60x60.png /usr/share/novnc/app/images/icons/novnc-60x60.png
ADD icons/prusaslicer-64x64.png /usr/share/novnc/app/images/icons/novnc-64x64.png
ADD icons/prusaslicer-72x72.png /usr/share/novnc/app/images/icons/novnc-72x72.png
ADD icons/prusaslicer-76x76.png /usr/share/novnc/app/images/icons/novnc-76x76.png
ADD icons/prusaslicer-96x96.png /usr/share/novnc/app/images/icons/novnc-96x96.png
ADD icons/prusaslicer-120x120.png /usr/share/novnc/app/images/icons/novnc-120x120.png
ADD icons/prusaslicer-144x144.png /usr/share/novnc/app/images/icons/novnc-144x144.png
ADD icons/prusaslicer-152x152.png /usr/share/novnc/app/images/icons/novnc-152x152.png
ADD icons/prusaslicer-192x192.png /usr/share/novnc/app/images/icons/novnc-192x192.png
ADD lxde-rc.xml /home/slic3r/.config/openbox/lxde-rc.xml 
# Set Firefox to run with hardware acceleration as if enabled.
RUN sed -i 's|exec $MOZ_LIBDIR/$MOZ_APP_NAME "$@"|if [ -n "$ENABLEHWGPU" ] \&\& [ "$ENABLEHWGPU" = "true" ]; then\n  exec /usr/bin/vglrun $MOZ_LIBDIR/$MOZ_APP_NAME "$@"\nelse\n  exec $MOZ_LIBDIR/$MOZ_APP_NAME "$@"\nfi|g' /usr/bin/firefox-esr

VOLUME /configs/
VOLUME /prints/

ENTRYPOINT ["/entrypoint.sh"]
