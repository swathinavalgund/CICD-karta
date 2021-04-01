#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Sys::Hostname;
use Getopt::Long;
use Pod::Usage;
use File::Find;
use Archive::Extract;
use FindBin;
use lib ($FindBin::Bin,                       # use when testing modules
         $FindBin::Bin."/../../lib/perlmod/Siebel",    # from script location in VOB
         $FindBin::Bin."/../lib/perlmod",".","/net/sdcnas06/vol/engfs02/tools/qf_ftp",
     $FindBin::Bin."/../lib","/net/sdc1001nap.us.oracle.com/vol/sdc60002vob/lib/perlmod","//sdc1001nap/sdc60002vob/lib/perlmod","/net/slciahb.us.oracle.com/vol/ccase/lib/perlmod","//slciahb/ccase/lib/perlmod",
         $FindBin::Bin."/../lib/perlmod/Siebel");         # from repository location
use Mail::Sendmail;
#use feature 'say';
#use XML::LibXML;

our ($run_status,$client_machine,$val3,$val4,$val1,$val2,$val,$masterDB,$curl,$recordid,$help) ;
our (@array);

GetOptions
(
   
    'recordid=s'                  => \$recordid,
	'help!'                       => \$help,
	
) or die "Incorrect usage!, please check help with perl --help usage\n";

$recordid =~ s/^\s+//;
$recordid =~ s/\s+$//;
#$masterDB = 'https://slc07hgm.us.oracle.com:16691/siebel' ;
$masterDB = 'https://slc11aml.us.oracle.com:4430/siebel' ;

