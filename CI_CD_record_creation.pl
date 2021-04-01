#!/usr/local/bin/perl
#
# Template for a typical perl script
# this is a collection of "best practices".
#
#------------------------------------------------------------------------

=pod

=head1 dbrefreshsubmit.pl

dbrefreshsubmit  -- Script for DB refresh

=head1 SYNOPSIS

  dbrefreshsubmit.pl [options] 

=head1 DESCRIPTION

This program will query two database one crated by David and Prashanth.   Then it will update App Exp DB with the information of db refreshed
The web page it upates is http://sdc60010vob.us.oracle.com:8888/apex/f?p=104:1:2211953417414506:::::

=head2 Options

=over

=item -?, --help

Display command line usage.

=item --man

Display the compleat manual for this program

=item -v, --verbose

Output in verbose mode


=back

=head2 Methodology

The script uses Cleartool find to search for files checked into a branch.   Then uses DBI module to query bugdb for information required and then to update 

App Exp DB wit the information.  Before inserting, the script will query App Exp DB for an existing record based on bug id.  If bug id exists, it will update 

that record with the new informatin.  The delivery date will not be changed in an update.

=head2 Environment

Script requires Perl 5.12.    You can install it from \\sdcnas06\engfs02\tools\perl512.  Script also requires ClearCase installed.  Script must be run
from re\utilities in using a view looking at main/LATEST
  

=head1 EXAMPLES

 
  perl appex.pl -b 11847297 -r jyeh,dev_jyeh_Bug11802930  -d port -f 8.1.1.5 -n build2 -e phho -c "a test"
  perl appex.pl --bug 11847297 -branch jyeh,dev_jyeh_Bug11802930  --delivery port --fpver 8.1.1.5 --buildnum build2 --eng  phho --comments "a test"
  

=head1 SEE ALSO

L<DBI::Oracle>

=head1 BUGS

Number of files in a branch can exceed the 4000 character limit for the field in App Exp causing an update failure.   

=cut

#require 5.12.3;
 

$l = 1;

# Where to find our own libraries.  Should be able to find them
# both from the script's original location in the vob, and also
# from the script storage area at a site's repository.
#use strict;
=pod
use FindBin;
use lib ($FindBin::Bin,                       # use when testing modules
	 $FindBin::Bin."/../../lib/perlmod/Siebel",    # from script location in VOB
         $FindBin::Bin."/../lib/perlmod",".","/net/sdcnas06/vol/engfs02/tools/qf_ftp",
     $FindBin::Bin."/../lib","/net/sdc1001nap.us.oracle.com/vol/sdc60002vob/lib/perlmod","//sdc1001nap/sdc60002vob/lib/perlmod",
	 $FindBin::Bin."/../lib/perlmod/Siebel");         # from repository location
 

=cut

use FindBin;
use lib ($FindBin::Bin,                       # use when testing modules
	 $FindBin::Bin."/../../lib/perlmod/Siebel",    # from script location in VOB
         $FindBin::Bin."/../lib/perlmod",".","/net/sdcnas06/vol/engfs02/tools/qf_ftp",
     $FindBin::Bin."/../lib","/net/sdc1001nap.us.oracle.com/vol/sdc60002vob/lib/perlmod","//sdc1001nap/sdc60002vob/lib/perlmod","/net/slciahb.us.oracle.com/vol/ccase/lib/perlmod","//slciahb/ccase/lib/perlmod",
	 $FindBin::Bin."/../lib/perlmod/Siebel");         # from repository location

use DBI;
use Getopt::Long;
use Pod::Usage;
use Mail::Sendmail;
use List::MoreUtils 'all';
#use warnings;

# setup my defaults

our ($codeline,$url,$perlpath,$os,$server_type1,$server_home_path,$buildlabel,$app_version,$entserver,$install_status1,$osplatform,$login_id1,$db_platform,$db_details,$db_user_detail,$server_login_credential,$gateway_machine,$application_type,$client_OS,$gatewayport,$id1,$tblo1,$buildnumber,$runstatus,$buildtype,$prod,$buildnum,$osverion,$typerun,$machine,$filename,$osVer,$login,$dbasename,$webSerApp,$webSerOS,$lang,$eatcount,$dbname,$totaleatcount,$buildstartdate,$language,$setflag,$ui,$srf,$runsuite,$msg,$runstatus,$sub,$buildcodeline,$buildlabel,$buildtype,$buildlabels,$servers,$platform,$runtype,$dbserver1,$instance1,$port1,$dbversion1,$osVersion1,$help);
our (%dbmapping,%urllist,%prodhostmapping,%database);
our (@submissiontext,@submissiontxt,@urllists);

our ($SEL1,$SEL2);
our ($prod,$productcount,$server_os,$siebelserver,$httpsport,$os);
our (@productlist) ;

our $path = "c:\\sowmya";
#our $path = "\\slc07fkq\c$\sowmya";
our $soap_content = "soap_content.json";
our $result_content = "result_content.json";

