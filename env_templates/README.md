---


Simple example how to dynamically create env variables or secret env variables for Pod. Before you start testing Secret env variables you need to create Secret via

```
kubectl create secret generic test-env --from-env-file=variables
```

Run Ansible to generate manifest from template via 

```
ansible-playbook gen-template.yaml
```

and you get your Pod manifest with default name `test-pod.yaml`. After creating this Pod in your cluster you can ensure that all variables
in your container via

```
kubectl exec envars-test-pod -- env
```

or if you do not need a template engine you can crate `PodPreset`, example located in `manifests` directory. For more information, read official kubernetes documentation.





a
a
a
a
a
a
a
a
a
a
