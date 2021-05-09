FROM alpine:3.3

RUN apk add --no-cache openssh

RUN ssh-keygen -f /etc/ssh/ssh_host_rsa_key -t rsa -N '' > /dev/null && \
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -t dsa -N '' > /dev/null && \
    ssh-keygen -f /etc/ssh/ssh_host_ecdsa_key -t ecdsa -N '' > /dev/null && \
    ssh-keygen -f /etc/ssh/ssh_host_ed25519_key -t ed25519 -N '' > /dev/null

# SSH CONFIG
RUN printf "AuthorizedKeysFile /etc/ssh/authorized_keys\nGatewayPorts yes\nPasswordAuthentication no\n" > /etc/ssh/sshd_config

COPY start.sh .


ENTRYPOINT ["sh", "start.sh"]