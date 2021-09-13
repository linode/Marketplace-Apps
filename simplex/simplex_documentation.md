---
slug: deploy-simplex-server-with-marketplace-apps
author:
  name: SimpleX
  email: chat@simplex.chat
description: 'SimpleX server is a message broker for SimpleX chat network - an open-source decentralized chat with a focus on users’ privacy.'
og_description: 'SimpleX Server is a message broker for SimpleX chat network - an open-source decentralized chat with a focus on users’ privacy.'
keywords: ["decentralized", "messaging", "server", "messaging server", "chat", "privacy", "open-source", "decentralized open-source chat", "simplex", "smp"]
tags: ["marketplace", "linode platform", "cloud manager"]
license: "AGPL v3"
published: 2021-09-12
modified_by:
  name: SimpleX
title: "Deploy SimpleX Server With Marketplace Apps"
h1_title: "How to deploy SimpleX Server with Marketplace apps"
enable_h1: true
contributor:
  name: Evgeny Poberezkin
  link: https://github.com/epoberezkin
external_resources:
- '[SimpleX Server source](https://github.com/simplex-chat/simplexmq)'
- '[SimpleX chat client for terminal](https://github.com/simplex-chat/simplex-chat)'
- '[simplex.chat website](https://simplex.chat)'
- '[SimpleX Messaging Protocol](https://github.com/simplex-chat/simplexmq/blob/master/protocol/simplex-messaging.md)'
---

## SimpleX Server Marketplace App

SimpleX Server is a message broker for SimpleX chat network - an open-source decentralized chat with a focus on users’ privacy.

SimpleX chat:
- ensures meta-data privacy by not using global user identities - no phone numbers, emails, usernames or any other globally unique identifiers.
- uses new [decentralized client-server network topology](https://github.com/simplex-chat/simplex-chat#network-topology) and privacy-preserving message routing protocol.
- has no dependence on DNS for the core network; optional DNS-based user addresses will be provided in the future to simplify the initial connections, but not for the message routing.

The terminal chat client is available in [simplex-chat repo](https://github.com/simplex-chat/simplex-chat) - you can either build it from source or download the binary for Linux, Windows or Mac from [the latest release](https://github.com/simplex-chat/simplex-chat/releases/latest).

### Deploy a SimpleX Server Marketplace App

<!-- shortguide used by every Marketplace app to describe how to deploy from the Cloud Manger -->

{{< content "deploy-marketplace-apps">}}

### SimpleX Server Options
<!-- The following table has three parts. The UDF name, in bold and in one column, followed by
     UDF description in the second column. The description is in normal text, with an optional
     "Required." tag at the end of the description, in italics, if the field is mandatory. -->
You can configure your SimpleX Server App by providing values for the following fields:

| **Field** | **Description** |
|:----------|:----------------|
| **enable_store_log** | Store log - persists SMP queues to append only log and restores them upon server restart. *Recommended*. |
| **api_token** | Linode API token - allows StackScript to create tags containing SMP server domain/ip address, transport key hash and server version. Use `domain#hash` or `ip#hash` as SMP server address in the client. Note: minimal permissions token should have are - read/write access to `linodes` (to update linode tags) and `domains` (to add A record to the domain hosted on Linode). *Required*. |
| **fqdn** | Fully qualified domain name - provide a third level domain name (e.g., smp.example.com) that will be added as an A record to the domain hosted on Linode. |

### Linode Options

After providing the App-specific options, provide configurations for your Linode server:
<!-- Be sure to edit the Select an Image and Linode Plan to match app's needs -->

| **Configuration** | **Description** |
|:------------------|:----------------|
| **Select an Image** | Ubuntu 20.04 LTS is currently the only image supported by the SimpleX Server Marketplace App, and it is pre-selected on the Linode creation page. *Required*. |
| **Region** | The region where you would like your Linode to reside. In general, it's best to choose a location that's closest to you. For more information on choosing a DC, review the [How to Choose a Data Center](/docs/platform/how-to-choose-a-data-center) guide. You can also generate [MTR reports](/docs/networking/diagnostics/diagnosing-network-issues-with-mtr/) for a deeper look at the network routes between you and each of our data centers. *Required*. |
| **Linode Plan** | Your Linode's [hardware resources](/docs/platform/how-to-choose-a-linode-plan/#hardware-resource-definitions). SimpleX Server can be supported on any size Linode (the servers we provide are deployed on 1Gb Linodes), but we suggest you deploy your SimpleX Server App on a Linode plan that reflects how you expect using it. If you decide that you need more or fewer hardware resources after you deploy your app, you can always [resize your Linode](/docs/platform/disk-images/resizing-a-linode/) to a different plan. *Required*. |
| **Linode Label** | The name for your Linode, which must be unique between all of the Linodes on your account. This name is how you identify your server in the Cloud Manager Dashboard. *Required*. |
| **Root Password** | The primary administrative password for your Linode instance. This password must be provided when you log in to your Linode via SSH. The password must meet the complexity strength validation requirements for a strong password. Your root password can be used to perform any action on your server, so make it long, complex, and unique. *Required*. |
| **SSH Keys** | SSH key to connect to your Linode. *Required*. |

> **Please note**: You will need root password and SSH key if you haven't provided a Linode API token to obtain a transport key hash - see [Use your SimpleX Server](#use-your-simplex-Server).

<!-- the following disclaimer lets the user know how long it will take
     to deploy the app -->
After providing all required Linode Options, click on the **Create** button. **Your SimpleX Server App will complete installation within 1-2 minutes after your Linode has finished provisioning**.

## Getting Started after Deployment
<!-- the following headings and paragraphs outline the steps necessary
     to access and interact with the Marketplace app. -->

### Use your SimpleX Server
Your new SimpleX Server is deployed on TCP port 5223 - it should be passed as a command line parameter to the [terminal SimpleX chat client](https://github.com/simplex-chat/simplex-chat):

```shell
simplex-chat -s <ip_address_or_domain>#<transport_key_hash>
```

Transport key hash can be obtained either from the deployed Linode tags (click on the tag with a long hash string and copy it's value from the browser address bar - it is quite tricky!) or by logging into your Linode via ssh (Linode has [a great guide about using SSH](https://www.linode.com/docs/guides/use-public-key-authentication-with-ssh/)) - the key hash will be shown in the server welcome message and it is also available in the file `/etc/opt/simplex/pub_key_hash`.

### Using SimpleX chat client

Terminal SimpleX chat client now supports groups and sending files.

To print all available command-line options use:

```
simplex-chat -h
```

To see how to establish the connection, use groups, send files and use all other chat functions, type `/h` command inside the chat.

See demo videos and full documentation in [SimpleX chat repo](https://github.com/simplex-chat/simplex-chat).

<!-- the following shortcode informs the user that Linode does not provide automatic updates
     to the Marketplace app, and that the user is responsible for the security and longevity
     of the installation. -->
{{< content "marketplace-update-note">}}
