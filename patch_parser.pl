#!/usr/bin/perl
use strict;
use warnings;
use Env;
use List::MoreUtils qw(uniq);
use Term::ANSIColor;
use Text::Table;




our $data =  `cat /etc/oratab`;
our @homes = ( $data =~ /:(.*)\:/g);
our @distinct_homes = uniq @homes;
our $ORACLE_HOME;
our $unix_path_variable;

our $hostname=`hostname`;
our $psu_patch_id;
our $psu_release_date;
our $one_off_patch_id;
our $one_off_patch_id2;
our $ojvm_patch_id;
our $ojvm_release_date;
our $instance_name;


#------------------------------------------------------------------------------------------#
# Declare table
#------------------------------------------------------------------------------------------#
our $tb = Text::Table->new(
    "instance_name","hostname",  "psu_patch_id", "psu_release_date", "ojvm_patch_id", "ojvm_release_date", "one_off_patch_id", "one_off_patch_id2"
);


open (FILE, "/etc/oratab") || die "Cannot open your file";

while (my $line = <FILE> )
{ 
  chomp $line;
  
  our @sid = $line =~ /^(.*?):\//;
  foreach  (@sid)
  {
	$instance_name = "$_ \n";
 	
          
	foreach (@distinct_homes)
	{

	  #------------------------------------------------------------------------------------------#
	  # Set up ORACLE_HOME
	  #------------------------------------------------------------------------------------------#
	   $ORACLE_HOME=$_;
	   chomp $ORACLE_HOME;
	   $ENV{ORACLE_HOME}=$ORACLE_HOME;


	  #------------------------------------------------------------------------------------------#
	  #Set up PATH
	  #------------------------------------------------------------------------------------------#
	   $unix_path_variable = $ENV{PATH} .= ":$ORACLE_HOME/bin";

	  #------------------------------------------------------------------------------------------#
	  # Get PSU Patch details
	  #------------------------------------------------------------------------------------------#
           
           #-- Check wether dbpsu or psu patch is being used
           our $cmd_dbpsu_or_psu = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i bundle | wc -l";
	   our $bundle_lines = `$cmd_dbpsu_or_psu`;

	   
	   if ($bundle_lines == 0 )
           {
	     #-- Patch number
	     our $psu_first_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 -m 1 update | grep -m 1 Patch";
	     our $get_first_line_string = `$psu_first_line_cmd`;

	     $psu_patch_id = substr($get_first_line_string, 7,12);

             #-- PSU release date
             my $psu_third_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 -m 1 update | grep -m 3 Update";
             my $get_third_line_string_psu = `$psu_third_line_cmd`;

             $psu_release_date = substr($get_third_line_string_psu, 58, 6);
 

           
           }
	   else 
           {
            #-- Patch number
            our $psu_first_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 -m 1 bundle | grep -m 1 Patch";
            our $get_first_line_string = `$psu_first_line_cmd`;
            
            $psu_patch_id = substr($get_first_line_string, 7,12);
		
	    #-- PSU release date
            my $psu_third_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i  -A 0 -B 0  -m 1 Bundle";
            my $get_third_line_string_psu = `$psu_third_line_cmd`;

            $psu_release_date = substr($get_third_line_string_psu, 54, 6);

           }
            





	  #-----------------------------------------------------------------------------------------#
	  #Get OJVM patch details
	  #-----------------------------------------------------------------------------------------#

	  #-- OJVM patch number
	  my $ojvm_first_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 -m 1 javavm | grep -m 1 Patch";
	  my $get_first_line_string_ojvm = `$ojvm_first_line_cmd`;

	  $ojvm_patch_id = substr($get_first_line_string_ojvm, 7,12);


	  #-- OJVM release date
	  my $ojvm_third_line_cmd  = "$ORACLE_HOME/OPatch/opatch lsinventory | grep -i -A 2 -B 2 javavm | grep -m 3 Component";
	  my $get_third_line_string_ojvm = `$ojvm_third_line_cmd`;

	  $ojvm_release_date = substr($get_third_line_string_ojvm, 43, 6);
	  
#-----------------------------------------------------------------------------------------#
#Get one off patch details
#-----------------------------------------------------------------------------------------# 



#-- one off patch details 
my  $one_off_cmd = "$ORACLE_HOME/OPatch/opatch lsinventory | grep Patch  | grep -v OPatch | grep -v Unique | grep -v Database | grep -v $ojvm_patch_id | grep -v $psu_patch_id | grep -v version";  

#-- check how many one off patches exist in the box
my  $one_off_counter = "$ORACLE_HOME/OPatch/opatch lsinventory | grep Patch  | grep -v OPatch | grep -v Unique | grep -v Database | grep -v $ojvm_patch_id | grep -v $psu_patch_id | grep -v version | wc -l";

my $one_off_patch_total = `$one_off_counter`;

if ($one_off_patch_total == 1) 
{

my $one_off_output = `$one_off_cmd`;
   
#-- logic to cater for when the one off patch was applied online 
   if ($one_off_output =~ m/online/) {
     $one_off_patch_id = substr($one_off_output, 14, 9);
     chomp $one_off_patch_id;
     
     $one_off_patch_id2 = " ";
   
   }
   else {
     $one_off_patch_id = substr($one_off_output, 7,12);
     $one_off_patch_id2 = " ";
   }	

}else 
{

my  $one_off_cmd_first = "$ORACLE_HOME/OPatch/opatch lsinventory | grep Patch  | grep -v OPatch | grep -v Unique | grep -v Database | grep -v $ojvm_patch_id | grep -v $psu_patch_id | grep -v version | head -1";

my $one_off_output1 = `$one_off_cmd_first`;
chomp $one_off_output1;


# -- deal with first one off patch 
if ($one_off_output1 =~ m/online/) {
  $one_off_patch_id = substr($one_off_output1, 14, 9);
  chomp $one_off_patch_id;


}
else {
  $one_off_patch_id = substr($one_off_output1, 7,12);
}


# -- deal with second one off patch

my  $one_off_cmd_second = "$ORACLE_HOME/OPatch/opatch lsinventory | grep Patch  | grep -v OPatch | grep -v Unique | grep -v Database | grep -v $ojvm_patch_id | grep -v $psu_patch_id | grep -v version | grep -v $one_off_patch_id";

my $one_off_output2 = `$one_off_cmd_second`;
chomp $one_off_output2;

if ($one_off_output2 =~ m/online/) {
  $one_off_patch_id2 = substr($one_off_output2, 14, 9);
  chomp $one_off_patch_id2;


}
else {
  $one_off_patch_id2 = substr($one_off_output2, 7,12);
  chomp $one_off_patch_id2;
}


































}














}
}

$tb->add($instance_name , $hostname, $psu_patch_id, $psu_release_date,$ojvm_patch_id, $ojvm_release_date, $one_off_patch_id, $one_off_patch_id2);

}
close (FILE);
print $tb;






