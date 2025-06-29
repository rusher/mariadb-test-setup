#!/bin/bash

# // SPDX-License-Identifier: LGPL-2.1-or-later
# // Copyright (c) 2015-2025 MariaDB Corporation Ab

# Script to generate self-signed certificates for testing
# CN: mariadb.example.com

set -e

echo "Generating self-signed certificates for mariadb.example.com..."

# Create directory for certificates
mkdir -p .github/workflows/certs

echo "Generate CA private key"
openssl genrsa 2048 > .github/workflows/certs/ca.key

echo "[ req ]" > .github/workflows/certs/ca.conf
echo "prompt                 = no" >> .github/workflows/certs/ca.conf
echo "distinguished_name     = req_distinguished_name" >> .github/workflows/certs/ca.conf
echo "" >> .github/workflows/certs/ca.conf
echo "[ req_distinguished_name ]" >> .github/workflows/certs/ca.conf
echo "countryName            = FR" >> .github/workflows/certs/ca.conf
echo "stateOrProvinceName    = Loire-atlantique" >> .github/workflows/certs/ca.conf
echo "localityName           = Nantes" >> .github/workflows/certs/ca.conf
echo "organizationName       = Home" >> .github/workflows/certs/ca.conf
echo "organizationalUnitName = Lab" >> .github/workflows/certs/ca.conf
echo "commonName             = mariadb.example.com" >> .github/workflows/certs/ca.conf
echo "emailAddress           = admin@mariadb.example.com" >> .github/workflows/certs/ca.conf

echo "Generate CA certificate (self-signed)"
openssl req -days 365 -new -x509 -nodes -key .github/workflows/certs/ca.key -out .github/workflows/certs/ca.crt --config .github/workflows/certs/ca.conf



echo "[ req ]" > .github/workflows/certs/server.conf
echo "prompt                 = no" >> .github/workflows/certs/server.conf
echo "distinguished_name     = req_distinguished_name" >> .github/workflows/certs/server.conf
echo "req_extensions         = req_ext" >> .github/workflows/certs/server.conf
echo "" >> .github/workflows/certs/server.conf
echo "[ req_distinguished_name ]" >> .github/workflows/certs/server.conf
echo "countryName            = FR" >> .github/workflows/certs/server.conf
echo "stateOrProvinceName    = Loire-atlantique" >> .github/workflows/certs/server.conf
echo "localityName           = Nantes" >> .github/workflows/certs/server.conf
echo "organizationName       = Home" >> .github/workflows/certs/server.conf
echo "organizationalUnitName = Lab" >> .github/workflows/certs/server.conf
echo "commonName             = mariadb.example.com" >> .github/workflows/certs/server.conf
echo "emailAddress           = admin@mariadb.example.com" >> .github/workflows/certs/server.conf
echo "" >> .github/workflows/certs/server.conf
echo "[ req_ext ]" >> .github/workflows/certs/server.conf
echo "subjectAltName = DNS: mariadb.example.com, IP: 127.0.0.1" >> .github/workflows/certs/server.conf


echo "Generating private key..."
openssl genrsa -out .github/workflows/certs/server.key 2048

echo "Generating certificate signing request..."
openssl req -new -key .github/workflows/certs/server.key -out .github/workflows/certs/server.csr --config .github/workflows/certs/server.conf


echo "Generate the certificate for the server:"
openssl x509 -req -days 365 -in .github/workflows/certs/server.csr -out .github/workflows/certs/server.crt -CA .github/workflows/certs/ca.crt -CAkey .github/workflows/certs/ca.key -extensions req_ext -extfile .github/workflows/certs/server.conf

cat .github/workflows/certs/ca.crt .github/workflows/certs/server.crt > .github/workflows/certs/ca_server.crt
openssl x509 -noout -fingerprint -sha1 -in .github/workflows/certs/server.crt > .github/workflows/certs/server-cert.sha1

echo "Server certificate SHA1 fingerprint:"
cat .github/workflows/certs/server-cert.sha1

echo "Generating client private key..."
openssl genrsa -out .github/workflows/certs/client.key 2048

echo "Generating password-protected client private key..."
openssl rsa -aes256 -in .github/workflows/certs/client.key -out .github/workflows/certs/client-encrypted.key -passout pass:qwerty

echo "Generating client certificate signing request..."
openssl req -new -key .github/workflows/certs/client.key -out .github/workflows/certs/client.csr --config .github/workflows/certs/server.conf

echo "Generate the certificate for the client:"
openssl x509 -req -days 365 -in .github/workflows/certs/client.csr -out .github/workflows/certs/client.crt -CA .github/workflows/certs/ca.crt -CAkey .github/workflows/certs/ca.key -extensions req_ext -extfile .github/workflows/certs/server.conf

echo "Generate the pkcs for the client:"
openssl pkcs12 -export -in .github/workflows/certs/client.crt -inkey .github/workflows/certs/client.key -out .github/workflows/certs/client.p12 -name "mysqlAlias" -passout pass:kspass

echo "Creating symbolic links..."
ln -sf client.key .github/workflows/certs/client-key.pem
ln -sf client.crt .github/workflows/certs/client-cert.pem
ln -sf ca_server.crt .github/workflows/certs/cacert.pem
ln -sf client-encrypted.key .github/workflows/certs/client-key-enc.pem

# Set appropriate permissions
chmod 644 .github/workflows/certs/*
chmod 600 .github/workflows/certs/ca.key .github/workflows/certs/client.key .github/workflows/certs/client-encrypted.key

# List generated certificates
echo "Generated certificates:"
ls -la .github/workflows/certs/

# Verify certificate
echo "Certificate details:"
openssl x509 -in .github/workflows/certs/server.crt -text -noout | grep -E "(Subject|CN)"

echo "Certificate generation completed successfully!"