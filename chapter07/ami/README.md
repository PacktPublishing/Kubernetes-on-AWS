# AWS EKS Node AMI

To support the other material in this Chapter this directory includes configuration for building an worker Node image.

## Deps

You will need [packer](https://www.packer.io/intro/getting-started/install.html) to be installed on your workstation.

## Usage

Assuming you have aws credentials setup / in your environment.

Run:
```
packer build node.json
```

An AMI with a name like this will be produced:

`eks-worker-ubuntu-xenial-16.04-amd64-k8s-{{k8s_version}}-{{timestamp}}`

The AMI will be copied to the regions where EKS is supported, currently `us-east-1` and `us-west-2`.

## Prior Art

AWS provide source for the "Supported" EKS worker node image here https://github.com/awslabs/amazon-eks-ami

I made reference to this config while building this image.

## Differences

This image differs from the "Offical" image in a few interesting ways.

* Ubuntu - The "Offical" AWS image uses Amazon Linux ... this is an example of using a different distro to achive the same ends. In my experiance Ubuntu (amongst others) is far more widely used that Amazon Linux, although this is really just a matter of preference.

* ekstrap - This image uses a tool I have developed called ekstrap to bootstrap the kuberntes config on boot. This removes the need for the operator to inject a script to do this into userdata. ekstrap also waits for the eks cluster to become avalible if it is being launched before nodes are attached to improve reliablity when launching a cluster from scratch.

* Where possible packaged versions of the requred tools are used. We are installing docker, kuberntes and ekstrap from package repos maintained by the upstream projects.
