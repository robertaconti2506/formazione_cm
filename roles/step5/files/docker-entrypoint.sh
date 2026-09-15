#!/bin/sh

set -e

# Avvio del servizio SSH (background)
/usr/sbin/sshd -D &

# Avvio del servizio Docker (foreground)
dockerd 
