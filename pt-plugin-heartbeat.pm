
# #############################################################################
# The actual override_slavelag_check which is invoked by the plugin classes
# #############################################################################
{
package plugin_heartbeat;

sub get_slave_lag {
   my ($self, %args) = @_;
   # oktorun is a reference, also update it using $$oktorun=0;
   my $oktorun=$args{oktorun};
   
   my $heartbeattable="percona.heartbeat";

   print "PLUGIN get_slave_lag: pt-heartbeat will be checked\n";

   my $get_lag = sub {
         my ($cxn) = @_;
         my $dbh = $cxn->dbh();
   
         if ( !$dbh || !$dbh->ping() ) {
            eval { $dbh = $cxn->connect() };  # connect or die trying
            if ( $EVAL_ERROR ) {
               chomp $EVAL_ERROR;
               $$oktorun=0;
               die "Lost connection to replica " . $cxn->name()
                  . " while attempting to get its lag ($EVAL_ERROR)\n";
            }
         }

         # If replication is not running, then it should be properly reported

         my $slavestatus = $dbh->selectrow_hashref("SHOW SLAVE STATUS");
         if (     ($slavestatus->{slave_io_running} ne "Yes")
             ||   ($slavestatus->{slave_sql_running} ne "Yes") ) {
            return;
         }

         my $res = $dbh->selectrow_hashref(
            "SELECT min(unix_timestamp(now())
                        - unix_timestamp(
                           concat(substr(ts,1,10),
                                 ' ', 
                                 substr(ts,12,8)
                                 )
                           )
                     ) as lag_sec 
            FROM $heartbeattable");

         # we return oktorun and the lag
         return $res->{lag_sec};
   };

   return $get_lag;
}
}
1;
# #############################################################################
# pt_online_schema_change_plugin
# #############################################################################
{
package pt_online_schema_change_plugin;

use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use constant PTDEBUG => $ENV{PTDEBUG} || 0;

sub new {
   my ($class, %args) = @_;
   my $self = { %args };
   return bless $self, $class;
}

sub get_slave_lag {
   return plugin_heartbeat::get_slave_lag(@_);
}
}
1;

# #############################################################################
# pt_table_checksum_plugin
# #############################################################################
{
package pt_table_checksum_plugin;

use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use constant PTDEBUG => $ENV{PTDEBUG} || 0;

sub new {
   my ($class, %args) = @_;
   my $self = { %args };
   return bless $self, $class;
}

sub get_slave_lag {
   return plugin_heartbeat::get_slave_lag(@_);
}
}
1;
