FROM 999eagle/godot-mono-build-server:build-server AS build-server
FROM 999eagle/godot-mono-build-server:build-server AS build-templates

FROM 999eagle/godot-mono-build-server:base
ARG GODOT_VERSION=3.0.6

LABEL mantainer="Sophie Tauchert <sophie@999eagle.moe>"

COPY --from=build-server /build/godot-src/src/bin/godot_server.server.opt.tools.64.mono /build/godot
COPY --from=build-server /build/godot-src/src/bin/GodotSharpTools.dll /build/
COPY --from=build-server /build/godot-src/src/bin/mscorlib.dll /build/

COPY --from=build-templates /build/godot-src/src/bin/godot.x11.debug.64.mono /build/data/godot/templates/${GODOT_VERSION}.stable.mono/linux_x11_64_debug
COPY --from=build-templates /build/godot-src/src/bin/godot.x11.opt.64.mono /build/data/godot/templates/${GODOT_VERSION}.stable.mono/linux_x11_64_release

ENV XDG_CACHE_HOME /build/cache
ENV XDG_CONFIG_HOME /build/config
ENV XDG_DATA_HOME /build/data
RUN mkdir -p ${XDG_CACHE_HOME} && mkdir -p ${XDG_CONFIG_HOME} && mkdir -p ${XDG_DATA_HOME}

WORKDIR /build
