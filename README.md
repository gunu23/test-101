# Migration guide from existing local Docker deployment to virtual DataPower conatainerized pods running on OpenShift

## Instuctions

**Pre-Reqs**

1. Install the version of [oc](https://docs.openshift.com/container-platform/4.10/cli_reference/openshift_cli/getting-started-cli.html) necessary to connect to your cluster and add it to your OS' path.

- Make sure you install the same version as the OpenShift Cloud Platform you will be connecting to.

2. Install [kubectl](https://kubernetes.io/docs/tasks/tools/) and add it to your OS' path.

3. If running on a newly created OC, make sure you also install [unzip](https://www.google.com/search?q=install+unzip)

4. If running on Linux, switch to the linux-sed-fix branch.

- `git checkout linux-sed-fix`

5. Config the git pre-commit hook to run scripts.

- Inside the root of this repo run
  ```
  git config core.hooksPath .githooks
  ```
- Then depending on your OS:
  - Mac/Linux
    ```
    chmod ug+x .githooks/pre-commit migrate-backup-dps.sh migrate-backup-route.sh migrate-backup-service.sh
    ```
  - Windows
    ```
    icacls .githooks/pre-commit migrate-backup-dps.sh migrate-backup-route.sh migrate-backup-service.sh /grant *S-1-1-0:F
    ```
    _Note: You may have to use the full path on Windows to correctly authorize the hook to run. We haven't had the ability to test this yet._

6. (Optional) If you haven't already, first follow the instructions at [datapower-local-dev](https://github.com/dal-datapower/datapower-local-dev) to create a local development DataPower container.

- You will need some of the resources generated from that container for deployment.

7. (Optional) If you are using a Windows machine, make sure that you have [WSL](https://docs.microsoft.com/en-us/windows/wsl/install) installed and that you can properly run Bash scripts.

- This repo's scripts have not been tested in a Windows WSL environment, and because of some of the syntax they contain, they may not work correctly.
- It is highly recommended to use this repo with a UNIX (Mac) or Linux OS.

**(IMPORTANT) Checking in/out DataPower backup zip files**

- Only either add or delete zip files to this repo. Do not do both operations on the same commit.
- Write git commits after adding or removing DataPower backup zip files into the root of this repo.
- This will ensure that the git pre-commit hook will properly run the necessary scripts to generate your resources.

**(IMPORTANT) Please do not rename any zip files between commits to ensure the git hook works correctly.**
Instead:

1. Move the zip file out of this repo's directory
2. Add & commit the changes
3. Rename the moved zip file
4. Move the renamed zip file back to this repo's directory
5. Add & commit the changes.

### Instructions for deploying DataPower manually on OpenShift Container Platform

**Pre-reqs**

1. Login to the OpenShift Web Console.

- Use the provided url, username and password from either the OpenShift installer, or an admin who holds the credentials.

2. Once logged in the the OpenShift Web Console, log in to the OpenShift CLI.

- In the upper right corner of the OpenShift Web Console select the IAM user and click "Copy login command" in the drop down menu.
- In the window that opens, copy the first CLI input and paste it into your CLI of choice.

**Instructions**

1. Install the IBM catalog source to expose IBM operators using the CLI.

- Inside the root of this repo run
  ```
  oc apply -f ibm-catalog-source.yaml
  ```

2. Install the DataPower operator on all namespaces using the Web Console.

- Under the "Administrator" tab select "Operators" and then "OperatorHub".
- In the search bar provided search for `datapower`.
- Select "IBM DataPower GateWay".
- Select "Install" and keep all defaults.
  - Make sure you are installing on all namespaces as you will not have to repeat this step for other backup zip file migrations.
  - If you do not wish to do this in your cluster then make sure to repeat this step for each subsequent zip file you wish to migrate.

3. (Optional) Create a new project namespace to deploy your instance to using the CLI.

- You will be using the "default" namespace if this action is not performed.

```
oc new-project <namespace>
```

4. Create a secret to pull the DataPower image from the IBM registry.

- If using an [IBM Entitlement Key](https://myibm.ibm.com/products-services/containerlibrary)
  ```
  oc create secret docker-registry \
    ibm-entitlement-key \
    --docker-username=cp \
    --docker-password=<entitlement-key> \
    --docker-server=cp.icr.io
  ```
  _Note: This is the most common usage._
- If attempting to run in any enivornment besides "nonproduction" refer to [Pulling images from the IBM Entitled Registry](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=features-entitled-registry) for instructions.
- If you want to use a custom Service Account, read the official documentation and edit the appropriate fields in the generated <zipfile>/<zipfile>-dps.yaml file according to the links below.
  - [Pulling images from the IBM Entitled Registry](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=features-entitled-registry) - scroll to "Using a custom Service Account"
  - [serviceAccountName](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=s-serviceaccountname-1)
  - [imagePullSecrets](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=s-imagepullsecrets-1)

5. Create an admin user credential secret.

```
oc create secret generic datapower-user --from-literal=password=admin
```

6. (Optional) Gather the keys and certificates you wish to use and create a secret from them.

- You will not have these if you are using the "validation-flow.zip".
- You might have these if you are working with a more involved domain.
- If your keys are formatted as .cert/.key then run this command.
  ```
  oc create secret tls <domain>-cert --key=/path/to/my.crt --cert=/path/to/my.key
  ```
- If they are not then run this command instead.
  ```
  oc create secret generic <domain>-cert --from-file=/path/to/cert --from-file=/path/to/key
  ```

7. Edit the "NAMESPACE" variable at the top of 'migrate-backup.sh' to reflect the namespace you created in the step above.

8. (Optional) If using your own exported zip file, edit the "PORTARR" variable at the top of 'migrate-backup.sh' with the ports you need to expose.

- Each port must either follow the naming convention of "http-<port>" or "https-<port>".
- Port "https-9090" is exposed for the DataPower UI.
- You may choose to remove if you want, as using the DataPower UI outside of testing purposes on OpenShift is an anti-pattern.
- Port "http-8001" is exposed for the "validation-flow" JSON Placeholder route.
- You should remove this route if you are not using the "validation-flow.zip"

9. Add and commit a DataPower exported zip file to this repository.

- An example is provided in the previous step in the [datapower-local-dev](https://github.com/dal-datapower/datapower-local-dev) as validation-flow.zip.
- You may use your own exported configuration as well.

10. (Optional) If you have a keys & certificates for a domain, edit `<zip-file-name>/<zip-file-name>-output/<zip-file-name>-dps.yaml` file and uncomment out the "certs" definition for the domain in question. Then add the name based on the secret(s) you created in step 6.

11. In your terminal, go into the "<zip-file-name>-output" folder and apply the domain configmaps.

```
cd <zip-file-name>
cd <zip-file-name>/<zip-file-name>-output
oc apply -f <domain>-cfg.yaml
oc apply -f <domain>-local.yaml
```

\_Note: If your zip file contains multiple domains, apply the other domains as well.

12. (Optional) Once those yamls are applied, check the cluster to ensure that everything looks correct.

```
oc get configmap
```

13. Create the DataPowerService resource in the cluster.

```
oc apply -f <zip-file-name>-dps.yaml
```

14. Create a service for the DataPowerService in the cluster.

```
oc apply -f <zip-file-name>-service.yaml
```

15. Create a route for the service you just created in the cluster.

- Check your file structure for multiple routes and apply them all.

```
oc apply -f <zip-file-name>-<port>-route.yaml
```

16. Either use the OpenShift web console or the command line to get the route's address.

- If using the web console, under the "Administrator" tab go to "Networking" and then select "Routes".
- If using the command line.
  ```
  oc get route
  ```

17. Navigate to the route's address to ensure that your DataPower instance is working.

### Instructions for deploying DataPower on OCP with GitOps

**Pre-reqs**

1. Ensure that you have ArgoCD correctly installed on your cluster by following the instructions at [multi-tenancy-gitops](https://github.com/dal-datapower/multi-tenancy-gitops), including changing any required "namespace" attributes.

2. If you haven't already, clone the [multi-tenancy-gitops-apps](https://github.com/dal-datapower/multi-tenancy-gitops-apps) repo into the parent directory of where this repo is currently located on your local machine.

- Having the correct folder structure is important for this repo's scripts to work properly.

3. Login to the OpenShift Web Console.

- Use the provided url, username and password from either the OpenShift installer, or an admin who holds the credentials.

4. Once logged in the the OpenShift Web Console, log in to the OpenShift CLI.

- In the upper right corner of the OpenShift Web Console select the IAM user and click "Copy login command" in the drop down menu.
- In the window that opens, copy the first CLI input and paste it into your CLI of choice.

**Instructions**

1. Install the IBM catalog source to expose IBM operators using the CLI.

- Inside the root of this repo run
  ```
  oc apply -f ibm-catalog-source.yaml
  ```

2. Install the DataPower operator on all namespaces using the Web Console.

- Under the "Administrator" tab select "Operators" and then "OperatorHub".
- In the search bar provided search for `datapower`.
- Select "IBM DataPower GateWay".
- Select "Install" and keep all defaults.
  - Make sure you are installing on all namespaces as you will not have to repeat this step for other backup zip file migrations.
  - If you do not wish to do this in your cluster then make sure to repeat this step for each subsequent zip file you wish to migrate.

3. (Optional) Create a new project namespace to deploy your instance to using the CLI.

- You will be using the "default" namespace if this action is not performed.

```
oc new-project <namespace>
```

4. Create a secret to pull the DataPower image from the IBM registry.

- If using an [IBM Entitlement Key](https://myibm.ibm.com/products-services/containerlibrary)
  ```
  oc create secret docker-registry \
    ibm-entitlement-key \
    --docker-username=cp \
    --docker-password=<entitlement-key> \
    --docker-server=cp.icr.io
  ```
  _Note: This is the most common usage._
- If attempting to run in any enivornment besides "nonproduction" refer to [Pulling images from the IBM Entitled Registry](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=features-entitled-registry) for instructions.
- If you want to use a custom Service Account, read the official documentation and edit the appropriate fields in the generated <zipfile>/<zipfile>-dps.yaml file according to the links below.
  - [Pulling images from the IBM Entitled Registry](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=features-entitled-registry) - scroll to "Using a custom Service Account"
  - [serviceAccountName](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=s-serviceaccountname-1)
  - [imagePullSecrets](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=s-imagepullsecrets-1)

5. Create an admin user credential secret.

```
oc create secret generic datapower-user --from-literal=password=admin
```

6. (Optional) Gather the keys and certificates you wish to use and create a secret from them.

- You will not have these if you are using the "validation-flow.zip".
- You might have these if you are working with a more involved domain.
- If your keys are formatted as .cert/.key then run this command.
  ```
  oc create secret tls <domain>-cert --key=/path/to/my.crt --cert=/path/to/my.key
  ```
- If they are not then run this command instead.
  ```
  oc create secret generic <domain>-cert --from-file=/path/to/cert --from-file=/path/to/key
  ```

7. Edit the "NAMESPACE" variable at the top of 'migrate-backup.sh' to reflect the namespace you created in the step above.

8. (Optional) If using your own exported zip file, edit the "PORTARR" variable at the top of 'migrate-backup.sh' with the ports you need to expose.

- Each port must either follow the naming convention of "http-<port>" or "https-<port>".
- Port 9090 is exposed for the DataPower UI.
- You may choose to remove if you want, as using the DataPower UI outside of testing purposes on OpenShift is an anti-pattern.

9. Add and commit a DataPower exported zip file to this repository.

- An example is provided in the previous step in the [datapower-local-dev](https://github.com/dal-datapower/datapower-local-dev) as validation-flow.zip.
- You may use your own exported configuration as well.

10. (Optional) Examine the file structure in the `multi-tenancy-gitops-apps` repo .

11. (Optional) If you have a keys & certificates for a domain, edit `multi-tenancy-gitops-apps/dp/environments/dev/datapower/datapower/<zip-file-name>-dps.yaml` file and uncomment out the "certs" definition for the domain in question. Then add the name based on the secret(s) you created in step 6.

12. Change directories to the `multi-tenancy-gitops-apps` repo in the terminal and commit and push the changes that have been automatically made.

- If your configuration is complex and other changes need to be made, please examine the files located in the `multi-tenancy-gitops-apps/dp/environments/dev/datapower` folders before commiting.

14. Refresh the changes with ArgoCD.

15. Either use the OpenShift web console or the command line to get the route's address.

- If using the web console, under the "Administrator" tab go to "Networking" and then select "Routes".
- If using the command line.
  ```
  oc get route
  ```

16. Navigate to the route's address to ensure that your DataPower instance is working.

## datapower-operator-scripts

Home of utility scripts for automating datapower-operator tasks.

## Debugging

### `must-gather.sh`

Use this script to gather all DataPower Operator related resources from your Kubernetes/OpenShift cluster.

For usage:

```
./must-gather.sh -h
```

Reference:

- [Guide: Domain configuration](https://www.ibm.com/docs/en/datapower-operator/1.6?topic=guides-domain-configuration)
- [DataPowerService API docs](https://www.ibm.com/docs/en/datapower-operator/1.6)
