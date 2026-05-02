FROM alpine:3.19

ARG NODE
ENV NODE=${NODE}

RUN apk add --no-cache \
        bash \
        curl \
        iproute2 \
        iptables \
        iputils \
        netcat-openbsd \
        strongswan \
        tcpdump

WORKDIR /opt/legacy-wan

COPY nodes/${NODE}/swanctl.conf /etc/swanctl/conf.d/site.conf
COPY node_boot.sh               /usr/local/bin/node_boot.sh

RUN chmod 0600 /etc/swanctl/conf.d/site.conf \
 && chmod +x   /usr/local/bin/node_boot.sh

ENTRYPOINT ["/usr/local/bin/node_boot.sh"]