#$curl="curl -k -X GET ".$masterDB."/v1.0/data/Keyword%20Automation/Automation%20Exec%20Config/".$recordid." -H \"Content-Type:application/json\" -H \"authorization:Basic R09XTEFLU0g6R09XTEFLU0gxMTQ=\" ";
$curl="curl -k -X GET ".$masterDB."/v1.0/data/Keyword%20Automation/Automation%20Exec%20Config/".$recordid."  -H \"Content-Type:application/json\" -H \"authorization:Basic R09XTEFLU0g6R09XTEFLU0gxMTQ=\" ";
print "curl :: $curl \n ";
$run_status = "XXX";
my @outtxt;
while ($run_status ne "Completed")
{ 
	my $exec=`$curl 2>&1`;
	#$exec =~ s/[\t"}\{\[\]]//g;
	#$exec=~s/[\n\t{\[\]]//g;$exec=~s/[\n\t}\[\]]//g;
	$exec =~ s/^\s+|\s+$//g ;
	@outtxt=split(/{"/,$exec);
	#print "$exec\n";
	print "STE runid is $recordid and $run_status\n";
	foreach my $txt (@outtxt)
	{
		$txt=~s/[\n\t"\[\]]//g;
		my @s = split(',',$txt);
		foreach my $v (@s)
		{
			if ((uc($v)  =~ /STATUS/) && (uc($v) !~ /MOBILESTATUS/))
			{
				my ($v1,$v2)=split(":",$v);
				$run_status=$v2;
				print "RUN_STATUS::$run_status\n";
			}
		}	
	}

	if ($run_status eq "Error" )
	{
		print "STE run is errored please login to masterdburl";
		&mailsend();
		exit;
	}
}

foreach my $text (@outtxt)
{
	$text=~s/[\n\t"\[\]]//g;
	#print "$text\n";#@array = $text;
	my @spl = split(',',$text);
	foreach $val (@spl)
	{
		if ((uc($val)  =~ /STATUS/) && (uc($val) !~ /MOBILESTATUS/))
		{
		($val1,$val2)=split(":",$val);
		#print "$val1\n";print "$val2\n";
		$run_status=$val2;
		print "RUN_STATUS::$run_status\n";
		
				}
		elsif (uc($val) =~ /TEST MACHINE/)
		{
		($val3,$val4)=split(":",$val);
		#print "$val3\n";print "$val4\n";
		$client_machine=$val4;
		print "CLIENT_MACHINE::$client_machine\n";
		my $report_loc = "\\\\$client_machine\\c\$\\STEReportsLogs\\$recordid";
		print "REPORT_LOCATION::$report_loc\n";
		
			#- code for unzip
		opendir(DIR, "$report_loc") or die "Cannot open the directory $report_loc for listing: $!";
		my @files = grep(/\.zip$/,readdir(DIR));
		closedir(DIR);
		foreach(@files)
		{
			chomp $_;
			my $input = "$report_loc/$_";
			my $output = $input;
			$output =~ s/.zip//;
			if ( ! -d $output )
			{
				my $x = Archive::Extract->new( archive => "$input" );
				$x->extract( to => "$output" ) or die $x->error;
			}
		}

		my $mFile;
	   
		my @dirs = "$report_loc";
		my @mList;
   
		find( sub{
			push @mList, $File::Find::name if -f $_ && $_ =~ /MasterSuite.*.xml$/ },
			@dirs );

    foreach(@mList)
	{
		print "XML Location: $_\n";
		chomp($_);
		my $xml_file = "$_";
		# my $xml_file = "\\\\slc10nrz.us.oracle.com\\c\$\\STEReportsLogs\\88-28LOO9/Reports_01202021124149/Reports/88-28LOO9_CORE_UIF_ATA5_MasterSuite_1.xml";

		open(contentXML,"<$xml_file") || die "Could not open the file $xml_file for reading: $!";
		chomp(my @lines = <contentXML>);
		close contentXML;

		sub mailsend() 
		{
			#my $os = $^O;
			my $sub = "CI/CD : STE Automation run ";
			
			my $to_list = "swathi.navalgund\@oracle.com,nagesh.shivanna\@oracle.com";
			my $MailFrom = "swathi.navalgund\@oracle.com,nagesh.shivanna\@oracle.com";
			#my $MailFrom = "siebel_atfqtp_autonotifyemail_grp\@oracle.com";
			  
			my $msg = "";
			$msg .="<html>";
			$msg .="<body>";
			$msg .=" Hi Team,<br><br>";
			$msg .= "Please find the Automation run-id : $recordid initiated for CICD <br><br>";
			$msg .= "Run-id status $run_status kindly login to MasterDB URL $masterDB to reinitiate<br><br>\n";
			$msg .= "</body>";
			$msg .="</html>";
				
			my %smail = (From => "$to_list",
			To => "$to_list",
			Subject => "$sub",
			Message => "$msg",
			Smtp => 'internal-mail-router.oracle.com',
			'Content-type' => 'text/html'
			);
			sendmail(%smail) || die $Mail::Sendmail::error;
			#sendmail(%smail) || die Mail::Sendmail::error;
	foreach(@lines)
	{
		#Spliting with the delimiter > and assigning to an array variable ie value 	
		my @value = split(/>/, $_);

		# getting Status
		#print " *** $value[18] *** \n";
		my @a1 = split(/"/, $value[18]);
		print "STATUS :: $a1[1] \n";

		# getting TOTAL_TC
		#print " *** $value[20] *** \n";
		my @a2 = split(/</, $value[20]);
		print "TOTAL_TC :: $a2[0] \n";

		# getting TOTAL_PASS_TC
		#print " *** $value[22] *** \n";
		my @a3 = split(/</, $value[22]);
		print "TOTAL_PASS_TC :: $a3[0] \n";

		# getting TOTAL_FAIL_TCation
		#print " *** $value[24] *** \n";
		my @a4 = split(/</, $value[24]);
		print "TOTAL_FAIL_TC :: $a4[0] \n";

		# getting TOTAL_NOTEXECUTED_TC
		#print " *** $value[26] *** \n";
		my @a5 = split(/</, $value[26]);
		print "TOTAL_NOTEXECUTED_TC :: $a5[0] \n";
	
	}

}
    
    		#print "REPORT_LOCATION::\\\\$client_machine\\c\$\\STEReportsLogs\\$recordid\n";
		
		}
	}
}
}


