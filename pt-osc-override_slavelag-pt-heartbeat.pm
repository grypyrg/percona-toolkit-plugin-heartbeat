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

sub override_slavelag_check {
   my ($self, %args) = @_;
   print "PLUGIN override_slavelag_check: pt-heartbeat will be checked\n";

   return sub {
         my ($cxn) = @_;
         my $dbh = $cxn->dbh();
         if ( !$dbh || !$dbh->ping() ) {
            eval { $dbh = $cxn->connect() };  # connect or die trying
            if ( $EVAL_ERROR ) {
               chomp $EVAL_ERROR;
               die "Lost connection to replica " . $cxn->name()
                  . " while attempting to get its lag ($EVAL_ERROR)\n";
            }
         }
         my $sth = $dbh->prepare("SELECT min(unix_timestamp(now()) - unix_timestamp(concat(substr(ts,1,10), ' ', substr(ts,12,8)))) as lag_sec FROM percona.heartbeat");
         $sth->execute();
         my $res =  $sth->fetchrow_hashref();
         return $res->{lag_sec};
      };
}

1;
