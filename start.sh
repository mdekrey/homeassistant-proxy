#!/bin/sh

echo $1 | base64 -d > /etc/ssh/authorized_keys

/usr/sbin/sshd

echo "SSH server ready!"

while sleep 3600; do :; done
