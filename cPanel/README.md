## cPanel & WHM

The cPanel & WHM® Marketplace App streamlines publishing and managing a website on your Linode. cPanel & WHM is a Linux® based web hosting control panel and platform that helps you create and manage websites, servers, databases and more with a suite of hosting automation and optimization tools.

### Deploy a cPanel & WHM Marketplace App

The Linode Marketplace allows you to easily deploy software on a Compute Instance using the Cloud Manager. See [Get Started with Marketplace Apps](https://www.linode.com/docs/products/tools/marketplace/get-started/) for complete steps.

Log in to the [Cloud Manager](https://cloud.linode.com/) and select the Marketplace link from the left navigation menu. This displays the Linode Create page with the Marketplace tab pre-selected.

Under the Select App section, select the app you would like to deploy.

Complete the form by following the steps and advice within the [Creating a Compute Instance](https://www.linode.com/docs/guides/creating-a-compute-instance/) guide. Depending on the Marketplace App you selected, there may be additional configuration options available. See the [Configuration Options](https://www.linode.com/docs/products/tools/marketplace/guides/cpanel/#configuration-options) section below for compatible distributions, recommended plans, and any additional configuration options available for this Marketplace App.

Click the Create Linode button. Once the Compute Instance has been provisioned and has fully powered on, wait for the software installation to complete. If the instance is powered off or restarted before this time, the software installation will likely fail.

To verify that the app has been fully installed, see [Get Started with Marketplace Apps > Verify Installation](https://www.linode.com/docs/products/tools/marketplace/get-started/#verify-installation). Once installed, follow the instructions within the [Getting Started After Deployment](https://www.linode.com/docs/products/tools/marketplace/guides/cpanel/#getting-started-after-deployment) section to access the application and start using it.

{{< content "deploy-marketplace-apps">}}

### Linode Options

Provide configurations for your Linode server:
<!-- Be sure to edit the Select an Image and Linode Plan to match app's needs -->

| **Configuration** | **Description** |
|:--------------|:------------|
| **Select an Image** | Ubuntu 20.04 and CentOS 7 are supported by the cPanel & WHM Marketplace App. *Required*. |
| **Region** | The region where you would like your Linode to reside. In general, it's best to choose a location that's closest to you. For more information on choosing a DC, review the [How to Choose a Data Center](/docs/platform/how-to-choose-a-data-center) guide. You can also generate [MTR reports](/docs/networking/diagnostics/diagnosing-network-issues-with-mtr/) for a deeper look at the network routes between you and each of our data centers. *Required*. |
| **Linode Plan** | Your Linode's [hardware resources](/docs/platform/how-to-choose-a-linode-plan/#hardware-resource-definitions). cPanel & WHM can be supported on any size Linode, but we suggest you deploy your cPanel & WHM App on a Linode plan that reflects how you plan on using it. If you decide that you need more or fewer hardware resources after you deploy your app, you can always [resize your Linode](/docs/platform/disk-images/resizing-a-linode/) to a different plan. *Required*. |
| **Linode Label** | The name for your Linode, which must be unique between all of the Linodes on your account. This name is how you identify your server in the Cloud Manager Dashboard. *Required*. |
| **Root Password** | The primary administrative password for your Linode instance. This password must be provided when you log in to your Linode via SSH. The password must meet the complexity strength validation requirements for a strong password. Your root password can be used to perform any action on your server, so make it long, complex, and unique. *Required*. |

<!-- the following disclaimer lets the user know how long it will take
     to deploy the app -->
After providing all required Linode Options, click on the **Create** button. **Your cPanel & WHM App will complete installation anywhere between 10-15 minutes after your Linode has finished provisioning**.

## Getting Started after Deployment
<!-- the following headings and paragraphs outline the steps necessary
     to access and interact with the Marketplace app. -->
### Access your cPanel & WHM App
Your app is accessible at your Linode server IP address.
For more information, read our [How to Log in to Your Server or Account](https://docs.cpanel.net/knowledge-base/accounts/how-to-log-in-to-your-server-or-account/) and [Getting Started](https://docs.cpanel.net/whm/the-whm-interface/getting-started/) documentation.

<!-- the following shortcode informs the user that Linode does not provide automatic updates
     to the Marketplace app, and that the user is responsible for the security and longevity
     of the installation. -->
{{< content "marketplace-update-note">}}
