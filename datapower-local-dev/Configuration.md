### Configuration for ODF on OCP 4.10+
- Delete the existing `multi-tenancy-gitops` repo from your `GIT_ORG`
- Go to [Cloud Native Toolkit REP](https://github.com/cloud-native-toolkit/multi-tenancy-gitops) [Use this Template](https://github.com/cloud-native-toolkit/multi-tenancy-gitops/generate) & attach it to your existing `GIT_ORG`
- Then Clone the `multi-tenancy-gitops` repo down.
- Access the repo and `~/scripts` to run the `set-git-source.sh` script.
- Push the changes.
- Then make sure that your logged in, into the right cluster by typing
    
    ```bash
    oc project
    ```
- Then run another script to deploy `ODF` which is `infra-mod.sh`
- Push and refresh argo to see the changes.
