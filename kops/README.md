After creating cluster, we need to modify it:

```bash
kops edit cluster --name=my_cluster
```

```yaml
 kubeAPIServer:
    basicAuthFile: ""
    TokenAuthFile: ""
    anonymousAuth: "false"
    authorizationMode: RBAC,Node
    auditLogPath: /var/log/kube-apiserver-audit.log
    auditLogMaxAge: 30
    auditLogMaxBackups: 10
    auditLogMaxSize: 100
    auditPolicyFile: /srv/kubernetes/audit-policy.yaml
    admissionControl:
      - NamespaceLifecycle
      - LimitRanger
      - ServiceAccount
      - PersistentVolumeLabel
      - DefaultStorageClass
      - ResourceQuota
      - DefaultTolerationSeconds
      - Initializers
      - PodPreset
      - PodSecurityPolicy
      - AlwaysPullImages
      - DenyEscalatingExec
    runtimeConfig:
      settings.k8s.io/v1alpha1: "true"
      rbac.authorization.k8s.io/v1alpha1: "true"
      batch/v2alpha1: "true"
    kubelet:
      kubeletCgroups: "/systemd/system.slice"
      runtimeCgroups: "/systemd/system.slice"
      anonymousAuth: false
    masterKubelet:
      kubeletCgroups: "/systemd/system.slice"
      runtimeCgroups: "/systemd/system.slice"
    featureGates:
      AllAlpha: "true"
      RotateKubeletClientCertificate: "true"
      RotateKubeletServerCertificate: "true"
      AdvancedAuditing: "true"
      HugePages: "false"
  encryptionConfig: true
  fileAssets:
    - content: |
        apiVersion: audit.k8s.io/v1beta1
        kind: Policy
        omitStages:
          - "RequestReceived"
        rules:
          - level: RequestResponse
            resources:
            - group: ""
              resources: ["pods"]
          - level: Metadata
            resources:
            - group: ""
              resources: ["pods/log", "pods/status"]
          - level: None
            resources:
            - group: ""
              resources: ["configmaps"]
              resourceNames: ["controller-leader"]
          - level: None
            users: ["system:kube-proxy"]
            verbs: ["watch"]
            resources:
            - group: ""
              resources: ["endpoints", "services"]
          - level: None
            userGroups: ["system:authenticated"]
            nonResourceURLs:
            - "/api*"
            - "/version"
          - level: Request
            resources:
            - group: ""
              resources: ["configmaps"]
            namespaces: ["kube-system"]
          - level: Metadata
            resources:
            - group: ""
              resources: ["secrets", "configmaps"]
          - level: Request
            resources:
            - group: ""
            - group: "extensions"
          - level: Metadata
            omitStages:
              - "RequestReceived"
      name: audit-policy-file
      path: /srv/kubernetes/audit-policy.yaml
      roles:
      - Master

```

Enable `encryptionConfig` via `config.yaml`:

```yaml
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
    - secrets
    providers:
    - aescbc:
        keys:
        - name: base
          secret: {{ secret }}
```

where `{{ secret }}` is:

```bash

echo $( head -c 32 /dev/urandom | base64 )`
```

```bash
kops create secret encryptionconfig -f config.yaml --name=my_cluster
```

Insert into etcd section: 
```yaml  
  enableEtcdTLS: true
  enableEtcdAuth: true
  version: 3.1.17
``

Update cluster:

```bash

kops update cluster --name=my_cluster --yes && \
    kops rolling-update cluster --yes
```

We can ensure, that `secret` now encrypted:
```bash

kubectl exec -ti $(kubectl get pods -n kube-system -l k8s-app=etcd-server -o=jsonpath='{.items[0].metadata.name}') /bin/sh

ETCDCTL_API=3  etcdctl --cert  /srv/kubernetes/etcd-client.pem --key /srv/kubernetes/etcd-client-key.pem --cacert /srv/kubernetes/ca.crt --endpoints https://127.0.0.1:4001 get /registry/secrets --keys-only --prefix
ETCDCTL_API=3  etcdctl --cert  /srv/kubernetes/etcd-client.pem --key /srv/kubernetes/etcd-client-key.pem --cacert /srv/kubernetes/ca.crt --endpoints https://127.0.0.1:4001 get /
registry/secrets/default/default-token-{{ my_token }}  --prefix
```

---

TLS for Tiller & Helm

Add `v3_ca` section configuration for v3_ca certificate generation

```bash
sudo sh -c 'cat <<EOF >> /etc/ssl/openssl.cnf
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
EOF'
```


