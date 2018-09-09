ARG GODOT_VERSION=3.0.6
FROM ubuntu:18.04 AS baseimg
RUN apt-get update && \
	apt-get -y upgrade

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

RUN apt-get -y install ca-certificates gnupg2
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
	echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | tee /etc/apt/sources.list.d/mono-official-stable.list && \
	apt-get update && \
	apt-get -y install mono-complete msbuild wget

FROM baseimg AS build
ARG GODOT_VERSION
RUN apt-get -y install build-essential scons pkg-config libx11-dev libxcursor-dev libxinerama-dev \
	libgl1-mesa-dev libglu-dev libasound2-dev libpulse-dev libfreetype6-dev libssl-dev libudev-dev \
	libxi-dev libxrandr-dev mingw-w64

RUN mkdir -p /build/godot-src && \
	cd /build/godot-src && \
	wget "https://github.com/godotengine/godot/archive/${GODOT_VERSION}-stable.tar.gz" -O "src.tar.gz" && \
	tar -xzf src.tar.gz

RUN	cd /build/godot-src/godot-${GODOT_VERSION}-stable && \
	scons -j 6 platform=server target=release_debug tools=yes bits=64 module_mono_enabled=yes mono_glue=no && \
	bin/godot_server.server.opt.tools.64.mono --generate-mono-glue modules/mono/glue && \
	scons -j 6 platform=server target=release_debug tools=yes bits=64 module_mono_enabled=yes

RUN cd /build/godot-src/godot-${GODOT_VERSION}-stable && \
	scons -j 6 platform=x11 target=release_debug tools=no bits=64 module_mono_enabled=yes && \
	scons -j 6 platform=x11 target=release tools=no bits=64 module_mono_enabled=yes

RUN mkdir -p /build/bin && \
	cp /build/godot-src/godot-${GODOT_VERSION}-stable/bin/* /build/bin

FROM baseimg
ARG GODOT_VERSION

LABEL mantainer="Sophie Tauchert <sophie@999eagle.moe>"

WORKDIR /build
COPY --from=build /build/bin /build
RUN ln -s godot_server.server.opt.tools.64.mono godot
RUN cp godot.x11.debug.64.mono data/godot/templates/${GODOT_VERSION}.stable.mono/linux_x11_64_debug
RUN cp godot.x11.opt.64.mono data/godot/templates/${GODOT_VERSION}.stable.mono/linux_x11_64_release

ENV XDG_CACHE_HOME /build/cache
ENV XDG_CONFIG_HOME /build/config
ENV XDG_DATA_HOME /build/data
RUN mkdir -p ${XDG_CACHE_HOME} && mkdir -p ${XDG_CONFIG_HOME} && mkdir -p ${XDG_DATA_HOME}
