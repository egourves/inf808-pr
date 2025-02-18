#!/bin/sh
cd /app && \
apt-get update && \
apt-get install -y nodejs npm && \
# Directly use npm to install dependencies and build the application
(cd plugins/magma && npm install) && \
(cd plugins/magma && npm run build) && \
# Remove Node.js, npm, and other unnecessary packages
apt-get remove -y nodejs npm && \
apt-get autoremove -y && \
apt-get clean && \
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
