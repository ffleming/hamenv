# FROM fsfleming/dmr-bridge-base:0.1.0 AS analog_builder
FROM ubuntu:focal AS base_builder
ARG platform="amd64"
# begin base build
ARG repo_base="https://github.com/DVSwitch"
ARG analog_name="Analog_Bridge"
ARG mmdvm_name="MMDVM_Bridge"
ARG tmp_pkgs="git"
ARG pkgs="libsndfile-dev libasound2 python3"
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install -y ${tmp_pkgs} ${pkgs} \
    && git clone ${repo_base}/${analog_name} /src/${analog_name} \
    && git clone ${repo_base}/${mmdvm_name} /src/${mmdvm_name} \
    && mv /src/${analog_name}/bin/${analog_name}.${platform} /${analog_name} \
    && mv /src/${mmdvm_name}/bin/${mmdvm_name}.${platform} /${mmdvm_name} \
    && mv /src/${mmdvm_name}/dvswitch.sh / \
    && mkdir -p /opt/${mmdvm_name} \
    && apt-get purge -y ${tmp_pkgs} \
    && apt-get autoremove -y \
    && apt-get clean
# end base build
COPY run.sh /
COPY *.tmpl /
COPY bridge.macro /
RUN chmod +x /run.sh /dvswitch.sh
CMD ["bash", "/run.sh"]
