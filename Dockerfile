FROM alpine:3.19

ARG SITE
ENV SITE=${SITE}

RUN apk add --no-cache \
        bash \
        curl \
        iproute2 \
        iptables \
        iputils \
        netcat-openbsd \
        python3 \
        py3-pip \
        tcpdump \
        wireguard-tools

WORKDIR /opt/sdwan

COPY sites/${SITE}/wg0.conf      /etc/wireguard/wg0.conf
COPY sites/${SITE}/agent/        /opt/sdwan/agent/
COPY container_init.sh           /usr/local/bin/container_init.sh

RUN chmod 0600 /etc/wireguard/wg0.conf \
 && chmod +x /usr/local/bin/container_init.sh /opt/sdwan/agent/*.py

ENTRYPOINT ["/usr/local/bin/container_init.sh"]
