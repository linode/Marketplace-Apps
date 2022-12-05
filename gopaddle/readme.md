## Getting started with gopaddle

Once the gopaddle lite dashboard is available, developers can review the evaluation agreement, subscribe to the lite edition and get started with the containerization process.

<img width="865" alt="gp-evaluation-agreement" src="https://user-images.githubusercontent.com/74309181/205760559-478ebb58-d1fd-4517-ba1f-5710ed9694c6.png">


### Containerize and Deploy

In the main dashboard, the **Containerize and Deploy** Quickstart wizard helps to onboard a Source Code project from GitHub using the GitHub personal access token, build and push the generated container image to the Docker Registry. Once the build completes, gopaddle generates the necessary YAML files and deploys the docker image to the local microk8s cluster. 

#### Pre-requisites

[Docker Access Token with Read & Write Permissions](https://www.docker.com/blog/docker-hub-new-personal-access-tokens/)

[GitHub Person Access Token for containerizing Private Repositories](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

In the final step of the Containerize and Deploy Quickstart wizard, enable the option to **Disable TLS verification**. 

<img width="1409" alt="containerize-deploy-quickstart" src="https://user-images.githubusercontent.com/74309181/205758353-7ce833e6-e493-4680-b7e9-a04f43e541ff.png">

All the artificats generated during the process can be edited and re-deployed at a later stage.

### Kubernetes Templates - Marketplace

Under Templates, the Marketplace Applications hosts a variety of pre-built Kubernetes templates. Developers can subscribe to these templates and deploy them on the local microk8s cluster.

<img width="1445" alt="gp-app-templates-1" src="https://user-images.githubusercontent.com/74309181/205758999-2a50eac6-d292-4280-85dd-3d617eda623a.png">
