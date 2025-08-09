# aws-helper
## Documentations
* [AWS IRSA](./docs/IRSA.md)
## CLIs
### aws-toolkit
* Prerequisite
  * `aws` cli
  * `whiptail` (should be preinstalled in your system `sudo apt install whiptail`)
* Run
  ```Bash
    export AWS_ACCESS_KEY=<access key id>
    export AWS_SECRET_ACCESS_KEY=<secret access key>
    ./cmd/aws-toolkit.sh
  ```