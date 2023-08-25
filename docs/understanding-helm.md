## Understanding Helm

When you create a Helm chart for the first time, this is the typical structure you will find:

```console
mychart
|-- Chart.yaml
|-- charts
|-- templates
|   |-- NOTES.txt
|   |-- _helpers.tpl
|   |-- deployment.yaml
|   |-- ingress.yaml
|   `-- service.yaml
`-- values.yaml
```

Let's check each directory in detail:

### Templates

The most important piece of the puzzle is the *templates/* directory. This is where Helm finds the YAML definitions for your Services, Deployments and other Kubernetes objects. If you already have definitions for your application, all you need to do is replace the generated YAML files for your own. What you end up with is a working chart that can be deployed using the helm install command.

It's worth noting however, that the directory is named *templates*, and Helm runs each file in this directory through a [Go template](https://golang.org/pkg/text/template/) rendering engine. Helm extends the template language, adding a number of utility functions for writing charts. Open the *service.yaml* file to see what this looks like:

```console
apiVersion: v1
kind: Service
metadata:
name: {{ template "fullname" . }}
labels:
    chart: "{{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}"
spec:
type: {{ .Values.service.type }}
ports:
- port: {{ .Values.service.externalPort }}
    targetPort: {{ .Values.service.internalPort }}
    protocol: TCP
    name: {{ .Values.service.name }}
selector:
    app: {{ template "fullname" . }}
```

This is a basic Service definition using templating. When deploying the chart, Helm will generate a definition that will look a lot more like a valid Service. We can do a dry-run of a helm install and enable debug to inspect the generated definitions:

```console
helm install --dry-run --debug ./mychart
...
# Source: mychart/templates/service.yaml
apiVersion: v1
kind: Service
metadata:
name: chocolate-potato-mychart
labels:
    chart: "mychart-0.1.0"
spec:
type: ClusterIP
ports:
- port: 80
    targetPort: 80
    protocol: TCP
    name: nginx
selector:
    app: chocolate-potato-mychart
...
```

### Values

The template in *service.yaml* makes use of the Helm-specific objects *.Chart* and *.Values*. The former provides metadata about the chart to your definitions such as the name, or version. The latter *.Values* object is a key element of Helm charts, used to expose configuration that can be set at the time of deployment. The defaults for this object are defined in the *values.yaml* file. Try changing the default value for *service.internalPort* and execute another dry-run, you should find that the targetPort in the Service and the containerPort in the Deployment changes. The *service.internalPort* value is used here to ensure that the Service and Deployment objects work together correctly. The use of templating can greatly reduce boilerplate and simplify your definitions.

If a user of your chart wanted to change the default configuration, they could provide overrides directly on the command-line:

```console
$ helm install --dry-run --debug ./mychart --set service.internalPort=8080
```

For more advanced configuration, a user can specify a YAML file containing overrides with the *--values* option.

### Helpers and other functions

The *service.yaml* template also makes use of partials defined in *_helpers.tpl*, as well as functions like replace. The [Helm documentation](https://helm.sh/docs/chart_template_guide/getting_started/) has a deeper walkthrough of the templating language, explaining how functions, partials and flow control can be used when developing your chart.

### Documentation

Another useful file in the *templates/* directory is the *NOTES.txt* file. This is a templated, plaintext file that gets printed out after the chart is successfully deployed. As we'll see when we deploy our first chart, this is a useful place to briefly describe the next steps for using a chart. Since *NOTES.txt* is run through the template engine, you can use templating to print out working commands for obtaining an IP address, or getting a password from a Secret object.

### Metadata

As mentioned earlier, a Helm chart consists of metadata that is used to help describe what the application is, define constraints on the minimum required Kubernetes and/or Helm version and manage the version of your chart. All of this metadata lives in the Chart.yaml file. The [Helm documentation](https://helm.sh/docs/) describes the different fields for this file.

### Next steps: Create your first Helm chart

To learn more about the common Helm chart structure and start creating your first Helm chart, check out the [official Helm guide](https://helm.sh/docs/chart_best_practices/conventions/).
