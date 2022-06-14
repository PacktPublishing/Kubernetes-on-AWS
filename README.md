# Kubernetes on AWS

<a href="https://www.packtpub.com/virtualization-and-cloud/kubernetes-aws?utm_source=9781788390071"><img src="https://dz13w8afd47il.cloudfront.net/sites/default/files/imagecache/ppv4_main_book_cover/9781788390071--.png" alt="Kubernetes on AWS" height="256px" align="right"></a>

This is the code repository for [Kubernetes on AWS](https://www.packtpub.com/virtualization-and-cloud/kubernetes-aws?utm_source=9781788390071), published by Packt.

**Deploy and manage production-ready Kubernetes clusters on AWS**

## What is this book about?
Docker containers promise to radicalize the way developers and operations build, deploy, and manage applications running on the cloud. Kubernetes provides the orchestration tools you need to realize that promise in production.

This book covers the following exciting features:
* Learn how to provision a production-ready Kubernetes cluster on AWS
* Deploy your own applications to Kubernetes with Helm
* Discover strategies for troubleshooting your cluster and know where to find help with issues
* Explore the best ways to monitor your cluster and the applications running on it
* Supercharge your cluster by integrating it with the tools provided by the AWS platform

If you feel this book is for you, get your [copy](https://www.amazon.com/dp/1788390075) today!

<a href="https://www.packtpub.com/?utm_source=github&utm_medium=banner&utm_campaign=GitHubBanner"><img src="https://raw.githubusercontent.com/PacktPublishing/GitHub/master/GitHub.png" 
alt="https://www.packtpub.com/" border="5" /></a>


## Instructions and Navigations
All of the code is organized into folders. For example, Chapter05.

The code will look like the following:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-configmap
data:
  user_id.properties: |-
    {{- range $index, $user := .Values.users }}
    user.{{ $user }}={{ $index }}
    {{- end }}
```
**Following is what you need for this book:**
If you’re a cloud engineer, cloud solution provider, sysadmin, site reliability engineer, or developer with an interest in DevOps and are looking for an extensive guide to running Kubernetes in the AWS environment, this book is for you. Though any previous knowledge of Kubernetes is not expected, some experience with Linux and Docker containers would be a bonus.

With the following software and hardware list you can run all code files present in the book (Chapter 1-10).

### Software and Hardware List

| Chapter  | Software required                   | OS required                        |
| -------- | ------------------------------------| -----------------------------------|
| 1 to 10  | Kubernetes, AWS account, Minikube   | Windows                            |



### Related products <Other books you may enjoy>
* Effective DevOps with AWS - Second Edition [[Packt]](https://www.packtpub.com/virtualization-and-cloud/effective-devops-aws-second-edition?utm_source=9781789539974) [[Amazon]](https://www.amazon.com/dp/1789539978)

* Practical DevOps - Second Edition [[Packt]](https://www.packtpub.com/virtualization-and-cloud/practical-devops-second-edition?utm_source=9781788392570) [[Amazon]](https://www.amazon.com/dp/1788392574)

## Get to Know the Author
**Ed Robinson**
works as a senior site reliability engineer at Cookpad's global headquarters in Bristol, UK. He has been working with Kubernetes for the last three years, deploying clusters on AWS to deliver resilient and reliable services for global audiences. He is a contributor to several open source projects and is a maintainer of Træfɪk, the modern HTTP reverse proxy designed for containers and microservices





### Suggestions and Feedback
[Click here](https://docs.google.com/forms/d/e/1FAIpQLSdy7dATC6QmEL81FIUuymZ0Wy9vH1jHkvpY57OiMeKGqib_Ow/viewform) if you have any feedback or suggestions.
