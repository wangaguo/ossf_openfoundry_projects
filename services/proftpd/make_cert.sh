#!/bin/sh
mkdir -p /etc/ssl/certs
mkdir -p /etc/ssl/private
chmod og-rwx /etc/ssl/private
mkdir -p /etc/ssl/crl
mkdir -p /etc/ssl/newcerts

openssl genrsa -des3 -out /etc/ssl/private/myrootca.key 2048
chmod og-rwx /etc/ssl/private/myrootca.key

openssl req -new -key /etc/ssl/private/myrootca.key -out /tmp/myrootca.req

openssl x509 -req -days 7305 -sha1 -extfile /etc/ssl/openssl.cnf -extensions v3_ca -signkey /etc/ssl/private/myrootca.key -in /tmp/myrootca.req -out /etc/ssl/certs/myrootca.crt

rm -f /tmp/myrootca.req

openssl genrsa -out /etc/ssl/private/myhost.key 2048
chmod og-rwx /etc/ssl/private/myhost.key

openssl req -new -key /etc/ssl/private/myhost.key -out /tmp/myhost.req

openssl x509 -req -days 3650 -sha1 -extfile /etc/ssl/openssl.cnf -extensions v3_req -CA /etc/ssl/certs/myrootca.crt -CAkey /etc/ssl/private/myrootca.key -CAserial /etc/ssl/myrootca.srl -CAcreateserial -in /tmp/myhost.req -out /etc/ssl/certs/myhost.crt
