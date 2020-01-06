# Db2 Community Edition

## Introduction
This describes how to install Db2 Community Edition into an OpenShift cluster.

## Requirements
* Cluster:
  * OpenShift version ">=3.10.1" "<4.X"
  * Helm version ">=2.9" (https://blog.openshift.com/getting-started-helm-openshift/) 
  * Cluster Administrator account
* Storage:
  * NFS version ">=v4.2" StorageClass or PersistentVolume
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

Create the **Role**, **RoleBinding**, **ServiceAccount**, and **SecurityContextConstraint** objects:
```
# oc create -n <PROJECT-NAME> -f ./adm
```

Bind the **SecurityContextConstraint** to the **ServiceAccount**:
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
        --db-name STRING            the name of database to deplpy. The default value is BLUDB (optional). The length of the value must not exceed 8 characters
        --namespace STRING          namespace/project to install Db2 Community Edition into (required)
        --release-name STRING       release name for helm (required)
        --existing-pvc STRING       existing PersistentVolumeClaim to use for persistent storage
        --storage-class STRING      StorageClass to use to dynamically provision a volume
        --cpu-size STRING           amount of CPU cores to set at engine pod's request
        --memory-size STRING        amount of memory to set at engine pod's request

    Helm arguments:
        --tls                       enable TLS for request
        --tiller-namespace STRING   namespace/project of Tiller (default "kube-system")
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
# ./db2u-install \
    --db-type db2oltp \
    --db-name MYDB \
    --namespace db2u-project \
    --release-name db2u-release-1 \
    --storage-class managed-nfs-storage
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

## How to Connect to Db2

You can connect to Db2 using its NodePort service.

* The default database is **BLUDB**
* The default user is **db2inst1**
* The IP address is any OpenShift master node's IP address
* The password is randomly generated for each instance, and stored inside a Secret. It can be retrieved by running the command:
```
oc get secret -n <PROJECT> <RELEASE-NAME>-db2u-instance -o jsonpath='{.data.password}' | base64 -d
```
* The **NodePort**'s port is arbitrarily assigned, and can be retrieved by running the command:
```
oc get svc -n <PROJECT> <RELEASE-NAME>-db2u-engn-svc -o jsonpath='{.spec.ports[?(@.name=="legacy-server")].nodePort}'
```

## SELinux Considerations

If you are using OpenShift with SELinux in enforcing mode, Db2 requires the SELinux label **container_file_t** on its persistent storage. This can be achieved with both NFS and hostPath storage.

### NFS

NFS v4.2 supports volume relabeling on the client-side mount. You can specify the mount options either in the storage class if you are dynamically provisioning the volume, or in the persistent volume if you are manually provisioning the volume.

The following key and values must be added to the storage definition that you are using for Db2:
```
mountOptions:
- v4.2
- context="system_u:object_r:container_file_t:s0"
```
* If you are using a **PersistentVolume** for Db2 storage, add these values under the spec key of the **PersistentVolume** object.
* If you are using a **StorageClass** for Db2 storage, add the values as a top-level key of the **StorageClass** object.

To enable v4.2 on your NFS server or to check whether it is enabled, see [How to enable NFS v4.2 on RHEL7](https://access.redhat.com/solutions/2325171).

### HostPath

Run the following commands to apply the **container_file_t** SELinux label to the storage path on all nodes:
```
# semanage fcontext -a -t container_file_t "<STORAGE-PATH>(/.*)?"
# restorecon -Rv <STORAGE-PATH>
```



## How to create a new LDAP user
### 1. Log in to the LDAP pod
``` 
oc rsh $(oc get po | grep ldap | cut -d " " -f 1) /bin/bash
```

### 2. Find the next available LDAP user ID
```
source /opt/ibm/lib/utils.sh

ldapPassword=$(get_ldap_root_password)

echo $(($(ldapsearch -Z -H ldap:/// -D 'cn=bluldap,dc=blustratus,dc=com' -w "$ldapPassword" -b 'dc=blustratus,dc=com' '(objectClass=posixAccount)' | grep uidNumber | cut -d ":" -f 2 | sort -nr | head -n 1)+1)) 
```
Example output
```
5003
```
### 3. Set up a configuration file 
Create a configuration file (e.g. */tmp/newuser.ldif*) with following contents:
```  
dn: uid=<user>,ou=People,dc=blustratus,dc=com
uid: <user>
cn: <user>
objectClass: account
objectClass: posixAccount
objectClass: top
uidNumber: <new LDAP uid>
gidNumber: <3000|3002>
homeDirectory: /mnt/blumeta0/home/<user>

dn: cn=<bluadmin|bluusers>,ou=Groups,dc=blustratus,dc=com
changetype: modify
add: memberuid
memberuid: <user>
memberuid: uid=<user>,ou=People,dc=blustratus,dc=com   
```
**Note**: 
* Replace *user* with a new LDAP user name. (e.g. ldapusr1)
* gidNumber - **3000** means **admin**; **3002** means **user**
* Replace *new LDAP uid* with an unused unique LDAP id from the step above. 

### 4. Create the new LDAP user by using the config file
Add the new user using the LDAP root credentials:
```
ldapadd -Z -H ldap:/// -D 'cn=bluldap,dc=blustratus,dc=com' -w "$ldapPassword" -f <config-file>
```
**Note**: 
* Replace "config-file" with the real file that you created earlier (e.g. /tmp/newuser.ldif)

Output:
```
adding new entry "uid=ldapuser1,ou=People,dc=blustratus,dc=com"
modifying entry "cn=bluadmin,ou=Groups,dc=blustratus,dc=com"
```

### 5. Set the password for the newly created LDAP user
```
ldappasswd -x -Z -H ldap:/// -D "cn=bluldap,dc=blustratus,dc=com" -w "$ldapPassword" -S "uid=<user>,ou=People,dc=blustratus,dc=com" -s <password>
```

### 6. Verify the newly created LDAP user and credential
a) Exit from the LDAP pod
```
exit
```
b) Log in to a db2u pod 
```
oc rsh db2u-deployment-db2u-0 /bin/bash
```
c) Verify that the new LDAP user exists
```
id <ldap-user>
```
d) Log in to a Db2 instance
```
su - db2inst1
```
d) Connect to a database by using the newly created LDAP user:
```
db2 connect to bludb user <ldap-user> using <ldap-password>
```

