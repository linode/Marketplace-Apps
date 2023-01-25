---
slug: deploy-easypanel-with-marketplace-apps
author:
  name: Linode Community
  email: docs@linode.com
description: "Deploy a Easypanel Server on Linode using Marketplace Apps."
og_description: "Deploy a Easypanel Server on Linode using Marketplace Apps."
keywords: ["easypanel", "docker", "self-hosted", "heroku"]
tags: ["marketplace", "linode platform", "cloud manager"]
license: "[CC BY-ND 4.0](https://creativecommons.org/licenses/by-nd/4.0)"
published: 2022-03-29
modified_by:
  name: Linode
title: "How to Deploy Easypanel With Marketplace Apps"
h1_title: "Deploying Easypanel With Marketplace Apps."
contributor:
  name: Linode
external_resources:
  - "[Easypanel Website](https://easypanel.io)"
  - "[Easypanel Documentation](https://easypanel.io/docs)"
---

## Easypanel Marketplace App

Easypanel is a modern server control panel which uses Docker under the hood. You can think of it as "self-hosted Heroku". It helps you deploy Node.js, Ruby, Python, PHP, Go and Java applications.

### Deploy a Easypanel Marketplace App

{{< content "deploy-marketplace-apps">}}

### Linode Options

After providing the App-specific options, provide configurations for your Linode server:

| **Configuration**   | **Description**                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| :------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Select an Image** | Ubuntu 20.04 LTS is currently the only image supported by the Easypanel Marketplace App, and it is pre-selected on the Linode creation page. _Required_.                                                                                                                                                                                                                                                                                                                        |
| **Region**          | The region where you would like your Linode to reside. In general, it's best to choose a location that's closest to you. For more information on choosing a DC, review the [How to Choose a Data Center](/docs/platform/how-to-choose-a-data-center) guide. You can also generate [MTR reports](/docs/networking/diagnostics/diagnosing-network-issues-with-mtr/) for a deeper look at the network routes between you and each of our data centers. _Required_.                 |
| **Linode Plan**     | Your Linode's [hardware resources](/docs/platform/how-to-choose-a-linode-plan/#hardware-resource-definitions). Easypanel can be supported on any size Linode, but we suggest you deploy your Easypanel App on a Linode plan that reflects how you plan on using it. If you decide that you need more or fewer hardware resources after you deploy your app, you can always [resize your Linode](/docs/platform/disk-images/resizing-a-linode/) to a different plan. _Required_. |
| **Linode Label**    | The name for your Linode, which must be unique between all of the Linodes on your account. This name is how you identify your server in the Cloud Manager Dashboard. _Required_.                                                                                                                                                                                                                                                                                                |
| **Root Password**   | The primary administrative password for your Linode instance. This password must be provided when you log in to your Linode via SSH. The password must meet the complexity strength validation requirements for a strong password. Your root password can be used to perform any action on your server, so make it long, complex, and unique. _Required_.                                                                                                                       |

After providing all required Linode Options, click on the **Create** button. **Your Easypanel App will complete installation anywhere between 2-5 minutes after your Linode has finished provisioning**.

## Getting Started after Deployment

After creating your Linode, you can access Easypanel using the IP address of your server on port 3000.

{{< content "marketplace-update-note">}}
