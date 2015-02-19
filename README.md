# Zabbix extensive BIND monitoring plugin (with LLD)

Extensive monitoring plugin for BIND, including operational status, metrics and zone validation (for warning and errors) by leveraging sleuth (http://atrey.karlin.mff.cuni.cz/~mj/sleuth/) and named-checkzone.

The zones monitoring/validation is implemented through an extensive use of the powerful low-level discovery feature available in Zabbix.

## Installation
Depending on how you distribute your plugins around and respective Zabbix configuration, you would at least need to set up the following userparameters on the agent side:

```
UserParameter=bind[*],<path_to_your_plugins>/bind.sh $1
UserParameter=bind.zones[*],<path_to_your_plugins>/bind.sh zones $1
UserParameter=bind.zones.discovery,<path_to_your_plugins>/bind.sh zones discovery
UserParameter=bind.zones.validate[*],<path_to_your_plugins>/bind.sh zones validate $2
UserParameter=bind.zones.errors[*],<path_to_your_plugins>/bind.sh zones errors $1
UserParameter=bind.zones.warnings[*],<path_to_your_plugins>/bind.sh zones warnings $1
```

You would then need to import the templates into Zabbix and link them to the hosts you wish to monitor. The Template-BIND_Zones_Validation would normally be linked only to the BIND master(s).

Ideally, you would also add the following value mappings before importing the templates, so that sampled values can be mapped to human readable states (makes latest data look prettier).

```
mysql> SELECT name, value, newvalue FROM valuemaps INNER JOIN mappings ON valuemaps.valuemapid = mappings.valuemapid WHERE name LIKE 'BIND%';
+--------------------------------+-------+----------+
| name                           | value | newvalue |
+--------------------------------+-------+----------+
| BIND - DNS zone validity check | 0     | OK       |
| BIND - DNS zone validity check | 1     | Failed   |
| BIND - DNS zone validity check | -1    | Absent   |
+--------------------------------+-------+----------+
```

## Configuration
BIND and sleuth are the only pre-requisites to have the plugin working.

You may need to adjust warning and errors classification in the sleuth main configuration file, typically located at /etc/sleuth.conf. For instance, if you don't mind having DNS records pointing to CNAME(s), you can set the pcname option to '.' (informational message).

As sleuth works by requesting zone transfers, you would need to allow the host in the allow-transfer BIND option.

## Screenshots

Dashboard example:

![ScreenShot](https://raw.github.com/m4ce/zabbix-bind/master/screenshots/zabbix-bind-dashboard.png)

BIND server generic monitoring:

![ScreenShot](https://raw.github.com/m4ce/zabbix-bind/master/screenshots/zabbix-bind-latest_data1.png)

BIND zones validation:

![ScreenShot](https://raw.github.com/m4ce/zabbix-bind/master/screenshots/zabbix-bind-latest_data2.png)

BIND zones errors and warnings:

![ScreenShot](https://raw.github.com/m4ce/zabbix-bind/master/screenshots/zabbix-bind-latest_data3.png)
