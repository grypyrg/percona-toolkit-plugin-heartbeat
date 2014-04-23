#!/usr/bin/env perl
# This test file requires a working Percona Toolkit test environment.


BEGIN {
   die "The PERCONA_TOOLKIT_BRANCH environment variable is not set.\n"
      unless $ENV{PERCONA_TOOLKIT_BRANCH} && -d $ENV{PERCONA_TOOLKIT_BRANCH};
   unshift @INC, "$ENV{PERCONA_TOOLKIT_BRANCH}/lib";
};


use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use Test::More;

use PerconaTest;
use Cwd;
use Sandbox;
require "$trunk/bin/pt-table-checksum";

use Data::Dumper;
$Data::Dumper::Indent    = 1;
$Data::Dumper::Sortkeys  = 1;
$Data::Dumper::Quotekeys = 0;

my $dp         = new DSNParser(opts=>$dsn_opts);
my $sb         = new Sandbox(basedir => '/tmp', DSNParser => $dp);
my $master_dbh = $sb->get_dbh_for('master');
my $slave_dbh  = $sb->get_dbh_for('slave1');

if ( !$master_dbh ) {
   plan skip_all => 'Cannot connect to sandbox master';
}
if ( !$slave_dbh ) {
   plan skip_all => 'Cannot connect to sandbox slave1';
}

my $cwd = getcwd();

my $output;
my $master_dsn = $sb->dsn_for('master');
my $slave_dsn  = $sb->dsn_for('slave1');
my $plugin = "$cwd/pt-plugin-heartbeat.pm";
my $exit;
my $rows;


# #############################################################################
# pttc-ptheartbeat.t
# #############################################################################

$master_dbh->prepare("drop database if exists percona")->execute();
$master_dbh->prepare("create database percona")->execute();
$master_dbh->prepare("create table if not exists percona.t ( a int primary key);")->execute();
$master_dbh->prepare("insert into percona.t values (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)")->execute();
$master_dbh->prepare("analyze table percona.t;")->execute();


system("$trunk/bin/pt-heartbeat -D percona --update $master_dsn --interval 6 --run-time 7 --create-table --daemonize");


# heartbeat is stopped, we wait for 2 seconds, so the max lag of 1 should be reached
# there's another 8 seconds that the tool will wait now, so we will have at least one
# time the lag will be too high
sleep 2;

($output) = full_output(
   sub { pt_table_checksum::main(
      "$master_dsn",
      '--max-lag', '1',
      '--progress', 'time,1',
      '--chunk-size', '1',
      '--plugin', "$plugin",
      '--databases', 'percona',
   )},
   stderr => 1,
);


my @called = $output =~ m/^PLUGIN .*$/gm;
is_deeply(
   \@called,
   [
      'PLUGIN get_slave_lag: pt-heartbeat will be checked',
   ],
   "Check if the pt-hearbeat plugin is properly enabled"
) or diag(Dumper($output));


my @replica_lag = $output =~ m/^Replica lag is/gm;
is_deeply(
   $replica_lag[0],
   'Replica lag is',
   "Check if replica lag happened"
) or diag(Dumper($output));


# #############################################################################
# Done.
# #############################################################################
# we wait another 2 seconds, then pt-heartbeat is done
sleep 2;

$sb->wipe_clean($master_dbh);
ok($sb->ok(), "Sandbox servers") or BAIL_OUT(__FILE__ . " broke the sandbox");
done_testing;
