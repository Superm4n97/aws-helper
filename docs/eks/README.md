# EKS Cluster
## setup

<details>
<summary>Private cluster: a cluster with private endpoint</summary>

* Add ssh inbound rule in `bastion host sg` for port 22 to `all`
* Add outbound route to the `route table that is attached to instance`. Outbound route should permit all routes to `Internet Gateway`
  ```shell
  0.0.0.0/0     igw-049a4de6a24119e03
  ```
---
* Add inbound rule in `cluster security group` for port 443 and 33080 to the `bastion host security-group`
    ```shell
    HTTPS        TCP 443   sg-xxxxxxxxxxxxxxxxx / bastion-demo
    Custom TCP   TCP 33080 sg-xxxxxxxxxxxxxxxxx / bastion-demo
    ```
---
* SSH into the instance and run the `bastion-host-initial-setup.sh` file
* Create a `kubeconfig.yaml` file and paste the `kubeconfig` there
* Export these variables or you can add them in the .bashrc file
  ```shell
  export KUBECONFIG=/home/ubuntu/kubeconfig.yaml
  export AWS_ACCESS_KEY="xxxxxxxxxxxxxxxxx"
  export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxx"
  ```
</details>

* Install aws load balancer controller (`not recommended, use irsa or pod identity instead`)
  ```shell
  helm repo add eks https://aws.github.io/eks-charts
  helm repo update eks
  helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster name> \
  --set env.AWS_ACCESS_KEY=<access key id> \
  --set env.AWS_SECRET_ACCESS_KEY=<secret access key>
  ```
* Create Load Balancer service (`not recommended, use irsa or pod identity instead`)
  ```shell
  // export AWS_ACCESS_KEY="xxxxxxxxxxxxxxxxx"
  // export AWS_SECRET_ACCESS_KEY="xxxxxxxxxxxxxxxxx"
  helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
  helm repo update
  helm upgrade \
    --install aws-ebs-csi-driver \
    --namespace kube-system aws-ebs-csi-driver/aws-ebs-csi-driver
  ```

---
* Add annotation to default `storageclass` `gp2`
  ```shell
  storageclass.kubernetes.io/is-default-class: "true"
  ```
* Install EBS CSI driver
  ```shell
  kubectl create secret generic aws-secret --namespace kube-system --from-literal "key_id=${AWS_ACCESS_KEY_ID}" --from-literal "access_key=${AWS_SECRET_ACCESS_KEY}"
  
  helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
  helm repo update
  helm upgrade --install aws-ebs-csi-driver --namespace kube-system aws-ebs-csi-driver/aws-ebs-csi-driver
  ```
* Create selfhost ace installer using any one of the elastic ip
* Install cert-manager
  ```shell
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.3/cert-manager.yaml
  ```
* Install fluxCD
* Install Ace

---
### Testing
* [OPTIONAL] Add inbound rule to `eksctl-private-endpoint-nodegroup-ng-private-SG-SH8cNFoSeG3h` security group to allow access to the loadbalancer target
  ```shell
  HTTP  TCP  80  0.0.0.0/0
  ```
* Create Elastic IP's for per zone
  ```yaml
  apiVersion: v1
  kind: Service
  metadata:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
      service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
      service.beta.kubernetes.io/aws-load-balancer-eip-allocations: eipalloc-06c57e8b46d4610b3,eipalloc-08ffbdaa187791361
      service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-08217ae37faaa2959,subnet-0501521b14dadf232
    name: test-lb
  spec:
    selector:
      app.kubernetes.io/name: nginx
    ports:
      - protocol: TCP
        port: 80
        targetPort: 80
    type: LoadBalancer
  ---
  apiVersion: v1
  kind: Pod
  metadata:
    name: nginx
    labels:
      app.kubernetes.io/name: nginx
  spec:
    containers:
    - name: nginx
      image: nginx:1.14.2
      ports:
      - containerPort: 80
  ```
  Node Selector
  ```yaml
  nodeSelector:
    kubernetes.io/hostname: ip-192-168-117-6.us-west-1.compute.internal
  ```