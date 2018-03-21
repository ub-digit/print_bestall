#!/usr/bin/perl

use utf8;
use CGI qw(-utf8);
use DBI;
use POSIX qw(strftime);
binmode STDOUT, ":utf8";

print "Content-Type: text/html; charset=UTF-8\n";
print "Pragma: no-cache", "\n\n";


my $cgi      = new CGI;
my $action   = $cgi->param('action');
my $calc     = $cgi->param('calc');
my $enhet    = $cgi->param('enhet');
my $files    = $cgi->param('fileSelect');
my $fromDate = $cgi->param('fromDate');
my $toDate   = $cgi->param('toDate');
my $appDir   = "/tmp/koha-940/apps/BirdHome/html/MoveFiles";

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
my $timestamp = sprintf ( "%04d%02d%02d%02d%02d",$year+1900,$mon+1,$mday,$hour+1,$min);
if ( !$fromDate ) {	$fromDate = $timestamp; }
if ( !$toDate )   { $toDate   = $timestamp; }

if ( length($fromDate) == 4 ) {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	my $timestamp = sprintf ( "%04d%02d%02d",$year+1900,$mon+1,$mday);
	$fromDate = $timestamp . $fromDate;
}
if ( length($toDate) == 4 ) {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
	my $timestamp = sprintf ( "%04d%02d%02d",$year+1900,$mon+1,$mday);
	$toDate = $timestamp . $toDate;
}

if     ($action eq "send"){
	
	my $rePrintFileList = '/tmp/reprint' . $$ . '.txt';
	open(my $fh, '>', $rePrintFileList) or die "Could not open file '$rePrintFileList' $!";
	$files =~ s/^\s*fileSelect=//;
	$files =~ s/&fileSelect=/\r\n/g;
 	print $fh "$files";
	close $fh;
	system("./reprint.sh " . $rePrintFileList . " " . $appDir);
}elsif ($action eq "calculate"){

	$filesDir=$appDir . "/files/done";
	$fileListString=`ls -w 1 $filesDir | grep "_pr${enhet}_" | sort -t "_" -k3 -r`;

	my @fileListArray = split /^/m, $fileListString;
	my $lines;
	my $i = 0;
	foreach(@fileListArray) {
		my $line = $_;
		my $dateline;
		$line = $_;
		$line =~ s/^\s+|\s+$//g;
		$dateline = $line;
		$dateline =~ s/^[^_]+_[^_]+_(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})\d{2}_.*$/$1$2$3$4$5/mg;
		if ( ($fromDate le $dateline) and ($toDate gt $dateline) ) {
			$lines = $lines . "\<option value='$line'>$dateline</option>\n";
			$i++;
		}
	}
	if ( $calc ) {
		if    ($i == 0) { print "Inga filer motsvarar sökningen."; }
		elsif ($i == 1) { print "$i fil vald"; }
		else            { print "$i filer valda"; }
	} else {
		print "$lines";
	}

}elsif ($action eq "show"){
	#$filesDir="../html/MoveFiles/exp/done";
	$filesDir="/tmp/koha-940/apps/BirdHome/html/MoveFiles/files/done";
	$fileListString=`ls -w 1 $filesDir | grep "_pr${enhet}_" | sort -t "_" -k3 -r`;
	$fileListString =~ s/^([^_]+_[^_]+_(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})\d{2}_.*)$/<option value="$1">$2-$3-$4 $5:$6<\/option>\n/mg;

	print $fileListString;
}elsif ($action eq "error") {
	print "Antingen är ingen enhet vald, eller så finns det inga utskrifter på den valda enheten för det angivna tidsintervallet."
}
__END__





