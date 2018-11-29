resource "local_file" "storage-classes" {
  content = <<YAML
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: general-purpose
  annotations:
    "storageclass.kubernetes.io/is-default-class": "true"
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp2
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: high-iops-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: io1
  iopsPerGB: "50"
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: medium-iops-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: io1
  iopsPerGB: "25"
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: throughput
provisioner: kubernetes.io/aws-ebs
parameters:
  type: st1
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: cold-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: sc1
YAML
  filename = "${path.module}/storage-classes.yaml"
  depends_on = ["local_file.kubeconfig"]

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${local_file.kubeconfig.filename} apply -f ${path.module}/storage-classes.yaml"
  }
}
