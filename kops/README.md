Kops/AWS security text file

After creating cluster, modify it:

```bash
kops edit cluster --name=my_cluster
```

```yaml
  kubelet:
    kubeletCgroups: "/systemd/system.slice"
    runtimeCgroups: "/systemd/system.slice"
    anonymousAuth: false
  masterKubelet:
    kubeletCgroups: "/systemd/system.slice"
    runtimeCgroups: "/systemd/system.slice"
  kubeAPIServer:
    authorizationMode: RBAC,Node
    auditLogPath: /var/log/kube-apiserver-audit.log
    auditLogMaxAge: 5
    auditLogMaxBackups: 5
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
    featureGates:
      AllAlpha: "true"
      BlockVolume: "false"
      RotateKubeletClientCertificate: "true"
      RotateKubeletServerCertificate: "true"
      AdvancedAuditing: "true"
      HugePages: "false"
      ReadOnlyAPIDataVolumes: "false"
  encryptionConfig: true
  fileAssets:
    - content: |
        apiVersion: audit.k8s.io/v1beta1
        kind: Policy
        rules:
          - level: None
            resources:
              - group: ""
                resources:
                  - endpoints
                  - services
                  - services/status
            users:
              - 'system:kube-proxy'
            verbs:
              - watch

          - level: None
            resources:
              - group: ""
                resources:
                  - nodes
                  - nodes/status
            userGroups:
              - 'system:nodes'
            verbs:
              - get

          - level: None
            namespaces:
              - kube-system
            resources:
              - group: ""
                resources:
                  - endpoints
            users:
              - 'system:kube-controller-manager'
              - 'system:kube-scheduler'
              - 'system:serviceaccount:kube-system:endpoint-controller'
            verbs:
              - get
              - update

          - level: None
            resources:
              - group: ""
                resources:
                  - namespaces
                  - namespaces/status
                  - namespaces/finalize
            users:
              - 'system:apiserver'
            verbs:
              - get

          - level: None
            resources:
              - group: metrics.k8s.io
                resources:
                  - initializerconfigurations
                  - services
                  - endpoints
            users:
              - 'system:kube-controller-manager'
            verbs:
              - get
              - list

          - level: None
            resources:
              - group: admissionregistration.k8s.io
            users:
              - 'system:apiserver'
            verbs:
              - get
              - list

          - level: None
            nonResourceURLs:
              - '/healthz*'
              - /version
              - '/swagger*'

          - level: None
            resources:
              - group: ""
                resources:
                  - events

          - level: None
            omitStages:
              - RequestReceived
            resources:
              - group: ""
                resources:
                  - nodes/status
                  - pods/status
            users:
              - kubelet
              - 'system:node-problem-detector'
              - 'system:serviceaccount:kube-system:node-problem-detector'
            verbs:
              - update
              - patch

          - level: Request
            omitStages:
              - RequestReceived
            resources:
              - group: ""
                resources:
                  - nodes/status
                  - pods/status
            userGroups:
              - 'system:nodes'
            verbs:
              - update
              - patch

          - level: None
            omitStages:
              - RequestReceived
            users:
              - 'system:serviceaccount:kube-system:namespace-controller'
            verbs:
              - deletecollection

          - level: RequestResponse
            omitStages:
              - RequestReceived
            resources:
              - group: ""
                resources:
                  - secrets
                  - configmaps
              - group: authentication.k8s.io
                resources:
                  - tokenreviews

          - level: None
            omitStages:
              - RequestReceived
            resources:
              - group: ""
              - group: admissionregistration.k8s.io
              - group: apiextensions.k8s.io
              - group: apiregistration.k8s.io
              - group: apps
              - group: authentication.k8s.io
              - group: authorization.k8s.io
              - group: autoscaling
              - group: batch
              - group: certificates.k8s.io
              - group: extensions
              - group: metrics.k8s.io
              - group: networking.k8s.io
              - group: policy
              - group: rbac.authorization.k8s.io
              - group: scheduling.k8s.io
              - group: settings.k8s.io
              - group: storage.k8s.io
            verbs:
              - get
              - list
              - watch

          - level: None
            omitStages:
              - RequestReceived
            resources:
              - group: ""
              - group: admissionregistration.k8s.io
              - group: apiextensions.k8s.io
              - group: apiregistration.k8s.io
              - group: apps
              - group: authentication.k8s.io
              - group: authorization.k8s.io
              - group: autoscaling
              - group: batch
              - group: certificates.k8s.io
              - group: extensions
              - group: metrics.k8s.io
              - group: networking.k8s.io
              - group: policy
              - group: rbac.authorization.k8s.io
              - group: scheduling.k8s.io
              - group: settings.k8s.io
              - group: storage.k8s.io
              
          - level: Metadata
            omitStages:
              - RequestReceived
      name: audit-policy-file
      path: /srv/kubernetes/audit-policy.yaml
      roles:
      - Master

```

