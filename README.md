Percona Toolkit Plugin for *pt-heartbeat*
=========================================

This plugin adds support for *pt-heartbeat* monitoring when running *pt-table-checksum* and *pt-online-schema-change*.


How To Use
----------

First, configure the *pt-plugin-heartbeat.pm* file and specify the heartbeat table (default is *percona.heartbeat*).

Then run either *pt-online-schema-change* or *pt-table-checksum* with *--plugin='pt-plugin-heartbeat.pm'* option.