# Db2 Community Edition

## Introduction
This describes how to install Db2 Community Edition into an OpenShift cluster.

## Requirements
* Cluster:
  * OpenShift version ">=3.10.1"
  * Helm version ">=3.9" (https://blog.openshift.com/getting-started-helm-openshift/) 
  * Cluster Administrator account
* Storage:
  * NFS StorageClass or PersistentVolume
  * hostPath StorageClass or PersistentVolume
* Resources:
  * Minimum 3.3 vCPU (2.2 for the Db2 engine and 1.1 for Db2 auxiliary services)
  * Minimum 5.73 GiB Memory (4GiB for the Db2 engine and 1.73GiB for Db2 auxiliary services)

_Note_: To convert GiB to GB, multiply the GiB value by 1.048.

## Installation

### Pre-install cluster configuration

Create a project of your desired name:
```
# oc new-project <PROJECT-NAME>
```

Create the Role, RoleBinding, ServiceAccount, and SecurityContextConstraint objects:
```
# oc create -n <PROJECT-NAME> -f ./adm
```

Bind the SecurityContextConstraint to the ServiceAccount:
```
# oc adm policy add-scc-to-user db2u-scc system:serviceaccount:<PROJECT-NAME>:db2u
```

### Installation of the Chart

Once the pre-install cluster configuration is complete, proceed to install the chart using the script `db2u-install`. The usage is:

```
Db2 Community Edition Installer

Usage: ./db2u-install --db-type STRING --namespace STRING --release-name STRING [--existing-pvc STRING | --storage-class STRING] [OTHER ARGUMENTS...]

    Install arguments:
        --db-type STRING            the type of database to deplpy. Must be one of: db2wh, db2oltp (required)
        --namespace STRING          namespace to install Db2 Community Edition into (required)
        --release-name STRING       release name for helm (required)
        --existing-pvc STRING       existing PersistentVolumeClaim to use for persistent storage
        --storage-class STRING      StorageClass to use to dynamically provision a volume
        --cpu-size STRING           amount of CPU cores to set at engine pod's request
        --memory-size STRING        amount of memory to set at engine pod's request

    Helm arguments:
        --tls                       enable TLS for request
        --tiller-namespace STRING   namespace of Tiller (default "kube-system")
        --tls-ca-cert STRING        path to TLS CA certificate file (default "$HELM_HOME/ca.pem")
        --tls-cert STRING           path to TLS certificate file (default "$HELM_HOME/cert.pem")
        --tls-key STRING            path to TLS key file (default "$HELM_HOME/key.pem")
        --tls-verify                enable TLS for request and verify remote
        --home STRING               location of your Helm config. Overrides $HELM_HOME (default "~/.helm")
        --host STRING               address of Tiller. Overrides $HELM_HOST
        --kube-context STRING       name of the kubeconfig context to use

    Miscellaneous arguments:
        -h, --help                  display the usage
```

Example:
```
# ./db2u-install --dbtype db2oltp --namespace db2u-project --release-name db2u-release-1 --storage-class managed-nfs-storage
```

### Uninstalling the Chart

To delete the deployment:

```
# helm delete <RELEASE-NAME> --purge --tls
```

To delete the pre-install configuration objects:

```
# oc delete -n <PROJECT-NAME> -f ./adm
```