our ($password,$val1,$val2,$val3,$prod1,$curl1,$complete_submission_content,$final_user_list,$user_value,$final_server_cred_list,$ser_cred_val,$serverval,$complete_second_submission_content,$second_submission_content,$valuename1,$valuename2,$valuename3,$servercredlist,$userlist,$oldrecordid,$recordid,$complete_applet_content,$curl,$masterDB,$firstappletvalue,$server_applet_text,$server_applet_content,$appval,$appurl,$gatewayport,$application_url,$second_applet,$Server_applet_count,$bip_credentials,$tools_credentials,$prod,$first_applet,$httpsport,$siebelserver,$hostname,$productcount,$productname,$conf,$patchsetCodeline,$qfCodeline,$build_number,$qfName,$codeline,$siebelBuildNumber,$enableCompGroupsSIA);
our (@usercred,@userapplet,@userarray,@productlist,@serverarray,@server_credential);
our (@BIP);
our (@CORE_OM,@CORE_SCRIPTING,@PLATFORMDB,@CORE_WORKFLOW,@CORE_FIND_SEARCH,@CORE_WSUI_LOVSEED_CRUD_DR,@CORE_WSUI_LOVSEED_CRUD_RR,@CALLCENTER,@CALENDAR_1,@CALENDAR,@CORE_SERVER_WS,@CORE_WSUI_ACCEPTANCE,@CORE_WS_WORKSPACE_TOOLS,@SMC  );
our (@CG,@TNT,@LOYALTY,@CLINICAL);
our (@HTIM,@EAUTO,@PS,@SRVC_INVT_SOLN,@SRVC_ASSETS_SR,@SRVC_ENGINES,@ATA_FASTANDFURIOUS) ;
our (@LILT_DR,@LILT_RR);
our (@PSR_ClickStream_EAT);
our (@ACS_SALES_DELIVERY,@KEYWORDS_HEALTH_CHECK,@PHARMA1,@PHARMA2,@ACS_CONTENT,@FINS1,@FINS2,@SALES,@PRM,@ACS_FINS,@MARKETING,@SMC ) ;
our (@CICD_CME,@CME,@COM_MAVEN,@COM_MAVERICK1,@COM_MAVERICK2,@COM_MAVERICK3,@ATA_MAVERICK1,@ATA_MAVERICK2,@COM_SETANTA1,@COM_SETANTA2,@COM_SETANTA3,@COM_AIA2,@COM_AIA1 ) ;
our (@SERVICEM_PRESETUP,@CORE_UIF_EDITWEBLAYOUT_ODHEDITOR,@CORE_UIF_CHARTS_UIFRAGMENTS,@CORE_UIF_BATCH,@CALLCENTER_TRANSFORMERS_KWD,@CORE_UIF_NEWAUTOMATION_18,@CORE_UIF_NEWFEATURES_MONTHLYUPDATES,@CORE_LOV_INTEG,@CORE_UIF_ATA,@IP19_AutoTile_MS,@CORE_UIF_ATA1,@CORE_UIF_ATA2,@CORE_UIF_ATA3,@CORE_UIF_ATA4,@CORE_UIF_ATA5,@CORE_UIF_ATA6,@CORE_AULI,@CORE_UIF1,@CORE_UIF2,@CORE_UIF3,@CORE_UIF5) ;

GetOptions
(
   
    'buildlabel=s'                  => \$buildlabel,
	'app_version=s'					=> \$app_version,
	'hostname=s'					=> \$hostname,
	'loginid=s'						=> \$login_id,
	'language=s'					=> \$language,
	'installedpath=s'				=> \$installedpath,
	'ai_port=s'						=> \$ai_port,
	'gtw_port=s'					=> \$gtw_port,
	'mastersuite=s'					=> \$comp_grp,
	'server_os=s'					=> \$os,	
	'oldrecordid=s'                 => \$oldrecordid,
	'help!'                         => \$help,
	
) or die "Incorrect usage!, please check help with perl --help usage\n";

$masterDB = 'https://slc11aml.us.oracle.com:4430/siebel';

$buildlabel =~ s/^\s+//; 
$buildlabel =~ s/\s+$//; 
$app_version =~ s/^\s+//; 
$app_version =~ s/\s+$//; 
$hostname =~ s/^\s+//; 
$hostname =~ s/\s+$//; 
$installedpath =~ s/^\s+//; 
$installedpath =~ s/\s+$//;
$ai_port =~ s/^\s+//; 
$ai_port =~ s/\s+$//;
$gtw_port =~ s/^\s+//; 
$gtw_port =~ s/\s+$//;
$login_id =~ s/^\s+//; 
$login_id =~ s/\s+$//;
$language =~ s/^\s+//; 
$language  =~ s/\s+$//;
$os =~ s/^\s+//; 
$os =~ s/\s+$//;
$oldrecordid =~ s/^\s+//; 
$oldrecordid =~ s/\s+$//;
$httpsport = $ai_port;
$gatewayport = $gtw_port;
#$str1=~ s/^\s+//; 
&RESERVE_INFO_RECORD_QUERY();

sub RESERVE_INFO_RECORD_QUERY
{
	print "CICD Automation run\n";
	$application_type="Desktop_Chrome";
	#$application_type="Desktop_Firefox";
	$client_OS="Windows";
	print "products enabled on this server :: $comp_grp \n";
	#$comp_grp = $_ ;
	$comp_grp =~ s/^\s+|\s+$//g ;
	print "________________________________________________________________________\n";
	print "Product :: $comp_grp \n";
	
	&generate_first_applet();
	&generate_complete_applet_content();
	print "Mastersuite name : $comp_grp \n" ;
	&curl_first_record_creation_module();
	&second_record_creation_module();
	&run_id_submission();
	#&UPDATE_FULL_RUN_STATUS();
	print "_____________________________________________________\n";
		

}

sub generate_first_applet
{
		#my $fh;
		undef $firstappletvalue;
		$perl_path ="\\\\\\\\slcnas607\\\\karta\\\\ATF_QTP\\\\Perl\\\\bin\\\\perl.exe";
		$build_number = $app_version;
		$siebelserver = $hostname;
		print "APPLICATION VERION ::$build_number\n";
		print "HOST NAME ::$siebelserver\n";
		
		if ( uc($comp_grp) =~ /BIP/ )
		{
			$bip_credentials = '"BIP Outbound WS" : "http://slcopio/bip",'."\n".'"BIP Server Name" : "bipserver",'."\n".'"BIP Server Port" : "9090",'."\n".'"BIP XMLP Server" : "slc09cpo.us.oracle.com",'."\n".'"BIP XMLP Server Port" : "9090",'."\n".'"BIP User Name" : "user1",';
			$firstappletvalue.='"Application Version" : "'.$build_number.'",'."\n".'"Master Suite Name" : "'.$comp_grp.'",'."\n".'"Client OS" : "Windows",'."\n".'"Perl Path" : "'.$perl_path.'",'."\n".''.$bip_credentials.''."\n".'"EAI Machine Name" : "'.$siebelserver.'",'."\n".'"EAI Port Number" : "'.$httpsport.'",'."\n".'"EAI User Name":"sadmin",'."\n".'"ServerCredentials" :';
			#$firstappletvalue.='"Application Version" : "'.$build_number.'",'."\n".'"Master Suite Name" : "'.$comp_grp.'",'."\n".'"Client OS" : "Windows",'."\n".'"Perl Path" : "'.$perl_path.'",'."\n".''.$tools_credentials.','."\n".'"EAI Machine Name" : "'.$siebelserver.'",'."\n".'"EAI Port Number" : "16690",'."\n".'"EAI User Name":"sadmin",'."\n".'"Run Reference":"KARTA_CICD",'."\n".'"ServerCredentials" :';
			#&print_first_applet();
			&server_applet_list();
			
		}
		else
		{
			#$tools_credentials = '"Siebel Tools Machine" : "'.$siebelserver.'",'."\n".'"Siebel Tools Path" : "'.$server_home_path.'",'."\n".'"Siebel Tools User Name" : "oradev\\\\intbuild",'."\n".'"Siebel Tools DSN" : "Siebel_dsn",'."\n".'"Siebel Tools DSN User" : "sadmin"';
			$tools_credentials = '"Siebel Tools Machine" : "'.$hostname.'",'."\n".'"Siebel Tools Path" : "'.$installedpath.'",'."\n".'"Siebel Tools User Name" : "oradev\\\\intbuild",'."\n".'"Siebel Tools DSN" : "Siebel_dsn",'."\n".'"Siebel Tools DSN User" : "sadmin"';
			#$firstappletvalue.='"Application Version" : "'.$build_number.'",'."\n".'"Master Suite Name" : "'.$comp_grp.'",'."\n".'"Client OS" : "Windows",'."\n".'"Perl Path" : "'.$perl_path.'",'."\n".''.$tools_credentials.','."\n".'"EAI Machine Name" : "'.$siebelserver.'",'."\n".'"EAI Port Number" : "'.$aiport.'",'."\n".'"EAI User Name":"sadmin",'."\n".'"Run Reference":"KARTA_CICD",'."\n".'"ServerCredentials" :';
			$firstappletvalue.='"Application Version" : "'.$build_number.'",'."\n".'"Master Suite Name" : "'.$comp_grp.'",'."\n".'"Client OS" : "Windows",'."\n".'"Perl Path" : "'.$perl_path.'",'."\n".''.$tools_credentials.','."\n".'"EAI Machine Name" : "'.$siebelserver.'",'."\n".'"EAI Port Number" : "16690",'."\n".'"EAI User Name":"sadmin",'."\n".'"Run Reference":"KARTA_CICD",'."\n".'"ServerCredentials" :';
			&server_applet_list();
		}
		
}


