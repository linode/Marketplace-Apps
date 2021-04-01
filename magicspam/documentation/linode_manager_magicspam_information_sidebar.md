# Highlight Text
Powerful Anti-Spam and Email Security solution for Control Panels (cPanel and Plesk).

# Main Text

MagicSpam stops inbound spam from entering your server right at the SMTP layer to lower bandwidth and overhead, as well as secure mailboxes on your server from being compromised and used to send outbound spam. MagicSpam installs directly onto the email server without any need to change A/MX records to protect unlimited users and domains. MagicSpam also integrates natively into the control panel interface and comes equipped with log and statistic modules to help with the management of an email server.

# More info
- [MagicSpam Webstore](https://www.magicspam.com/store.php)
- [MagicSpam for cPanel](https://www.magicspam.com/anti-spam-protection-cpanel.php)
- [MagicSpam for Plesk](https://www.magicspam.com/anti-spam-protection-plesk.php)
- [MagicSpam for cPanel Manual Installation Guide](https://www.magicspam.com/download/products/MSWHMC/InstallationGuide.pdf)
- [MagicSpam for Plesk Manual Installation Guide](https://www.magicspam.com/download/products/MSPPRO/InstallationGuide.pdf)

# Guides
- [An Introduction to MagicSpam](https://www.linode.com/docs/guides/...)
- [How to Deploy MagicSpam With Marketplace Apps](https://www.linode.com/docs/guides/deploy-magicspam-with-marketplace-apps/)
- [Running a Mail Server](https://www.linode.com/docs/guides/running-a-mail-server/)

# Tips
- The MagicSpam One-Click App installer requires a MagicSpam license key, which can be purchased through the MagicSpam Webstore.
- The MagicSpam One-Click App installer will also deploy the selected Control Panel (e.g. cPanel or Plesk).
- Please note that it will take approximately 15 minutes for the selected Control Panel and MagicSpam to boot after you launch.
- Once the script finishes, go to https://[your-Linode's-IP-address]:2087 (cPanel) or https://[your-Linode's-IP-address]:8443 (Plesk) in a browser, where you'll be prompted to log in and begin your trial.
- Your credentials are root for the username and the Root Password you defined when you ran the MagicSpam One-Click App installer.
- Follow the instructions in the 'Running a Mail Server' guide to send outbound email from your server as Linode restricts the email outbound connections ports 25, 465, and 587 by default.
- Follow the instructions in the 'MagicSpam Manual Installation Guides' to deploy MagicSpam onto an existing Linode running a supported Control Panel.
