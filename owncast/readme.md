
Follow the below steps and it'll setup Owncast for you automatically.

## Create your new server

1. Put in the hostname that you'll use for this server, such as owncast.mydomain.com.  This is used to automatically configure your new server for SSL.
1. Put in your email address, also used for SSL.
1. If you skip this hostname and email step your server will not get automatically configured for SSL.
1. Keep in mind when selecting a monthly plan that the more CPU you can provide, the better quality and flexibility you'll have in the end.  [Read more about CPU usage](https://owncast.online/docs/video/#cpu-usage-1?source=linodemarketplace) with Owncast.

## Setting up DNS

1. Copy the IP Address for your new server from the new server status page.
1. Login to your DNS provider for your hostname you specified above.
1. Add an "A Record" pointing to this ip address and the name you specified above (if you used owncast.mydomain.com then type in owncast).
1. Wait 5 minutes, but it may take longer depending on your DNS provider.
1. When `http://ipaddress:8080` in your browser loads then your install is complete.
1. Reboot your new server so the SSL proxy starts.

## Test

1. In your browser paste the `http://ipaddress:8080` and verify Owncast is running.
1. If you configured SSL by specifying a hostname, put that hostname in your browser to make sure you can access it via https.
1. [Start a stream](https://owncast.online/quickstart/startstreaming/?source=linodemarketplace) using your software to this hostname using abc123 as the stream key.

## Configure

With Owncast running you can begin to configure your new server by visiting the Admin located at `/admin`.  Visit the [Configuration Instructions](https://owncast.online/docs/configuration/?source=linodemarketplace) to learn how you can change your video settings, web page content, and more.

## Notes

* Owncast is installed in `/opt/owncast`.  You'll find all your data files there.  This is also where you can upgrade your Owncast server in the future.