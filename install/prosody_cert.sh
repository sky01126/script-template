#!/bin/bash

#DOMAIN="meetdev.kthcorp.com"
if [[ -z ${DOMAIN} ]]; then
    printf "Enter your domain (ex. scala.or.kr)"
    read -e -p " > " DOMAIN
    while [[ -z ${DOMAIN} ]]; do
        printf "Enter your domain (ex. scala.or.kr)"
        read -e -p " > " DOMAIN
    done
    echo
fi
rm -rf *${DOMAIN}*

# ----------------------------------------------------------
echo "[v3_extensions]
keyUsage                = digitalSignature,keyEncipherment
extendedKeyUsage        = serverAuth,clientAuth
subjectAltName          = @subject_alternative_name
basicConstraints        = CA:FALSE

[subject_alternative_name]
DNS.0                   = conferenceduration.${DOMAIN}
DNS.1                   = lobby.${DOMAIN}
DNS.2                   = auth.${DOMAIN}
DNS.3                   = ${DOMAIN}
DNS.4                   = focus.${DOMAIN}
DNS.5                   = conference.${DOMAIN}
DNS.6                   = speakerstats.${DOMAIN}
DNS.7                   = internal.auth.${DOMAIN}
otherName.0             = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-server.conferenceduration.${DOMAIN}
otherName.1             = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:conferenceduration.${DOMAIN}
otherName.2             = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-server.lobby.${DOMAIN}
otherName.3             = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:lobby.${DOMAIN}
otherName.4             = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-client.auth.${DOMAIN}
otherName.5             = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-server.auth.${DOMAIN}
otherName.6             = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:auth.${DOMAIN}
otherName.7             = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-client.${DOMAIN}
otherName.8             = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:${DOMAIN}
otherName.9             = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-server.focus.${DOMAIN}
otherName.10            = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:focus.${DOMAIN}
otherName.11            = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-server.conference.${DOMAIN}
otherName.12            = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:conference.${DOMAIN}
otherName.13            = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-server.speakerstats.${DOMAIN}
otherName.14            = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:speakerstats.${DOMAIN}
otherName.15            = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-server.internal.auth.${DOMAIN}
otherName.16            = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:internal.auth.${DOMAIN}

[req_distinguished_name]
countryName             = KR
localityName            = The Internet
organizationName        = KTH
organizationalUnitName  = XMPP Department
commonName              = ${DOMAIN}
emailAddress            = xmpp@${DOMAIN}

[req]
# 화면으로 입력 받지 않도록 설정.
prompt                  = no
x509_extensions         = v3_extensions
req_extensions          = v3_extensions
distinguished_name      = req_distinguished_name
" > ${DOMAIN}.cfg

# openssl genpkey -algorithm RSA                              \
#                 -pkeyopt rsa_keygen_bits:2048               \
#                 -out ${DOMAIN}.key

openssl genpkey -algorithm RSA                              \
                -pkeyopt rsa_keygen_bits:4096               \
                -out ${DOMAIN}.key

chmod 400 ${DOMAIN}.key

openssl req -new -sha256                                                                                            \
            -key    ${DOMAIN}.key                           \
            -out    ${DOMAIN}.csr                           \
            -config ${DOMAIN}.cfg

openssl x509 -req -days 3650                                \
             -extensions v3_extensions                      \
             -in      ${DOMAIN}.csr                         \
             -signkey ${DOMAIN}.key                         \
             -out     ${DOMAIN}.crt                         \
             -extfile ${DOMAIN}.cfg

rm -rf ${DOMAIN}.csr

# 인증서 확인
openssl x509 -text -in ${DOMAIN}.crt

# ----------------------------------------------------------
echo "[v3_extensions]
keyUsage                = digitalSignature,keyEncipherment
extendedKeyUsage        = serverAuth,clientAuth
subjectAltName          = @subject_alternative_name
basicConstraints        = CA:FALSE

[subject_alternative_name]
DNS.0                   = auth.${DOMAIN}
DNS.1                   = internal.auth.${DOMAIN}
otherName.0             = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-client.auth.${DOMAIN}
otherName.1             = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-server.auth.${DOMAIN}
otherName.2             = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:auth.${DOMAIN}
otherName.3             = 1.3.6.1.5.5.7.8.7;IA5STRING:_xmpp-server.internal.auth.${DOMAIN}
otherName.4             = 1.3.6.1.5.5.7.8.5;FORMAT:UTF8,UTF8:internal.auth.${DOMAIN}

[distinguished_name]
countryName             = KR
localityName            = The Internet
organizationName        = KTH
organizationalUnitName  = XMPP Department
commonName              = auth.${DOMAIN}
emailAddress            = xmpp@auth.${DOMAIN}

[req]
# 화면으로 입력 받지 않도록 설정.
prompt                  = no
x509_extensions         = v3_extensions
req_extensions          = v3_extensions
distinguished_name      = distinguished_name
" > auth.${DOMAIN}.cfg

# openssl genpkey -algorithm RSA                              \
#                 -pkeyopt rsa_keygen_bits:2048               \
#                 -out auth.${DOMAIN}.key

openssl genpkey -algorithm RSA                              \
                -pkeyopt rsa_keygen_bits:4096               \
                -out auth.${DOMAIN}.key

chmod 400 ${DOMAIN}.key

openssl req -new -sha256                                                                                            \
            -key    auth.${DOMAIN}.key                      \
            -out    auth.${DOMAIN}.csr                      \
            -config auth.${DOMAIN}.cfg

openssl x509 -req -days 3650                                \
             -extensions v3_extensions                      \
             -in      auth.${DOMAIN}.csr                    \
             -signkey auth.${DOMAIN}.key                    \
             -out     auth.${DOMAIN}.crt                    \
             -extfile auth.${DOMAIN}.cfg

rm -rf auth.${DOMAIN}.csr

# 인증서 확인
openssl x509 -text -in auth.${DOMAIN}.crt
