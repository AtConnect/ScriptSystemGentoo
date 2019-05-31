#!/usr/bin/perl -w

#------------------------------------------------------------------------------
use Getopt::Std;
use strict;

#------------------------------------------------------------------------------
# Options: Can be changed
#------------------------------------------------------------------------------

# Globals variables
my $asterisk_bin                = "/usr/bin/sudo asterisk";
my $asterisk_option             = "-rx";
my $asterisk_command_version    = "core show version";
my $asterisk_command_channels   = "core show channels";
my $asterisk_command_registry   = "pjsip show registrations";
my $asterisk_span_number        = 1;
my $asterisk_buddy_name         = "asterisk";
my $asterisk_warn_treshold      = "1000";
my $asterisk_crit_treshold      = "2000";


#------------------------------------------------------------------------------
# Options: Can NOT be changed
#------------------------------------------------------------------------------

# version
my $version = "1.2.9";

use vars qw( %opts);

my $STA_OK       = 0;
my $STA_WARNING  = 1;
my $STA_CRITICAL = 2;
my $STA_UNKNOWN  = 3;

my $STA_NOALERT = 10;
my $STA_ALERT   = 11;
my $STA_ERROR   = 12;

# Default return value for this plugin:
my $return = $STA_UNKNOWN;

my $output = "";

#------------------------------------------------------------------------------
# Functions
#------------------------------------------------------------------------------


sub checkAlert() {
        my ($value, $treshold) = @_;

        return $STA_NOALERT if ($treshold eq '');
        return $STA_ERROR if ($value !~ /^\-?[0-9]+$/);

        # e.g. "10"
        if ($treshold =~ /^(@?)(\-?[0-9]+)$/) {

                if ($1 ne '@' && ($value < 0 || $value > $2)) {
                        return $STA_ALERT;
                } elsif ($1 eq '@' && ($value >= 0 && $value <= $2)) {
                        return $STA_ALERT;
                } else {
                        return $STA_NOALERT;
                }

                # e.g. "10:" || ":10" || "~:10" || "10:~"
        } elsif ($treshold =~ /^(@?)(~?)(:?)(\-?[0-9]+)(:?)(~?)$/) {

                if ($3 eq ':' && $5 eq ':') {
                        return $STA_ERROR;
                } elsif ($2 eq '~' && $3 ne ':') {
                        return $STA_ERROR;
                } elsif ($5 ne ':' && $6 eq '~') {
                        return $STA_ERROR;
                } elsif ($2 eq '~' && $6 eq '~') {
                        return $STA_ERROR;
                } elsif ($1 ne '@' && ($3 eq ':' && $value > $4)) {
                        return $STA_ALERT;
                } elsif ($1 ne '@' && ($5 eq ':' && $value < $4)) {
                        return $STA_ALERT;
                } elsif ($1 eq '@' && ($3 eq ':' && $value <= $4)) {
                        return $STA_ALERT;
                } elsif ($1 eq '@' && ($5 eq ':' && $value >= $4)) {
                        return $STA_ALERT;
                } else {
                        return $STA_NOALERT;
                }

                # e.g. "10:20"
        } elsif ($treshold =~ /^(@?)(\-?[0-9]+):(\-?[0-9]+)$/) {

                if ($2 > $3) {
                        return $STA_ERROR;
                } elsif ($1 ne '@' && ($value < $2 || $value > $3)) {
                        return $STA_ALERT;
                } elsif ($1 eq '@' && ($value >= $2 && $value <= $3)) {
                        return $STA_ALERT;
                } else {
                        return $STA_NOALERT;
                }

        } else {
                return $STA_ERROR;
        }
}

sub setAlert() {
        my ($val, $wtresh, $ctresh) = @_;

        my $walert = &checkAlert($val, $wtresh);
        my $calert = &checkAlert($val, $ctresh);
        my $state;

        if ($walert == $STA_ALERT && $calert == $STA_ALERT) {
                $state = $STA_CRITICAL;
        } elsif ($walert == $STA_ALERT) {
                $state = $STA_WARNING;
        }
        $state = $STA_OK if ($walert == $STA_NOALERT);
        $state = $STA_UNKNOWN if ($walert == $STA_ERROR || $calert == $STA_ERROR);

        return $state;
}

#------------------------------------------------------------------------------
# Main program
#------------------------------------------------------------------------------

# --- Get options from the command line
my $asterisk_command     = $asterisk_command_version;
my $asterisk_command_tag = "version";
my $valid_opts           = 'hvc:s:p:b:w:x:';

getopts("$valid_opts", \%opts) or (printsyntax() and exit($return));

