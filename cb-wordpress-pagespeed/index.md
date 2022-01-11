---
slug: cb-wordpress-pagespeed
author:
  name: CodeBru
  email: support@codebru.com
description: "WordPress + mod_pagespeed. The mod_pagespeed included to the app increases website loading speed on-the-fly. No extra configuration needed."
keywords: ['wordpress','mod_pagespeed','seo','optimization']
tags: ["marketplace", "linode platform", "cloud manager"]
license: '[CC BY-ND 4.0](https://creativecommons.org/licenses/by-nd/4.0)'
published: 2022-01-11
title: "WordPress + mod_pagespeed"
contributor:
  name: Eduard Faber
  link: https://support.codebru.com/
external_resources:
- '[Wordpress](https://wordpress.com/)'
- '[Mod_pagespeed](https://www.modpagespeed.com/)'
---

WordPress is open source software you can use to create a beautiful website, blog, or app.

The mod_pagespeed included to the app increases website loading speed on-the-fly. No extra configuration needed. 

The one-click app also ships with YoastSEO and W3 Total Cache plugins. Redis server in installed and enabled for wordpress object cache in orders to increase performance. 

## Deploying the Harbor Marketplace App

{{< content "deploy-marketplace-apps-shortguide">}}

**Software installation should complete within 5-10 minutes after the Linode has finished provisioning.**

## Configuration Options

### WordPress Options

You can configure your WordPress App by providing values for the following fields:

| **Field** | **Description** |
|:--------------|:------------|
| **Linux User Name** | Username for your server user. *Required*. |
| **Linux User Password** | Password for your server user. *Required*. |
| **Website Domain** | Domain name of your new WordPress site. *Required* |
| **Wordpress Website Name** | Wordpress Website Name. *Required* |
| **Wordpress Admin Email** | E-Mail address for your WordPress admin user. *Required*. |
| **Wordpress Admin Username** | Username for your WordPress admin user. *Required*. |
| **Wordpress Admin Password** | Password for your WordPress admin user. *Required*. |
| **MySQL root Password** | The root password for your MySQL database. *Required*. |
| **Wordpress Locale** | Language for your new WordPress site. Locale value can be found on https://translate.wordpress.org/ |

### General Options

For advice on filling out the remaining options on the **Create a Linode** form, see [Getting Started > Create a Linode](/docs/guides/getting-started/#create-a-linode). That said, some options may be limited or recommended based on this Marketplace App:

- **Supported distributions:** Ubuntu 20.04 LTS
- **Recommended plan:** All plan types and sizes can be used.

## Getting Started after Deployment

### Accessing your WordPress Site

After WordPress has finished installing, you can access your WordPress site by copying your Linode’s IPv4 address and entering it in the browser of your choice. If you’ve set up DNS during installation, you can go to your domain name in the browser. To find your Linode’s IPv4 address:

1. Click on the Linodes link in the sidebar to see a list of all your Linodes.
2. Find the Linode you just created when deploying your app and select it.
3. Navigate to the Networking tab.
4. Your IPv4 address is listed under the Address column in the IPv4 table.
5. Copy and paste the IPv4 address into a browser window. You should see your WordPress site’s home page.
6. Once you have accessed your WordPress site via the browser, you can log in to the WordPress administrative interface and start personalizing your theme, creating posts, and configuring other parts of your site.
7. The address of the WordPress login page is http://< your IP address >/wp-login.php.


If you set up a domain during installation, you can access the login page at http://< your domain >/wp-login.php.
Enter the credentials you previously specified in the Wordpress Admin Username and Wordpress Admin Password fields when you deployed the app.

{{< content "marketplace-update-note-shortguide">}}
