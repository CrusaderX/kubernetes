## Helm tips & tricks

1. Imagine that someone have many services with one template and want to pick service options for it. Example:


`values.yaml`
```yaml
services:
    ms01:
        port: 8080
        readiness:
            path: /
        annotations: "true"
    ms02:
        port: 8090
        readiness:
            path: /readiness
            initialDelaySeconds: 25
        annotations: "true"
    ms03:
        port: 8099
        annotations: "false"
        env:
        - name: ENV
          value: local
```


`templates/deployment.yaml`
```yaml
{{- $vars := pluck .Values.app .Values.services | first }}
{{- $port := first (values (pick $vars "port")) }}
{{- $annotations := first (values (pick $vars "annotations")) }}
{{- $env := first (pluck "env" (pick $vars "env")) }}
{{- $readiness :=  first (values (pick $vars "readiness")) }}
```

So now you can manipulate this variables as you wish. Examples:

```yaml
readinessProbe:
  httpGet:
    port: {{ $port }}
    path: {{ default "/" $readiness.path }}
  {{- if (unset $readiness "path") }}
  {{- toYaml (unset $readiness "path") | nindent 10 -}}
  {{- end }}

env:
  - name: TEST
    value: value
  {{- if $env }}
  {{- toYaml $env | nindent 10 -}}
  {{- end }}
```

```console
$ helm upgrade ${deployment} ${deploymentPath} --set app=ms01
```


2. Imagine that someone what to deploy service with `:latest` tag (please, don't do this). Anyway, we can
do some tricks. Add `env` variable that will be changed every deploy and do not forget to set `imagePullPolicy` to `Always`


`_helpers.tpl`
```yaml
{{- define "app.date" -}}
{{- printf "%s" now | trunc 19 }}
{{- end -}}
```


`templates/deployment.yaml`
```yaml
env:
  - name: APP__DEPLOY__TIMESTAMP
    value: {{ template "app.date" . }}
```