sub print_first_applet
{
	print "FIRST APPLET FILE CONTENT ::\n";
	print "_____________________________________________________\n";
	print "$firstappletvalue\n" ;
}



sub server_applet_list
{
	my $Server_applet_array_count;
	$server_applet_text='';
	#print "Inside Server Applet List Subrutine \n";
	#print "Master Suite Name : $prod \n";
	if (uc($comp_grp) eq "CORE_UIF1")
	{
		@CORE_UIF1 = ("CORE_UIF:callcenter","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF1 ;
		my @applet_list=split(",",@CORE_UIF1);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n"; 
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n"; 
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text(); $Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){$server_applet_text .=''."\n".'}';}
	}
	elsif (uc($comp_grp) eq "CORE_UIF_EAT1")
	{
		@CORE_UIF_EAT1 = ("CORE_UIF:callcenter","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_EAT1 ;
		my @applet_list=split(",",@CORE_UIF_EAT1);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_EAT1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n"; 
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text(); $Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){$server_applet_text .=''."\n".'}';}
	}
	elsif (uc($comp_grp) eq "CORE_UIF1")
	{
		@CORE_UIF1 = ("CORE_UIF:callcenter","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF1 ;
		my @applet_list=split(",",@CORE_UIF1);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n"; 
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text(); $Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){$server_applet_text .=''."\n".'}';}
	}
	
	elsif (uc($comp_grp) eq "PSR_CLICKSTREAM_EAT")
	{
		@PSR_ClickStream_EAT = ("PS:epublicsector","Siebel Financial Services:fins","Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @PSR_ClickStream_EAT ;
		my @applet_list=split(",",@PSR_ClickStream_EAT);
		$Server_applet_count=1;
		foreach $prod1 (@PSR_ClickStream_EAT)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n"; 
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text(); $Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){$server_applet_text .=''."\n".'}';}
	}
	
	elsif(uc($comp_grp) eq "CORE_UIF2")
	{
		@CORE_UIF2 = ("CORE_UIF:callcenter","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF2 ;
		my @applet_list=split(",",@CORE_UIF2);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF2)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n"; $application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text(); $Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){ $server_applet_text .=''."\n".'}'; }
	}
	elsif(uc($comp_grp) eq "CORE_UIF3")
	{
		@CORE_UIF3 = ("CORE_UIF:callcenter","PHARMAM:callcenter","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF3 ;
		my @applet_list=split(",",@CORE_UIF3);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF3)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){ $server_applet_text .=''."\n".'}'; }
	}
	
	elsif(uc($comp_grp) eq "CORE_UIF5")
	{
		@CORE_UIF5 = ("CORE_UIF:callcenter","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_UIF5 ;
		my @applet_list=split(",",@CORE_UIF5);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF5)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){ $server_applet_text .=''."\n".'}'; }
	}
	elsif(uc($comp_grp) eq "LILT_DR")
	{
		@LILT_DR = ("LILT_DR:callcenter","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @LILT_DR ;
		my @applet_list=split(",",@LILT_DR);
		$Server_applet_count=1;
		foreach $prod1 (@LILT_DR)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){ $server_applet_text .=''."\n".'}'; }
	}
	elsif(uc($comp_grp) eq "LILT_RR")
	{
		@LILT_RR = ("Siebel Consumer Web:ecustomer","Siebel Public Sector:epublicsector","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @LILT_RR ;
		my @applet_list=split(",",@LILT_RR);
		$Server_applet_count=1;
		foreach $prod1 (@LILT_RR)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){ $server_applet_text .=''."\n".'}'; }
	}
	elsif(uc($comp_grp) eq "CORE_AULI")
	{
		@CORE_AULI = ("Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_AULI ;
		my @applet_list=split(",",@CORE_AULI);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_AULI)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){ $server_applet_text .=''."\n".'}';}
	}
	elsif(uc($comp_grp) eq "CORE_FIND_SEARCH")
	{
		@CORE_FIND_SEARCH = ("Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_FIND_SEARCH ;
		my @applet_list=split(",",@CORE_FIND_SEARCH);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_FIND_SEARCH)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){ $server_applet_text .=''."\n".'}';}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_NEWAUTOMATION_18")
	{
		#@CORE_UIF_NEWAUTOMATION_18 = ("Siebel Financial Services:fins","Siebel Power Communications:ecommunications","Siebel Sales Enterprise:sales","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		@CORE_UIF_NEWAUTOMATION_18 = ("Siebel Financial Services:fins","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_NEWAUTOMATION_18 ;
		my @applet_list=split(",",@CORE_UIF_NEWAUTOMATION_18);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_NEWAUTOMATION_18)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){ $server_applet_text .=''."\n".'}';}
	}
	elsif(uc($comp_grp) eq "CALLCENTER_TRANSFORMERS_KWD")
	{
		@CALLCENTER_TRANSFORMERS_KWD = ("Siebel Power Communications:ecommunications","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CALLCENTER_TRANSFORMERS_KWD ;
		my @applet_list=split(",",@CALLCENTER_TRANSFORMERS_KWD);
		$Server_applet_count=1;
		foreach $prod1 (@CALLCENTER_TRANSFORMERS_KWD)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_ATA")
	{
		@CORE_UIF_ATA = ("Siebel Financial Services:fins","Siebel Hospitality:ehospitality","Siebel Loyalty:loyalty","Siebel Power Communications:ecommunications","Siebel Public Sector:epublicsector","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_ATA ;
		my @applet_list=split(",",@CORE_UIF_ATA);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_ATA)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	
	elsif(uc($comp_grp) eq "IP19_AUTOTILE_MS")
	{
		@IP19_AutoTile_MS = ("Siebel Financial Services:fins","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @IP19_AutoTile_MS ;
		my @applet_list=split(",",@IP19_AutoTile_MS);
		$Server_applet_count=1;
		foreach $prod1 (@IP19_AutoTile_MS)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	
	elsif(uc($comp_grp) eq "CORE_LOV_INTEG")
	{
		@CORE_LOV_INTEG = ("Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_LOV_INTEG ;
		my @applet_list=split(",",@CORE_LOV_INTEG);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_LOV_INTEG)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	
	
	
	elsif(uc($comp_grp) eq "CORE_UIF_ATA1")
	{
		@CORE_UIF_ATA1 = ("Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_UIF_ATA1 ;
		my @applet_list=split(",",@CORE_UIF_ATA1);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_ATA1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_ATA2")
	{
		#@CORE_UIF_ATA2 = ("Siebel Financial Services:fins","Siebel Power Communications:ecommunications","Siebel Public Sector:epublicsector","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		@CORE_UIF_ATA2 = ("Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_ATA2 ;
		my @applet_list=split(",",@CORE_UIF_ATA2);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_ATA2)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_ATA3")
	{
		#@CORE_UIF_ATA3 = ("Siebel Financial Services:fins","Siebel Loyalty:loyalty","Siebel Public Sector:epublicsector","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		@CORE_UIF_ATA3 = ("Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_ATA3 ;
		my @applet_list=split(",",@CORE_UIF_ATA3);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_ATA3)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_ATA4")
	{
		@CORE_UIF_ATA4 = ("Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_ATA4 ;
		my @applet_list=split(",",@CORE_UIF_ATA4);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_ATA4)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_ATA5")
	{
		#@CORE_UIF_ATA5 = ("Siebel Financial Services:fins","Siebel Loyalty:loyalty","Siebel Web Tools:webtools");
		@CORE_UIF_ATA5 = ("Siebel Financial Services:fins","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_ATA5 ;
		my @applet_list=split(",",@CORE_UIF_ATA5);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_ATA5)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_ATA6")
	{
		@CORE_UIF_ATA6 = ("Siebel Power Communications:ecommunications","Siebel Public Sector:epublicsector");
		$Server_applet_array_count = scalar @CORE_UIF_ATA6 ;
		my @applet_list=split(",",@CORE_UIF_ATA6);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_ATA6)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_CHARTS_UIFRAGMENTS")
	{
		@CORE_UIF_CHARTS_UIFRAGMENTS = ("Siebel Hospitality:ehospitality","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_CHARTS_UIFRAGMENTS ;
		my @applet_list=split(",",@CORE_UIF_CHARTS_UIFRAGMENTS);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_CHARTS_UIFRAGMENTS)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_EDITWEBLAYOUT_ODHEDITOR")
	{
		@CORE_UIF_EDITWEBLAYOUT_ODHEDITOR = ("Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_EDITWEBLAYOUT_ODHEDITOR ;
		my @applet_list=split(",",@CORE_UIF_EDITWEBLAYOUT_ODHEDITOR);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_EDITWEBLAYOUT_ODHEDITOR)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_NEWFEATURES_MONTHLYUPDATES")
	{
		#@CORE_UIF_NEWFEATURES_MONTHLYUPDATES = ("Siebel Hospitality:ehospitality","Siebel Power Communications:ecommunications","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		@CORE_UIF_NEWFEATURES_MONTHLYUPDATES = ("Siebel Hospitality:ehospitality","Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_UIF_NEWFEATURES_MONTHLYUPDATES ;
		my @applet_list=split(",",@CORE_UIF_NEWFEATURES_MONTHLYUPDATES);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_NEWFEATURES_MONTHLYUPDATES)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_UIF_BATCH")
	{
		@CORE_UIF_BATCH = ("CORE_UIF:callcenter","Siebel Power Communications:ecommunications","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_UIF_BATCH ;
		my @applet_list=split(",",@CORE_UIF_BATCH);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_UIF_BATCH)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "COM_AIA1")
	{
		@COM_AIA1 = ("COM_AIA:ecommunications");
		$Server_applet_array_count = scalar @COM_AIA1 ;
		my @applet_list=split(",",@COM_AIA1);
		$Server_applet_count=1;
		foreach $prod1 (@COM_AIA1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "COM_AIA2")
	{
		@COM_AIA2 = ("COM_AIA:ecommunications");
		$Server_applet_array_count = scalar @COM_AIA2 ;
		my @applet_list=split(",",@COM_AIA2);
		$Server_applet_count=1;
		foreach $prod1 (@COM_AIA2)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "COM_SETANTA1")
	{
		@COM_SETANTA1 = ("COM_SETANTA:ecommunications","Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @COM_SETANTA1 ;
		my @applet_list=split(",",@COM_SETANTA1);
		$Server_applet_count=1;
		foreach $prod1 (@COM_SETANTA1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "COM_SETANTA2")
	{
		@COM_SETANTA2 = ("COM_SETANTA:ecommunications","Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @COM_SETANTA2 ;
		my @applet_list=split(",",@COM_SETANTA2);
		$Server_applet_count=1;
		foreach $prod1 (@COM_SETANTA2)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "COM_SETANTA3")
	{
		@COM_SETANTA3 = ("COM_SETANTA:ecommunications","Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @COM_SETANTA3 ;
		my @applet_list=split(",",@COM_SETANTA3);
		$Server_applet_count=1;
		foreach $prod1 (@COM_SETANTA3)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "ATA_MAVERICK1")
	{
		@ATA_MAVERICK1 = ("Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @ATA_MAVERICK1 ;
		my @applet_list=split(",",@ATA_MAVERICK1);
		$Server_applet_count=1;
		foreach $prod1 (@ATA_MAVERICK1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "ATA_MAVERICK2")
	{
		@ATA_MAVERICK2 = ("Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @ATA_MAVERICK2 ;
		my @applet_list=split(",",@ATA_MAVERICK2);
		$Server_applet_count=1;
		foreach $prod1 (@ATA_MAVERICK2)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "COM_MAVERICK1")
	{
		@COM_MAVERICK1 = ("COM_MAVERICK:ecommunications","Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @COM_MAVERICK1 ;
		my @applet_list=split(",",@COM_MAVERICK1);
		$Server_applet_count=1;
		foreach $prod1 (@COM_MAVERICK1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "COM_MAVERICK2")
	{
		@COM_MAVERICK2 = ("COM_MAVERICK:ecommunications","Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @COM_MAVERICK2 ;
		my @applet_list=split(",",@COM_MAVERICK2);
		$Server_applet_count=1;
		foreach $prod1 (@COM_MAVERICK2)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "COM_MAVERICK3")
	{
		@COM_MAVERICK3 = ("CME:ecommunications","Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @COM_MAVERICK3 ;
		my @applet_list=split(",",@COM_MAVERICK3);
		$Server_applet_count=1;
		foreach $prod1 (@COM_MAVERICK3)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CME")
	{
		@CME = ("CME:ecommunications");
		$Server_applet_array_count = scalar @CME ;
		my @applet_list=split(",",@CME);
		$Server_applet_count=1;
		foreach $prod1 (@CME)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CICD_CME")
	{
		@CICD_CME = ("Siebel Power Communications:ecommunications");
		$Server_applet_array_count = scalar @CICD_CME ;
		my @applet_list=split(",",@CICD_CME);
		$Server_applet_count=1;
		foreach $prod1 (@CICD_CME)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "COM_MAVEN")
	{
		@COM_MAVEN = ("COM_MAVEN:ecommunications","Siebel Power Communications:ecommunications","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @COM_MAVEN ;
		my @applet_list=split(",",@COM_MAVEN);
		$Server_applet_count=1;
		foreach $prod1 (@COM_MAVEN)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "SALES")
	{
		@SALES = ("SALES:sales","Siebel Consumer Sales:esales","Siebel Sales Enterprise:sales");
		$Server_applet_array_count = scalar @SALES ;
		my @applet_list=split(",",@SALES);
		$Server_applet_count=1;
		foreach $prod1 (@SALES)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "PRM")
	{
		@PRM = ("PRM:partnerportal","PRMMANAGER:prmmanager","Siebel CX Partner Portal:partnerportal","Siebel Field Service:service","Siebel Financial Services:fins","Siebel Partner Manager:prmmanager");
		$Server_applet_array_count = scalar @PRM ;
		my @applet_list=split(",",@PRM);
		$Server_applet_count=1;
		foreach $prod1 (@PRM)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "SERVICEM_PRESETUP")
	{
		@SERVICEM_PRESETUP = ("Siebel Field Service:service");
		$Server_applet_array_count = scalar @SERVICEM_PRESETUP ;
		my @applet_list=split(",",@SERVICEM_PRESETUP);
		$Server_applet_count=1;
		foreach $prod1 (@SERVICEM_PRESETUP)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}	
	elsif(uc($comp_grp) eq "PHARMA1")
	{
		@PHARMA1 = ("PHARMA:epharma","Siebel Life Sciences:epharma");
		$Server_applet_array_count = scalar @PHARMA1 ;
		my @applet_list=split(",",@PHARMA1);
		$Server_applet_count=1;
		foreach $prod1 (@PHARMA1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "PHARMA2")
	{
		@PHARMA2 = ("PHARMA:epharma","Siebel Consumer Web:ecustomer","Siebel Life Sciences:epharma");
		$Server_applet_array_count = scalar @PHARMA2 ;
		my @applet_list=split(",",@PHARMA2);
		$Server_applet_count=1;
		foreach $prod1 (@PHARMA2)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "ACS_CONTENT")
	{
		@ACS_CONTENT = ("Siebel Life Sciences:epharma");
		$Server_applet_array_count = scalar @ACS_CONTENT ;
		my @applet_list=split(",",@ACS_CONTENT);
		$Server_applet_count=1;
		foreach $prod1 (@ACS_CONTENT)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "SMCold")
	{
		@SMC = ("SMCold:SMC");
		$Server_applet_array_count = scalar @SMC ;
		my @applet_list=split(",",@SMC);
		$Server_applet_count=1;
		foreach $prod1 (@SMC)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/$appurl/login.html?automation=1\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "FINS1")
	{
		@FINS1 = ("FINS:fins","Siebel Financial Services:fins");
		$Server_applet_array_count = scalar @FINS1 ;
		my @applet_list=split(",",@FINS1);
		$Server_applet_count=1;
		foreach $prod1 (@FINS1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "FINS2")
	{
		@FINS2 = ("FINS:fins","Siebel Financial Services:fins");
		$Server_applet_array_count = scalar @FINS2 ;
		my @applet_list=split(",",@FINS2);
		$Server_applet_count=1;
		foreach $prod1 (@FINS2)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "ACS_FINS")
	{
		@ACS_FINS = ("Siebel Financial Services:fins");
		$Server_applet_array_count = scalar @ACS_FINS ;
		my @applet_list=split(",",@ACS_FINS);
		$Server_applet_count=1;
		foreach $prod1 (@ACS_FINS)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "KEYWORDS_HEALTH_CHECK")
	{
		@KEYWORDS_HEALTH_CHECK = ("Siebel Financial Services:fins","Siebel Life Sciences:epharma","Siebel Sales Enterprise:sales","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @KEYWORDS_HEALTH_CHECK ;
		my @applet_list=split(",",@KEYWORDS_HEALTH_CHECK);
		$Server_applet_count=1;
		foreach $prod1 (@KEYWORDS_HEALTH_CHECK)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	#elsif (uc($comp_grp) eq "PSR_ClickStream_EAT" )
	#{
		#@PSR_ClickStream_EAT = ("PS:epublicsector","Siebel Financial Services:fins","Siebel Power Communications:ecommunications");
		#$Server_applet_array_count = scalar @PSR_ClickStream_EAT;
		#my @applet_list=split(",",@PSR_ClickStream_EAT);
		#$Server_applet_count=1;
		#foreach $prod1 (@PSR_ClickStream_EAT)
		#{
			#($appval,$appurl)=split(":",$prod1,2);
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url =~ s/\r|\n//g ;
			#&generate_second_applet_text();
			#$Server_applet_count++;
		#}
		#if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	#}
	elsif(uc($comp_grp) eq "ACS_SALES_DELIVERY")
	{
		@ACS_SALES_DELIVERY = ("Siebel CX Partner Portal:partnerportal","Siebel Partner Manager:partnerportal","Siebel Sales Enterprise:sales");
		$Server_applet_array_count = scalar @ACS_SALES_DELIVERY ;
		my @applet_list=split(",",@ACS_SALES_DELIVERY);
		$Server_applet_count=1;
		foreach $prod1 (@ACS_SALES_DELIVERY)
		{
			($appval,$appurl)=split(":",$prod1,2);
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "MARKETING")
	{
		@MARKETING = ("MARKETING:marketing","Siebel Consumer Marketing:emarketing");
		$Server_applet_array_count = scalar @MARKETING ;
		my @applet_list=split(",",@MARKETING);
		$Server_applet_count=1;
		foreach $prod1 (@MARKETING)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "HTIM")
	{
		@HTIM = ("HTIM:htim","PRM:htimprm");
		$Server_applet_array_count = scalar @HTIM ;
		my @applet_list=split(",",@HTIM);
		$Server_applet_count=1;
		foreach $prod1 (@HTIM)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "PS")
	{
		@PS = ("PS:epublicsector","PSS:pssservice","Siebel Public Sector PRMPortal:epsportal");
		$Server_applet_array_count = scalar @PS ;
		my @applet_list=split(",",@PS);
		$Server_applet_count=1;
		foreach $prod1 (@PS)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "SRVC_INVT_SOLN")
	{
		@SRVC_INVT_SOLN = ("CC:callcenter","SERVICE:service","Siebel Field Service:service","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @SRVC_INVT_SOLN ;
		my @applet_list=split(",",@SRVC_INVT_SOLN);
		$Server_applet_count=1;
		foreach $prod1 (@SRVC_INVT_SOLN)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "SRVC_ASSETS_SR")
	{
		@SRVC_ASSETS_SR = ("SERVICE:service","Siebel Field Service:service");
		$Server_applet_array_count = scalar @SRVC_ASSETS_SR ;
		my @applet_list=split(",",@SRVC_ASSETS_SR);
		$Server_applet_count=1;
		foreach $prod1 (@SRVC_ASSETS_SR)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "SRVC_ENGINES")
	{
		@SRVC_ENGINES = ("SERVICE:service");
		$Server_applet_array_count = scalar @SRVC_ENGINES ;
		my @applet_list=split(",",@SRVC_ENGINES);
		$Server_applet_count=1;
		foreach $prod1 (@SRVC_ENGINES)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "ATA_FASTANDFURIOUS")
	{
		@ATA_FASTANDFURIOUS = ("DELETE:service","Siebel Field Service:service","Siebel Power Communications:service","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @ATA_FASTANDFURIOUS ;
		my @applet_list=split(",",@ATA_FASTANDFURIOUS);
		$Server_applet_count=1;
		foreach $prod1 (@ATA_FASTANDFURIOUS)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "EAUTO")
	{
		@EAUTO= ("EAUTO:eautomotive","EDEALER:edealer","Siebel Service Portal:sservice");
		$Server_applet_array_count = scalar @EAUTO ;
		my @applet_list=split(",",@EAUTO);
		$Server_applet_count=1;
		foreach $prod1 (@EAUTO)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CG")
	{
		@CG= ("CG:econsumersector","Siebel Consumer Sector:econsumersector");
		$Server_applet_array_count = scalar @CG ;
		my @applet_list=split(",",@CG);
		$Server_applet_count=1;
		foreach $prod1 (@CG)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "TNT")
	{
		@TNT= ("Siebel Hospitality:ehospitality","TNT:ehospitality");
		$Server_applet_array_count = scalar @TNT ;
		my @applet_list=split(",",@TNT);
		$Server_applet_count=1;
		foreach $prod1 (@TNT)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "LOYALTY")
	{
		##@LOYALTY= ("LOYALTY:loyalty","Siebel Loyalty:loyalty","Siebel Web Tools:webtools");
		@LOYALTY= ("LOYALTY:loyalty","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @LOYALTY ;
		my @applet_list=split(",",@LOYALTY);
		$Server_applet_count=1;
		foreach $prod1 (@LOYALTY)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CLINICAL")
	{
		@CLINICAL= ("CLINICAL:eclinical");
		$Server_applet_array_count = scalar @CLINICAL ;
		my @applet_list=split(",",@CLINICAL);
		$Server_applet_count=1;
		foreach $prod1 (@CLINICAL)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "CORE_SCRIPTING")
	{
		@CORE_SCRIPTING= ("Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_SCRIPTING ;
		my @applet_list=split(",",@CORE_SCRIPTING);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_SCRIPTING)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif(uc($comp_grp) eq "PLATFORMDB")
	{
		@PLATFORMDB= ("Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @PLATFORMDB ;
		my @applet_list=split(",",@PLATFORMDB);
		$Server_applet_count=1;
		foreach $prod1 (@PLATFORMDB)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			#print "Application Url :: $application_url\n";
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif (uc($comp_grp) eq "CORE_OM" )
	{
		@CORE_OM = ("PS:epublicsector","Siebel Public Sector:epublicsector","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_OM;
		my @applet_list=split(",",@CORE_OM);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_OM)
		{
			($appval,$appurl)=split(":",$prod1,2);
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	}
	elsif (uc($comp_grp) eq "CORE_SERVER_WS" )
	{
		@CORE_SERVER_WS = ("Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_SERVER_WS;
		my @applet_list=split(",",@CORE_SERVER_WS);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_SERVER_WS)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	}
	elsif (uc($comp_grp) eq "CORE_WSUI_ACCEPTANCE" )
	{
		@CORE_WSUI_ACCEPTANCE = ("Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_WSUI_ACCEPTANCE;
		my @applet_list=split(",",@CORE_WSUI_ACCEPTANCE);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_WSUI_ACCEPTANCE)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	}
	elsif (uc($comp_grp) eq "CORE_WS_WORKSPACE_TOOLS" )
	{
		@CORE_WS_WORKSPACE_TOOLS = ("Siebel Universal Agent:callcenter","Siebel Web Tools:webtools");
		$Server_applet_array_count = scalar @CORE_WS_WORKSPACE_TOOLS;
		my @applet_list=split(",",@CORE_WS_WORKSPACE_TOOLS);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_WS_WORKSPACE_TOOLS)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	}
	elsif (uc($comp_grp) eq "SMC" )
	{
		@SMC = ("SMC:SMC","SMC:SMC");
		$Server_applet_array_count = scalar @SMC;
		my @applet_list=split(",",@SMC);
		$Server_applet_count=1;
		foreach $prod1 (@SMC)
		{
			($appval,$appurl)=split(":",$prod1,2);
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/$appurl/login.html?automation=1\n";
			$application_url="https://$siebelserver:$httpsport/oracle-crm/$appurl/login.html?automation=1\n";
			$application_url="https://$siebelserver:$httpsport/oracle-crm/$appurl/safemode.html?automation=1\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	}
	
	elsif (uc($comp_grp) eq "CORE_WORKFLOW" )
	{
		@CORE_WORKFLOW = ("CORE_WORKFLOW:callcenter","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_WORKFLOW;
		my @applet_list=split(",",@CORE_WORKFLOW);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_WORKFLOW)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	}
	elsif (uc($comp_grp) eq "CORE_WSUI_LOVSEED_CRUD_DR" )
	{
		@CORE_WSUI_LOVSEED_CRUD_DR = ("Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_WSUI_LOVSEED_CRUD_DR;
		my @applet_list=split(",",@CORE_WSUI_LOVSEED_CRUD_DR);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_WSUI_LOVSEED_CRUD_DR)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	}
	elsif (uc($comp_grp) eq "CORE_WSUI_LOVSEED_CRUD_RR" )
	{
		@CORE_WSUI_LOVSEED_CRUD_RR = ("Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CORE_WSUI_LOVSEED_CRUD_RR;
		my @applet_list=split(",",@CORE_WSUI_LOVSEED_CRUD_RR);
		$Server_applet_count=1;
		foreach $prod1 (@CORE_WSUI_LOVSEED_CRUD_RR)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	}
	elsif (uc($comp_grp) eq "CALLCENTER" )
	{
		@CALLCENTER = ("Siebel Sales Enterprise:sales","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CALLCENTER;
		my @applet_list=split(",",@CALLCENTER);
		$Server_applet_count=1;
		foreach $prod1 (@CALLCENTER)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
		
	}
	elsif (uc($comp_grp) eq "CALENDAR_1" )
	{
		@CALENDAR_1 = ("Siebel Sales Enterprise:sales","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CALENDAR_1;
		my @applet_list=split(",",@CALENDAR_1);
		$Server_applet_count=1;
		foreach $prod1 (@CALENDAR_1)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	elsif (uc($comp_grp) eq "CALENDAR" )
	{
		@CALENDAR = ("CALENDAR:callcenter","DELETE:callcenter","Siebel Sales Enterprise:sales","Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @CALENDAR;
		my @applet_list=split(",",@CALENDAR);
		$Server_applet_count=1;
		foreach $prod1 (@CALENDAR)
		{
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			#$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	

	
	elsif (uc($comp_grp) eq "BIP")
	{
		@BIP = ("Siebel Universal Agent:callcenter");
		$Server_applet_array_count = scalar @BIP;
		my @applet_list=split(",",@BIP);
		$Server_applet_count=1;
		foreach $prod1 (@BIP)
		{
	
			($appval,$appurl)=split(":",$prod1,2);
			$application_url="https://$siebelserver:$httpsport/oracle-crm/app/$appurl/enu\n";
			$application_url =~ s/\r|\n//g ;
			&generate_second_applet_text();
			$Server_applet_count++;
		}
		if ($Server_applet_array_count >= 1){	$server_applet_text .=''."\n".'}';	}
	}
	
	#&print_second_applet();
}


sub print_second_applet
{
	print "_____________________________________________________\n";
	print "SECOND APPLET FILE CONTENT ::\n$server_applet_text \n";	
	print "_____________________________________________________\n";
}


sub generate_second_applet_text
{
	#print "********************$comp_grp*******************\n";
	my $brackettype;
	
	if ($Server_applet_count eq 1)
	{
		$brackettype="{\n";
	}
	else
	{
		$brackettype="\n},\n{\n";
	}
	$server_applet_text .= ''.$brackettype.'"Application Alias" : "'.$appval.'",'."\n".'"Application Type" : "'.$application_type.'",'."\n".'"Server OS Type" : "'.$os.'",'."\n".'"URL" : "'.$application_url.'",'."\n".'"Server SRF Path" : "'.$installedpath.'",'."\n".'"Siebel Server Machine" : "'.$siebelserver.'",'."\n".'"Siebel Server User":"'.$login_id.'",'."\n".'"Gateway Machine":"'.$hostname.'",'."\n".'"Siebel Gateway Port":"'.$gatewayport.'",'."\n".'"AI Server Port":"'.$httpsport.'"' ;
}


sub generate_complete_applet_content
{
	
	$complete_applet_content='{'."\n".'"body":'."\n".'{'."\n".$firstappletvalue."\n".'['."\n".$server_applet_text."\n".']'."\n".'}'."\n".'}';
	print "##################################CURL FILE CONTENT#############################################\n";
	#print "$complete_applet_content\n";
	print "################################################################################################\n";
	
	#if (-e "$path\\$soap_content") 
	#{
    #print "Deleting $soap_content file @ $path \n" ;
    #unlink $soap_content;
	#}
	#else 
	#{
    #open my $fh, ">", "c:\\$soap_content" or die("Could not open file. $!");
	open(my $fh, '>', "$path\\$soap_content") or die "Could not open file $!";
	print $fh "$complete_applet_content";
	close($fh) 
	#}
	
}


sub curl_first_record_creation_module
{
	#print "Master DB :$masterDB" ;
	
	open(my $fh, '<', "$path\\$soap_content") or die "Could not open file $!";
	
	$curl="curl -k -X POST -H \"authorization: Basic R09XTEFLU0g6R09XTEFLU0gxMTQ=\" -H \"cache-control: no-cache\" -H \"postman-token: 4a64f80a-b1c1-4eab-8d0a-4ec603555de6\" -H \"Content-Type:application/json\" \"".$masterDB."/v1.0/service/Automation%20Rest%20Service/testexecution\" -d @\"c:\\sowmya\\soap_content.json\"";

	#$curl="curl -k -X POST ".$masterDB."/v1.0/service/Automation%20Rest%20Service/testexecution \ -H 'authorization: Basic R09XTEFLU0g6R09XTEFLU0gxMTQ=' \ -H 'cache-control: no-cache' \ -H 'content-type: application/json' \ -H 'postman-token: 4a64f80a-b1c1-4eab-8d0a-4ec603555de6' \ -d '".$complete_applet_content."'";
	#$curl=~s/\n//g;
	#$curl="curl -k -X POST ".$masterDB."/v1.0/service/Automation%20Rest%20Service/testexecution -H 'authorization: Basic R09XTEFLU0g6R09XTEFLU0gxMTQ=' -H 'cache-control: no-cache' -H 'content-type: application/json' -d '".$complete_applet_content."'";
	print "curl :: $curl \n ";
	my $exec=`$curl 2>&1`;
	$exec =~ s/^\s+|\s+$//g ;	#$exec =~ s/^+$//g ;
	#my @outtxt=split("\n",$exec);
	my @outtxt=split("{",$exec);
	#print "$exec\n";
	if (uc($exec)  =~ /ERROR/ )
	{
		print "$exec is error\n";
		exit;
	}
	else
	{
		foreach my $text (@outtxt)
		{
			$text=~s/[\n\t"\[\]]//g;
			#print "gowthami:$text\n";
			
			if (uc($text) =~ /ID/)
			{
			
				$text=~s/[\n\t{\[\]]//g;$text=~s/[\n\t}\[\]]//g;
				#$text=~s/[\n\t\s{\[\]]//g;	#$text=~s/[\n\t\s}\[\]]//g;
				($val1,$val2,$val3)=split(",",$text);
				#print "val1 :: $val1\n"; 
				($valuename1,$recordid)=split(":",$val1);
				print "Record_ID:$recordid\n"; #print "hello :: $val2\n";
				#my $replacedrunid = `sed -i -e 's/\"cicd_recordid\":\"88-28LOO9\"/\"cicd_recordid\":\"8888888\"/' \\\\slcnas607\\engfs06\\install\\gitlab_cache\\karta_CICD\\test1.json`;
				#print "$creplacedrunid";
				open(FILE, "<\\\\slcnas607\\engfs06\\install\\gitlab_cache\\karta_CICD\\test.json") || die "File not found";
				#open(FILE, "<\\\\slcnas607\\engfs06\\install\\gitlab_cache\\dev_analex_112233\\.deployParameters") || die "File not found";
				my @lines = <FILE>;
				close(FILE);
				foreach(@lines)
				{
					print "test1 OLD :: $oldrecordid : NEW :: $recordid\n";					
					#print "test2 : $_\n";
					$_ =~ s/\"recordid\":\"$oldrecordid\"/\"recordid\":\"$recordid\"/g;
				}
				open(FILE, ">\\\\slcnas607\\engfs06\\install\\gitlab_cache\\karta_CICD\\test.json") || die "File not found";
				#open(FILE, ">\\\\slcnas607\\engfs06\\install\\gitlab_cache\\dev_analex_112233\\.deployParameters") || die "File not found";
				print FILE @lines;
				close(FILE);
				($valuename2,$servercredlist)=split(":",$val2);
				#print "Server_credential_list:$servercredlist\n";
				@serverarray = split(';', $servercredlist);
				my @credarray ;
				foreach my $serverval (@serverarray)
				{
					#print "$serverval\n";
					#$ser_cred_val="$serverval:pwd1";
					$ser_cred_val="$serverval:welcome1";
					#print"$ser_cred_val\n";
					push (@credarray,$ser_cred_val)
				}
				$final_server_cred_list=join(";",@credarray);
				#print "FINAL:$final_server_cred_list\n"; #print "$val3\n";
				($valuename3,$userlist)=split(":",$val3);
				#print "User_List:$userlist\n"
				@userapplet=split(';',$userlist);
				my @usercred;
				foreach my $userval(@userapplet)
				{
					$user_value="$userval:ldap";
					#print"$user_value\n";
					push(@usercred,$user_value)
				}
				$final_user_list=join(";",@usercred);
				#print"FINAL_userlist:$final_user_list\n";
				
			}
			
		}
	}
	
}
sub second_record_creation_module
{
	#print "curl_second_record_creation_module\n";
	$second_submission_content='"Test Run Id":"'.$recordid.'",'."\n".'"MAC Machine Pwd":"Welcome123",'."\n".'"Siebel Tools Machine Pwd":"'.$password.'",'."\n".'"Siebel Tools DSN Pwd":"ldap",'."\n".'"BIP Server Pwd":"'.$password.'",'."\n".'"EAI Server Pwd":"ldap",'."\n".'"Server Credentials":"'.$final_server_cred_list.'",'."\n".'"Users List":"'.$final_user_list.'"';
	#print "$second_submission_content\n";
	print "Record id for the STE run : '.$recordid.'";
	$complete_submission_content='{'."\n".'"body":'."\n".'{'."\n".$second_submission_content."\n".'}'."\n".'}';
	print"$complete_submission_content\n";
	
	open(my $fh, '>', "$path\\$result_content") or die "Could not open file $!";
	print $fh "$complete_submission_content";
	close($fh) 
	
}

sub run_id_submission
{
	print "inside run id submission\n";
	open(my $fh, '<', "$path\\$result_content") or die "Could not open file $!";
	$curl1="curl -k -X POST -H \"authorization: Basic R09XTEFLU0g6R09XTEFLU0gxMTQ=\" -H \"cache-control: no-cache\" -H \"postman-token: 4a64f80a-b1c1-4eab-8d0a-4ec603555de6\" -H \"Content-Type:application/json\" \"".$masterDB."/v1.0/service/Automation%20Rest%20Service/ScheduleRun\" -d @\"c:\\sowmya\\result_content.json\"";
	
	print "curl :: $curl1 \n ";
	my $exec=`$curl1 2>&1`;
	#sleep 60;
	$exec =~ s/^\s+|\s+$//g ;
	my @outtxt=split("\n",$exec);
	#print "$exec\n";
	my @outtxt=split("{",$exec);
	#print "$exec\n";
	if (uc($exec)  =~ /ERROR/ )
	{
		print "$exec is error\n";
		exit;
	}
	else
	{
		foreach my $text (@outtxt)
		{
			$text=~s/[\n\t"\[\]]//g;
			print "STE record-id:$text\n";
			
			#if (uc($text) =~ /RUN REQUEST IS SUCCESSFULLY CREATED/)
			#{
			#print "Run is requested successfully with run ID $recordid for $comp_grp with $hostname/$login_id\n" ;
			#}
			#else
			#{
			#print "ERRORR!!!!!! RUN IS NOT SCHEDULED\n"
			#}
		}
	}
	
}