## How to apply production license?
This Db2U deployment comes with the Db2 community license. If you need to convert to the production license, follow steps below.

### 1. Download the entitled license key 
Follow the link below to download the production license key (e.g. db2adv_vpc.lic) and make it available to your OpenShift master node.
https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.5.0/com.ibm.db2.luw.qb.server.doc/doc/r0006748.html

### 2. Check the current Db2 license
#### a. Find the Db2 installation path from the Db2U pod
```
DB2PATH=`oc rsh db2u-deployment-db2u-0 bin/bash -c "db2ls | cut -d ' ' -f 1 | awk 'NR==4'" | sed $'s/[^[:print:]\t]//g'`
```
#### b. List the current Db2 license from the Db2 pod
```
oc rsh db2u-deployment-db2u-0 /bin/bash -c "$DB2PATH/adm/db2licm -l"
```
Output:
```
Product name:                     "DB2 Enterprise Server Edition"
License type:                     "License not registered"
Expiry date:                      "License not registered"
Product identifier:               "db2ese"
Version information:              "11.5"

Product name:                     "IBM DB2 Developer-C Edition"
License type:                     "Community"
Expiry date:                      "Permanent"
Product identifier:               "db2dec"
Version information:              "11.5"
Max amount of memory (GB):        "16"
Max number of cores:              "4"
Max amount of table space (GB):   "100"
```

### 3. Apply the production license

Update `RELEASE_NAME` to the namespace/project where db2 is deploy and `LICENSE_FILE` to the location of the `lic` file

```
RELEASE_NAME="db2u-cn1"
LICENSE_FILE="db2adv_vpc.lic"
oc delete configmap "${RELEASE_NAME}-db2u-lic"
oc create configmap "${RELEASE_NAME}-db2u-lic" --from-file=db2u-lic=${LICENSE_FILE}
#Db2 will need to restart to get the license apply.
#Restart db2u pods to pickup the new configmap and apply the license files.
oc delete pods "${RELEASE_NAME}-db2u-0"
```

### 4. Verify the production license
```
oc rsh db2u-deployment-db2u-0 /bin/bash -c "$DB2PATH/adm/db2licm -l"
```
Output:
```
Product name:                     "DB2 Advanced Edition"
License type:                     "Virtual Processor Core"
Expiry date:                      "Permanent"
Product identifier:               "db2adv"
Version information:              "11.5"
Enforcement policy:               "Hard Stop"
```
