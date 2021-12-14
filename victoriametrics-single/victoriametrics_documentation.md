## VictoriaMetrics Marketplace App

<!-- Intro paragraph describing the app and what it accomplishes. -->
VictoriaMetrics is a free [open source time series database](https://en.wikipedia.org/wiki/Time_series_database) (TSDB) and monitoring solution, designed to collect, store and process real-time metrics. 

It supports the [Prometheus](https://en.wikipedia.org/wiki/Prometheus_(software)) pull model and various push protocols ([Graphite](https://en.wikipedia.org/wiki/Graphite_(software)), [InfluxDB](https://en.wikipedia.org/wiki/InfluxDB), OpenTSDB) for data ingestion. It is optimized for storage with high-latency IO, low IOPS and time series with [high churn rate](https://docs.victoriametrics.com/FAQ.html#what-is-high-churn-rate). 

For reading the data and evaluating alerting rules, VictoriaMetrics supports the PromQL, [MetricsQL](https://docs.victoriametrics.com/MetricsQL.html) and Graphite query languages. VictoriaMetrics Single is fully autonomous and can be used as a long-term storage for time series.

[VictoriaMetrics Single](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html) = Hassle-free monitoring solution. Easily handles 10M+ of active time series on a single instance. Perfect for small and medium environments.

### Deploy a VictoriaMetrics Marketplace App

<!-- shortguide used by every Marketplace app to describe how to deploy from the Cloud Manger -->

{{< content "deploy-marketplace-apps">}}

### VictoriaMetrics Options

<!-- The following table has three parts. The UDF name, in bold and in one column, followed by
     UDF description in the second column. The description is in normal text, with an optional
     "Required." tag at the end of the description, in italics, if the field is mandatory. -->
You can configure your VictoriaMetrics App by providing values for the following fields:

| **Field** | **Description** |
|:--------------|:------------|
| **Hostname** | Your VictoriaMetrics Linode's hostname. *Required*. |

### Linode Options

After providing the App-specific options, provide configurations for your Linode server:
<!-- Be sure to edit the Select an Image and Linode Plan to match app's needs -->

| **Configuration** | **Description** |
|:--------------|:------------|
| **Select an Image** | Ubuntu 20.04 is currently the only image supported by the VictoriaMetrics Marketplace App, and it is pre-selected on the Linode creation page. *Required*. |
| **Region** | The region where you would like your Linode to reside. In general, it's best to choose a location that's closest to you. For more information on choosing a DC, review the [How to Choose a Data Center](/docs/guides/how-to-choose-a-data-center) guide. You can also generate [MTR reports](/docs/guides/diagnosing-network-issues-with-mtr/) for a deeper look at the network routes between you and each of our data centers. *Required*. |
| **Linode Plan** | Your Linode's [hardware resources](/docs/guides/how-to-choose-a-linode-plan/#hardware-resource-definitions). VictoriaMetrics can be supported on any size Linode, but we suggest you deploy your VictoriaMetrics App on a Linode plan that reflects how you plan on using it. If you decide that you need more or fewer hardware resources after you deploy your app, you can always [resize your Linode](/docs/guides/resizing-a-linode/) to a different plan. *Required*. |
| **Linode Label** | The name for your Linode, which must be unique between all of the Linodes on your account. This name is how you identify your server in the Cloud Manager Dashboard. *Required*. |
| **Root Password** | The primary administrative password for your Linode instance. This password must be provided when you log in to your Linode via SSH. The password must meet the complexity strength validation requirements for a strong password. Your root password can be used to perform any action on your server, so make it long, complex, and unique. *Required*. |

<!-- the following disclaimer lets the user know how long it will take
     to deploy the app -->
After providing all required Linode Options, click on the **Create** button. **Your VictoriaMetrics App will complete installation anywhere between 5-10 minutes after your Linode has finished provisioning**.

## Getting Started after Deployment

<!-- the following headings and paragraphs outline the steps necessary
     to access and interact with the Marketplace app. -->

### Config

VictoriaMetrics configuration is located at `/etc/victoriametrics/single/scrape.yml` on the droplet. 
This One Click app uses 8428, 2003, 4242 and 8089 ports to accept metrics from different protocols. It's recommended to disable ports for protocols which are not needed. [Ubuntu firewall](https://help.ubuntu.com/community/UFW) can be used to easily disable access for specific ports.

### Scraping metrics

VictoriaMetrics supports metrics scraping in the same way as Prometheus does. Check the configuration file to edit scraping targets. See more details about scraping at [How to scrape Prometheus exporters](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-scrape-prometheus-exporters-such-as-node-exporter).

### Sending metrics

Besides scraping, VictoriaMetrics accepts write requests for various ingestion protocols. This One Click app supports the following protocols:
- [Datadog](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-send-data-from-datadog-agent), [Influx (telegraph)](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-send-data-from-influxdb-compatible-agents-such-as-telegraf), [JSON](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-import-data-in-json-line-format), [CSV](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-import-csv-data), [Prometheus](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-import-data-in-prometheus-exposition-format)  on port :8428
- [Graphite (statsd)](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-send-data-from-graphite-compatible-agents-such-as-statsd) on port :2003 tcp/udp
- [OpenTSDB](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-send-data-from-opentsdb-compatible-agents) on port :4242
- Influx (telegraph) on port :8089 tcp/udp

See more details and examples in [official documentation](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html).

### UI

VictoriaMetrics provides a [User Interface (UI)](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#vmui) for query troubleshooting and exploration. The UI is available at `http://your_droplet_public_ipv4:8428/vmui`. It lets users explore query results via graphs and tables.

To check it, open the following in your browser `http://your_droplet_public_ipv4:8428/vmui` and then enter `vm_app_uptime_seconds` to the Query Field to Execute the Query.

Run the following command to query and retrieve a result from VictoriaMetrics Single with `curl`:

```bash
curl -sg http://your_linodes_ip_address_ipv4:8428/api/v1/query_range?query=vm_app_uptime_seconds | jq
```

### Accessing

Once the Droplet is created, you can use DigitalOcean's web console to start a session or  SSH directly to the server as root:

```bash
ssh root@your_linodes_ip_address_ipv4
```

### Next Steps

## For further documentation visit:

- [VictoriaMetrics documentation](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html)
- [Quick Start](https://docs.victoriametrics.com/Quick-Start.html)
- [VictoriaMetrics Articles](https://docs.victoriametrics.com/Articles.html)
- [Grafana Dashboards for VictoriaMetrics](https://grafana.com/grafana/dashboards/10229)

<!-- the following shortcode informs the user that Linode does not provide automatic updates
     to the Marketplace app, and that the user is responsible for the security and longevity
     of the installation. -->
{{< content "marketplace-update-note">}}