for my $option (keys %opts) {

        my $value = $opts{$option};

        if ($option eq 'h') {
                printsyntax();
                exit($return);

        } elsif ($option eq 'v') {
                printversion();
                exit($return);

        } elsif ($option eq 'c') {
                $asterisk_command_tag = $value;

                if ($value eq "channels") {
                        $asterisk_command = $asterisk_command_channels;
                } elsif ($value eq "peers") {
                        $asterisk_command = $asterisk_command_peers;
                } elsif ($value eq "peer") {
                        $asterisk_command = $asterisk_command_peer;
                } elsif ($value eq "jabber") {
                        $asterisk_command = $asterisk_command_jabber;
                } elsif ($value eq "konference") {
                        $asterisk_command = $asterisk_command_konference;
                } elsif ($value eq "zaptel") {
                        $asterisk_command = $asterisk_command_zaptel;
                } elsif ($value eq "span") {
                        $asterisk_command = $asterisk_command_span;
                } elsif ($value eq "dahdi") {
                        $asterisk_command = $asterisk_command_dahdi;
                } elsif ($value eq "dahdi_span") {
                        $asterisk_command = $asterisk_command_dahdi_span;
                } elsif ($value eq "pri_spans") {
                        $asterisk_command = $asterisk_command_pri_spans;
                } elsif ($value eq "pri_span") {
                        $asterisk_command = $asterisk_command_pri_span;
                } elsif ($value eq "registry") {
                        $asterisk_command = $asterisk_command_registry;
                } elsif ($value eq "version") {
                        $asterisk_command = $asterisk_command_version;
                } elsif ($value eq "calls") {
                        $asterisk_command = $asterisk_command_calls;
                } elsif ($value eq "failover") {
                        $asterisk_command = $asterisk_command_failover;
                } else {
                        printsyntax();
                        exit($return);
                }

        } elsif ($option eq 's') {

                # Set the SPAN number (with option -c span)
                $asterisk_span_number = $value;

        } elsif ($option eq 'p') {

                # Set the PEER name (with option -c peer)
                $asterisk_peer_name = $value;

        } elsif ($option eq 'b') {

                # Set the BUDDY name (with option -c jabber)
                $asterisk_buddy_name = $value;

        } elsif ($option eq 'w') {

                # Set warning treshold
                $asterisk_warn_treshold = $value if ($value ne '' && $value ne '-x');

        } elsif ($option eq 'x') {

                # Set critical treshold
                $asterisk_crit_treshold = $value if ($value ne '');

        } else {
                printsyntax();
                exit($return);
        }
}

#------------------------------------------------------------------------------
# Execute the appropriate asterisk command and analyze the result
#------------------------------------------------------------------------------

# --- CHANNELS ---
# Output example: "45 active channels 20 active calls 174 calls processed"
#
if ($asterisk_command_tag eq "channels") {

        $return = $STA_CRITICAL;
        $output = "Error getting channels";

        foreach (`$asterisk_bin $asterisk_option \"$asterisk_command\"`) {
                if (/channels/) {
                        $output = $_;
                } elsif (/calls/) {
                        $output .= $_;
                }
        }

        # Raise alert based on number of active channels
        $return = &setAlert($1, $asterisk_warn_treshold, $asterisk_crit_treshold)
          if ($output =~ /^([0-9]+)\ active channels/);

# --- PEERS ---
# Output example: "2 sip peers [Monitored: 1 online, 0 offline Unmonitored: 0 online, 1 offline]"
#
} elsif ($asterisk_command_tag eq "registry") {
    my $found=0;
    my $outputregistry = "";
    my $outputregistrydown = "";
    my $outputregistryup = "";
    my @arraynoms = (`$asterisk_bin $asterisk_option \"$asterisk_command\" | sed '1,4d' | sed '/^\$/d' | sed '\$d' | awk '{print \$2}'`);
    my @arraystatus = (`$asterisk_bin $asterisk_option \"$asterisk_command\" | sed '1,4d' | sed '/^\$/d' | sed '\$d' | awk '{print \$3}'`);
    my $longueurstatusgeneral = (`$asterisk_bin $asterisk_option \"$asterisk_command\" | sed '1,4d' | sed '/^\$/d' | sed '\$d' | awk '{print \$3}' | grep -v "Registered" | wc -l`);
    my $longueur = scalar(@arraynoms);
       
        my @tableau;
        my $nom = '';
        my $status = '';        
        for (my $i = 0; $i < $longueur; $i++){                
                $nom = $arraynoms[$i];
                $status = $arraystatus[$i];     
                $outputregistry = "Trunk $nom $status";
                $found++;                    
                push (@tableau, $outputregistry);  
         }
        
        if($longueurstatusgeneral == 0){
            $return = $STA_OK;
            $outputregistryup = "Statut Général : OK\n";
            print($outputregistryup);
        }else{
            $return = $STA_CRITICAL;
            $outputregistrydown = "Statut Général : DOWN\n";  
            print($outputregistrydown);
        }
        
        foreach $outputregistry (@tableau){
            print ($outputregistry);
        }

        if ($found == 0) {
            $return = $STA_WARNING;
            $output = "No Trunk was found";
        }

# --- VERSION ---
# Output example:
#
} elsif ($asterisk_command_tag eq "version") {

        $return = $STA_CRITICAL;
        $output = "Error getting version";

        foreach (`$asterisk_bin $asterisk_option \"$asterisk_command\"`) {
                if (/(Asterisk.*)\ built/) {
                        $return = $STA_OK;
                        $output = "$1";
                }
        }

# --- CALLS ---
# Output example: "Active calls: 5"
#
} elsif ($asterisk_command_tag eq "calls") {

        $return = $STA_CRITICAL;
        #$output = "Error getting calls";

        foreach (`$asterisk_bin $asterisk_option \"$asterisk_command\"`) {
            
                if (/active call/) {
                        $return = $STA_OK;
                        my @nb_calls = split(' ', $_);
                        $output = "Active calls : $nb_calls[0] | Nb_Calls=$nb_calls[0]";
                }
        }
# --- FAILOVER ---
# Output example: (./nagisk.pl -c failover)
# * DEVICE#1: openvox_failover_1 /dev/ttyUSB0 VERSION:1.5
#   INTERNAL:4000 EVENT: AUTORUN:no STATE:RUNNING
} 

# --- Print the command output on STDOUT
$output =~ s/\r|\n/\ /g;
print $output;

# --- Return appropriate Nagios code
exit($return);
