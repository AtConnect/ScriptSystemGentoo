#!/usr/bin/perl -w
#
# Status of each Xivo/Wazo Services At Connect
#------------------------------------------------------------------------------
use Getopt::Std;
use strict;

#------------------------------------------------------------------------------
# Options: Can be changed
#------------------------------------------------------------------------------

# Globals variables
my $asterisk_bin                      = "/usr/bin/sudo";
my $asterisk_command_wazo_services    = "wazo-service status";


#------------------------------------------------------------------------------
# Options: Can NOT be changed
#------------------------------------------------------------------------------

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
my $asterisk_command = "";
#------------------------------------------------------------------------------
# Main program
#------------------------------------------------------------------------------
my $commandrequested = $ARGV[1];
if ($commandrequested eq "wazo-service"){
    $asterisk_command = $asterisk_command_wazo_services;
}elsif($commandrequested eq "asterisk-xivo-service"){
    $asterisk_command = $asterisk_command_xivo_services;
}

#------------------------------------------------------------------------------
# Execute the appropriate command
#------------------------------------------------------------------------------

# --- Wazo Services ---
# Output example: "Services OK"
#

if($commandrequested eq "wazo-service"){

        $return = $STA_CRITICAL;
        $output = "Error getting services";

        my $outputrunning = "";
        my $outputrunningdown = "";
        my $outputrunningup = "";
        my @arraynoms = (`$asterisk_bin $asterisk_command | awk '{print \$2}' | sed '1,3d'`);
        my @arraystatus = (`$asterisk_bin $asterisk_command | awk '{print \$1}' | sed '1,3d' | cut -d ' ' -f1`);
        my $statusgeneral = (`$asterisk_bin $asterisk_command | awk '{print \$1}' | sed '1,3d' | grep -v "running"`);
        my $longueurstatusgeneral = length($statusgeneral);
        my $longueur = scalar(@arraystatus);


        my @tableau;
        my $nom = '';
        my $status = '';   
            
        for (my $i = 0; $i < $longueur; $i++){
                
                $nom = $arraynoms[$i];
                $status = $arraystatus[$i];      
                $outputrunning = "Service $nom $status";                                       
                push (@tableau, $outputrunning);
        }
        
        if($longueurstatusgeneral == 0){
            $return = $STA_OK;
            $outputrunningup = "Statut Général Wazo : OK\n";
            print($outputrunningup);                       
        }else{
            $return = $STA_CRITICAL;
            $outputrunningdown = "Statut Général Wazo : DOWN\n"; 
            print($outputrunningdown); 
        }

        foreach $outputrunning (@tableau){
            print ($outputrunning);
        }

# --- Xivo Services ---
# Output example: "Services OK"
#
}elsif($commandrequested eq "asterisk-wazo-service") {

        $return = $STA_CRITICAL;
        $output = "Error getting services";

        my $outputrunning = "";
        my $outputrunningdown = "";
        my $outputrunningup = "";
        my @arraynoms = (`$asterisk_bin $asterisk_command | grep "asterisk" | awk '{print \$2}'`);
        my @arraystatus = (`$asterisk_bin $asterisk_command | grep "asterisk"  | awk '{print \$1}'`);
        
        my @tableau;
        my $nom = '';
        my $status = '';           
                        
                $nom = $arraynoms[0];
                $status = $arraystatus[0];      
                $outputrunning = "Service $nom $status";                                       
                push (@tableau, $outputrunning);
        
        
        if($status == "running"){
            $return = $STA_OK;
            $outputrunningup = "Statut Astersik : OK\n";
            print($outputrunningup);                       
        }else{
            $return = $STA_CRITICAL;
            $outputrunningdown= "Statut Astersik : DOWN\n";
            print($outputrunningup);
        }

        foreach $outputrunning (@tableau){
            print ($outputrunning);
        }


        
}




# --- Return appropriate Nagios code
exit($return);