NOTE:
> If you don't see the output of `kubectl logs -f` from pod, you should add `APIResponseCompression: "false"` into featureGates section

Insert into etcd section for both main/events sections: 
```yaml  
  enableEtcdTLS: true
  version: 3.1.17
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

echo $( head -c 32 /dev/urandom | base64 )
```

```bash
kops create secret encryptionconfig -f config.yaml --name=my_cluster
```

Update cluster:

```bash

kops update cluster --name=my_cluster --yes
```

Ensure that `secret` now encrypted:
```bash

kubectl exec -n kube-system -ti $(kubectl get pods -n kube-system -l k8s-app=etcd-server -o=jsonpath='{.items[0].metadata.name}') /bin/sh

ETCDCTL_API=3  etcdctl --cert  /srv/kubernetes/etcd-client.pem --key /srv/kubernetes/etcd-client-key.pem --cacert /srv/kubernetes/ca.crt --endpoints https://127.0.0.1:4001 get /registry/secrets --keys-only --prefix
ETCDCTL_API=3  etcdctl --cert  /srv/kubernetes/etcd-client.pem --key /srv/kubernetes/etcd-client-key.pem --cacert /srv/kubernetes/ca.crt --endpoints https://127.0.0.1:4001 get /registry/secrets/default/default-token-{{ my_token }}  --prefix
```

Do not forget to add `automountServiceAccountToken: false` record to `spec` location in your `Deployment/Pod/etc` or disable it on `ServiceAccount` level.

Do not forget to protect `get aws metaData` from pod: use `NetworkPolicy` or `kiam` or smt.

Modify `kube-apiserver.manifest` to disable some security issues:
```python
def change_api_manifest(file):
    with open(file,'r') as input_file:
        results = yaml_as_python(input_file)
        for item in results["spec"]["containers"]:
            for command in item["command"]:
                if 'token-auth-file' in command:
                    command = re.sub(r'--token-auth-file.*?\s',r"", command)
                if 'basic-auth-file' in command:
                    command = re.sub(r'--basic-auth-file.*?\s',r"", command)
                if 'profiling' not in command:
                    command = re.sub(r'(\/bin\/kube-apiserver\s)(--)', r'\1--profiling=false \2', command)
                if 'service-account-lookup' not in command:
                    command = re.sub(r'(\/bin\/kube-apiserver\s)(--)', r"\1--service-account-lookup=true \2", command)
                if 'service-account-key-file' not in command:
                    command = re.sub(r'(\/bin\/kube-apiserver\s)(--)', r"\1--service-account-key-file=/srv/kubernetes/server.key \2", command)
                if 'repair-malformed-updates' not in command:
                    command = re.sub(r'(\/bin\/kube-apiserver\s)(--)', r"\1--repair-malformed-updates=false \2", command)
            item["command"][2] = command
        return results
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

or use code from `tiller` directory where you should change subj data.


---

Certificate signer

It's just a small python code for validating certificate pending requests.
