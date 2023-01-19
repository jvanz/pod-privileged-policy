Given the following scenario:

> As an operator of a Kubernetes cluster used by multiple users,
> I want to have tight control over who can schedule privileged containers.

Kubernetes containers can be run in privileged mode by providing a well crafted
[SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

Cluster administrators can prevent regular users to create privileged containers
by using a Kubernetes built-in feature called [Pod Security Policies](https://kubernetes.io/docs/concepts/policy/pod-security-policy/).

However, Pod Security Polices are going to be [deprecated](https://github.com/kubernetes/enhancements/issues/5)
in the near future.

Pod Security Policies could be replaced by using policies provided by an
external Admission Controller, like Kubewarden.

This policy inspects the [AdmissionReview](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#request)
objects generated by the Kubernetes API server and either accept or reject them.

The policy can be used to inspect `CREATE` and `UPDATE` requests of `Pod` resources.
It will reject any pod with containers, init container or ephemeral containers
configured as privileged in their [SecurityContext](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

# Settings

This policy has no configurable settings.

The user is responsible to configure the policy defining the resources targeted
by the policy. Otherwise, the policy will not be able to run. The current supported
resources are listed in the metadata.yml file. See more information about how to
configure a policy in the [Kubewarden documentation](https://docs.kubewarden.io/).

# Examples

The following Pod specification doesn't have any security context defined:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
```

This workload can be scheduled by all the users of the cluster.

This Pod specification has one of its containers running in
privileged mode and it will be rejected by the policy:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  runtimeClassName: containerd-runc
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
    securityContext:
      privileged: true
  - name: sleeping-sidecar
    image: alpine
    command: ["sleep", "1h"]
```

