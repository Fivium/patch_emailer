#!/usr/bin/perl
use strict;
use warnings;
use Env;
use Term::ANSIColor;
use List::MoreUtils qw(uniq);
use Text::ASCIITable;
use MIME::Lite;

our $cmd_current_date = "date +\"%d-%m-%Y\"";
our $current_date = `$cmd_current_date` ;



#-- initialise tables
our $t = Text::ASCIITable->new({ headingText => "Oracle Patches Status as of  $current_date" });
$t->setCols("instance_name","hostname",  "psu_patch_id", "psu_release_date", "ojvm_patch_id", "ojvm_release_date", "one_off_patch_id", "one_off_patch_id2");

our $config_file = "/oracle/scripts/patch_parser/db_lookup.php";
our $patch_parser = "/oracle/scripts/patch_parser/patch_parser.pl";
our $cmd_cat = "cat $config_file | grep -i conn_str";
our @hosts = `$cmd_cat`;
our @host_list;
our $elem;
our $uniq_host;
our $stripped;
our $str;

#-- Define table columns
our $instance_name;
our $hostname;
our $psu_patch_id;
our $psu_release_date;
our $ojvm_patch_id;
our $ojvm_release_date;
our $one_off_patch_id;
our $one_off_patch_id2;



#-- Delete old logfile
our $cmd_del_log = "rm -f /oracle/scripts/patch_parser/*.log 2>/dev/null";
`$cmd_del_log`;


foreach $elem (@hosts)
{
   (my $stripped) = ($elem =~ /conn_str\>(.*)\:/);
   push @host_list, $stripped;
  
}
#-- get unique hostnames
   our @distinct_hosts = uniq @host_list;
   print "@distinct_hosts \n";

foreach $uniq_host (@distinct_hosts)
{
  print "Running Patch checker for $uniq_host \n";
  our $ssh_command = "ssh oracle\@$uniq_host perl < $patch_parser >> /oracle/scripts/patch_parser/patch.log";
  print "$ssh_command \n";
  system ($ssh_command);
}

#-- Delete column names
our $cmd_dele_col = "sed -i '/instance_name/d' /oracle/scripts/patch_parser/patch.log";
`$cmd_dele_col`;

#-- trim the spaced between each value in a row
our $cmd_trim_space = "tr -s \" \" < /oracle/scripts/patch_parser/patch.log > /oracle/scripts/patch_parser/opatch.log";
`$cmd_trim_space`;


#-- Format the values generated into tabularised form 
 
open (FILE, "/oracle/scripts/patch_parser/opatch.log") || die "Cannot open your file";
while (my $line = <FILE> )
{
    chomp $line;
    our @sid = $line =~ /^(.*?):\//;
    ($instance_name , $hostname, $psu_patch_id, $psu_release_date, $ojvm_patch_id, $ojvm_release_date, $one_off_patch_id, $one_off_patch_id2 ) = split / /, $line;

    $t->addRow($instance_name , $hostname, $psu_patch_id, $psu_release_date, $ojvm_patch_id, $ojvm_release_date, $one_off_patch_id,  $one_off_patch_id2);
}

print $t;

open(my $fh, '>', '/oracle/scripts/patch_parser/report.txt');
print $fh "$t";
close $fh;

#--------------------------------------------------------------------------------------------
#Email report to DBA's and Yao                                                              #
#-------------------------------------------------------------------------------------------
my $msg;
my $mail_host='';
my $report_filename_with_path = "/oracle/scripts/patch_parser/report.txt";
my $report_file_name= "report.txt";


$msg = MIME::Lite->new(
    From    => '',
    To      => '',
    Cc      => '', 
    Subject => 'Databases Patch Level',
    Type    => 'multipart/mixed'
);

$msg->attach (
  Type => 'TEXT',
  Data => 'See attachments'
);


$msg->attach (
    Type =>'text/html; charset="iso-8859-1"',
    Path => $report_filename_with_path,
    Filename => $report_file_name,
    Disposition => 'attachment'	
);




$msg->send('smtp', $mail_host);





