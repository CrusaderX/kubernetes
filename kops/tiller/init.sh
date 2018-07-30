#!/usr/bin/env bash

function init(){
    
    rm -rf {ca,tiller,helm}
    mkdir {ca,tiller,helm} || true
}

function patch(){

    if grep -q v3_ca /etc/ssl/openssl.cnf  ; then
        :
    else
        cat <<EOF >> /etc/ssl/openssl.cnf
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
EOF
    fi
}

init
patch