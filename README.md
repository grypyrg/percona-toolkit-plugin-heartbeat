Percona Toolkit Plugin for *pt-heartbeat*
=========================================

This plugin adds support for *pt-heartbeat* monitoring when running *pt-table-checksum* and *pt-online-schema-change*.


How To Use
----------

First, configure the *pt-plugin-heartbeat.pm* file and specify the heartbeat table (default is *percona.heartbeat*).

Then run either *pt-online-schema-change* or *pt-table-checksum* with *--plugin='pt-plugin-heartbeat.pm'* option.


Percona Toolkit Version
-----------------------

This plugin does not work with Percona Toolkit (currently 2.2.7). A different code branch has been created to develop the feature: https://code.launchpad.net/~gryp/percona-toolkit/ptosc-lagwaiter-ptheartbeat/+merge/212652
This is expected to end up in Percona Toolkit Eventually.
