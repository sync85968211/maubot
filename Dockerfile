FROM node:20 AS frontend-builder

COPY ./maubot/management/frontend /frontend
RUN cd /frontend && yarn --prod && yarn build

FROM alpine:3.20

# Install ffmpeg and additional libraries
RUN apk add --no-cache \
        ffmpeg \
        x265-libs \
        libwebp \
        fdk-aac \
        libzmq \
        libopenmpt \
        libass \
        libdav1d \
        libmodplug \
        libvpx \
        x264-libs \
        curl

# Download and install the latest stable version of yt-dlp from GitHub
RUN curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp \
    && mkdir -p /media_tmp \
    && chmod -R a=rw /media_tmp

RUN apk add --no-cache \
        python3 py3-pip py3-setuptools py3-wheel \
        ca-certificates \
        su-exec \
        yq \
        py3-aiohttp \
        py3-attrs \
        py3-bcrypt \
        py3-cffi \
        py3-ruamel.yaml \
        py3-jinja2 \
        py3-click \
        py3-packaging \
        py3-markdown \
        py3-alembic \
        py3-cssselect \
        py3-commonmark \
        py3-pygments \
        py3-tz \
        py3-regex \
        py3-wcwidth \
        # encryption
        py3-cffi \
        py3-olm \
        py3-pycryptodome \
        py3-unpaddedbase64 \
        py3-future \
        # plugin deps
        py3-pillow \
        py3-magic \
        py3-feedparser \
        py3-dateutil \
        py3-lxml \
        py3-semver
# TODO remove pillow, magic, feedparser, lxml, gitlab and semver when maubot supports installing dependencies

COPY requirements.txt /opt/maubot/requirements.txt
COPY optional-requirements.txt /opt/maubot/optional-requirements.txt
WORKDIR /opt/maubot
RUN apk add --virtual .build-deps python3-dev build-base git \
    && pip3 install --break-system-packages -r requirements.txt -r optional-requirements.txt \
        dateparser langdetect python-gitlab pyquery tzlocal \
    && apk del .build-deps
# TODO also remove dateparser, langdetect and pyquery when maubot supports installing dependencies

COPY . /opt/maubot
RUN cp maubot/example-config.yaml .
COPY ./docker/mbc.sh /usr/local/bin/mbc
COPY --from=frontend-builder /frontend/build /opt/maubot/frontend
ENV UID=1337 GID=1337 XDG_CONFIG_HOME=/data
VOLUME /data

CMD ["/opt/maubot/docker/run.sh"]
