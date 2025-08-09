# aws-helper
## Documentations
* [AWS IRSA](./docs/IRSA.md)
---
## Scripts
### [oidc-provider](./scripts/oidc-providers.sh)
* List and Delete all oidc providers from your account
  ```shell
  export AWS_ACCESS_KEY=<access key id>
  export AWS_SECRET_ACCESS_KEY=<secret access key>
  ./cmd/oidc-providers.sh
  ```
---
## GUI
### aws-toolkit
* Details
  * OIDC provider
    * List
    * Delete
  * Instance
    * List
* Prerequisite
  * `aws` cli
  * `whiptail` (should be preinstalled in your system `sudo apt install whiptail`)
* Run
  ```Bash
    export AWS_ACCESS_KEY=<access key id>
    export AWS_SECRET_ACCESS_KEY=<secret access key>
    ./cmd/aws-toolkit.sh
  ```