#!/usr/bin/env bash

set -e

KRED="\x1B[31m"
KNRM="\x1B[0m"
KGRN="\x1B[32m"

function ERROR() {

    printf $KRED"[ ERROR ]: "$KNRM
    printf "%s " "$@"
    printf "\n"
    exit 1
}

function OK() {

    printf $KGRN"[ OK ]: "$KNRM
    printf "%s " "$@"
    printf "\n"
}

function input(){

    longOpts="help,intermediate-key::,intermediate-key-bit::,root-key::,root-key-bit::"
    args=$(getopt -o h --long ${longOpts} -- "$@")

    while true ; do
        case "${1}" in
            -h | --help       ) __help; exit 0 ;;
            --intermediate-key )
                intermediateKeyPasswd=$2 ; shift 2 ;;
            --intermediate-key-bit )
                intermediateKeyBit=$2 ; shift 2 ;;
            --root-key )
                rootKeyPasswd=$2 ; shift 2 ;;
            --root-key-bit )
                rootKeyBit=$2 ; shift 2 ;;
            -- ) shift; break ;;
            *  ) break ;;
        esac
    done

    intermediateKeyBit=${intermediateKeyBit:-2048}
    intermediateKeyPasswd=${intermediateKeyPasswd:-StrongPassword}
    rootKeyBit=${rootKeyBit:-2048}
    rootKeyPasswd=${rootKeyPasswd:-StrongPassword}
}

function rootCA(){

    OK "Generating root CA key" && { openssl genrsa -aes256 -passout pass:${rootKeyPasswd} -out ca/ca.key ${rootKeyBit} &>/dev/null ;}
    OK "Generating root CA cert" && { openssl req -key ca/ca.key -new -x509 -days 7300 -sha256 -out ca/ca.cert \
        -extensions v3_ca \
        -passin pass:${rootKeyPasswd} \
        -subj "/C=GB/ST=London/L=London/O=Tiller/OU=IT/CN=tiller-server/emailAddress=email@example.com" ;}
}

function tillerCert(){

    OK "Generating tiller key" && { openssl genrsa -out tiller/tiller.key 2048 &>/dev/null  ;}
    OK "Generating tiller csr" && { openssl req -key tiller/tiller.key -new -sha256 -out tiller/tiller.csr \
        -subj "/C=GB/ST=London/L=London/O=Tiller Server/OU=IT/CN=tiller-server/emailAddress=email@example.com";}
    OK "Generating tiller cert" && { openssl x509 \
        -days 375 \
        -req -CA ca/ca.cert \
        -CAkey ca/ca.key -CAcreateserial \
        -passin pass:${intermediateKeyPasswd} \
        -in tiller/tiller.csr \
        -out tiller/tiller.cert ;}
}

function helmCert(){

    OK "Generating helm client key" && { openssl genrsa -out helm/helm.key 2048 &>/dev/null  ;}
    OK "Generating helm client csr" && { openssl req -key helm/helm.key -new -sha256 -out helm/helm.csr \
        -subj "/C=GB/ST=London/L=London/O=Tiller Server/OU=IT/CN=tiller-server/emailAddress=email@example.com";}
    OK "Generating helm cert" && { openssl x509 \
        -passin pass:${intermediateKeyPasswd} \
        -days 375 \
        -req -CA ca/ca.cert \
        -CAkey ca/ca.key -CAcreateserial \
        -in helm/helm.csr \
        -out helm/helm.cert ;}
}

function helmInit(){

    kubectl apply -f rbac.yaml
    OK "Checking helm secret plugin" && {
        if helm plugin list | grep -q secrets ; then OK "Already installed" ; else
            OK "Installing helm secret plugin" ; helm plugin install https://github.com/futuresimple/helm-secrets ; fi ;}
    OK "Init helm" && {
      helm init --tiller-tls \
                --tiller-tls-cert tiller/tiller.cert \
                --tiller-tls-key tiller/tiller.key \
                --tiller-tls-verify \
                --tls-ca-cert ca/ca.cert \
                --service-account tiller \
                --override 'spec.template.spec.containers[0].command'='{/tiller,--storage=secret}' ;
    }
    OK "Copying certs to helm home" && {
        cp ca/ca.cert /app/.helm/ca.pem ;
        cp helm/helm.cert /app/.helm/cert.pem ;
        cp helm/helm.key /app/.helm/key.pem ;}
    OK "Initialization complite successfully. Now you can try use 'helm ls --tls'"
}

$(pwd)/init.sh
input "$@"
rootCA
tillerCert
helmCert
helmInit
