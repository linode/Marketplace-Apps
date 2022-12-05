## Getting started with gopaddle

Once the gopaddle lite dashboard is available, developers can review the evaluation agreement, subscribe to the lite edition and get started with the containerization process.

### Pre-requisites
[Docker Access Token with Read & Write Permissions](https://www.docker.com/blog/docker-hub-new-personal-access-tokens/)
[GitHub Person Access Token for containerizing Private Repositories](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

### Containerize and Deploy

In the main dashboard, the Containerize and Deploy Quickstart wizard helps to onboard a Source Code project from GitHub using the GitHub personal access token, build and push the generated container image to the Docker Registry. Once the build completes, gopaddle generates the necessary YAML files and deploys the docker image to the local microk8s cluster. 

In the final step of the Containerize and Deploy Quickstart wizard, enable the option to skip the TLS verification. 


All the artificats generated during the process can be edited and re-deployed at a later stage.