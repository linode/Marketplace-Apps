## App Information

### App Name

Microweber

### App Description

Microweber is an easy Drag and Drop website builder and a powerful CMS of a new generation, based on the PHP Laravel Framework. 

You can use Microweber to quickly and simply make any kind of website, online store and blog. 

The Drag and Drop technology allows you to build your entrepreneurial presence on the internet – your new website – without any technical knowledge.
This is the Microweber Linode Marketplace application, it provides Microweber ready to be one-click installed.

### Check the video tutorial here

[Demo Video](https://www.youtube.com/watch?v=EKiaLcZkReM)

### Version Number

Latest Version

### Support URL

[Support](https://microweber.com/support)

### Operating System

Ubuntu 20.04 LTS

### Documentation

[Documentation](https://microweber.com/docs)

**In addition to the package installation, this one-click deploy also**

- Enables the UFW firewall to allow only SSH (port 22, rate limited), HTTP (port 80), and HTTPS (port 443) access.
- Sets the MySQL root password.
- Sets up the debian-sys-maint user in MySQL so the system’s init scripts for MySQL will work without requiring the MySQL root user password.
- Sets the cron required for background tasks.

**Microweber Server Details**

After you finish the installation, your Microweber website will be accessible at:

[http://your_linode_ipv4/](http://your_linode_ipv4/)


**Credentials**

Once you finish the installation, you can access your Mict website at:

**Extra-steps**

1. Provide HTTPS.

```sh
certbot --apache -d example.com -d www.example.com
```

1. Disable non-HTTPS access.

```sh
ufw delete allow 80/tcp
```

3. Secure MySQL.

```sh
mysql_secure_installation`
```
**Updates**
Microweber can update itself, simply  open [http://your_linode_ipv4/admin](http://your_linode_ipv4/admin) and click "check for updates" button.
### Brand Color 1 (HEX Code)
`#4592ff`
### Brand Color 2 (HEX Code)
`#4592ff`
