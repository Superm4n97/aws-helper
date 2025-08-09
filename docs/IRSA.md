# AWS IRSA
### Prerequisite
### Installation
* Get cluster name and OIDC id
  ```shell
    cluster_name=<my-cluster>
    region=<cluster region>
    oidc_id=$(aws eks describe-cluster --name $cluster_name --region $region --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
    echo $oidc_id
    ```
  * Verify the OIDC already created or not
      ```shell
      aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
      ```
      * If the command does **not return the oidc id** then create one
        ```shell
          eksctl utils associate-iam-oidc-provider --cluster $cluster_name --region $region --approve
        ```
        * Else you already have the OIDC provider, don't need to do anything

* Create policy
  * Create a file (`my-policy.json`) with the following policy. Change the policy document according to your need.
      ```json
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": "s3:GetObject",
              "Resource": "arn:aws:s3:::my-pod-secrets-bucket"
            }
          ]
        }
    ```
  * Use the following command to create the policy
    ```Bash
    aws iam create-policy --policy-name my-policy --policy-document file://my-policy.json
    ```
* Create and associate IAM Role
  * Create a `trust-relationship.json` file with the following content:
      ```json
      {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": {
                  "Federated": "arn:aws:iam::<aws account id>:oidc-provider/oidc.eks.<region>.amazonaws.com/id/EXAMPLEFE73FC563CA68E53E92811BC1"
              },
              "Action": "sts:AssumeRoleWithWebIdentity",
              "Condition": {
                  "StringEquals": {
                      "oidc.eks.<region>.amazonaws.com/id/EXAMPLEFE73FC563CA68E53E92811BC1:sub": "system:serviceaccount:<service account namespace>:<service account name>",
                      "oidc.eks.<region>.amazonaws.com/id/EXAMPLEFE73FC563CA68E53E92811BC1:aud": "sts.amazonaws.com"
                  }
              }
          }
      ]
      }
      ```
    * If the trust relation is invalid or mistaken, you will see error like following: 
      ```Bash
      Not authorized to perform sts:AssumeRoleWithWebIdentity
      ```
  * Create the role with that `trust-relationship.json`
    ```shell
    aws iam create-role --role-name my-role --assume-role-policy-document file://trust-relationship.json --description "my-role-description"
    ```
  * Attach the policy using the policy arn:
    ```shell
    aws iam attach-role-policy --role-name my-role --policy-arn=<policy arn>
    ```
* Grab the role ARN from previous step and annotate your `Service Account`. Make sure the reference of this service account specified in your trust relationship audience.
    ```
    eks.amazonaws.com/role-arn: <role arn>
    ```