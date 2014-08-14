use strict;
use DBI;
use IO::File;
use XML::Parser;

my $accuRev = '"C:\Program Files (x86)\AccuRev\bin\accurev.exe" xml -l';
my $tmpXml = 'AccuWorkLinkTmp.xml';
my $depot = 'FS';
my $dbs = 'dbi:ODBC:DRIVER={SQL Server};SERVER=.\R2;Integrated Security=Yes';
my $dbh = DBI->connect($dbs) or die "Error: $DBI::errstr\n";
$dbh->{LongReadLen} = 50000;

binmode(STDOUT, ":raw");
print "\xEF\xBB\xBF"; # UTF-8 Byte Order Mark
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my @issueInfo = ();

my $query = <<'~';
select TransmittalId, REPLACE(cast(ReadMe as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) [description]
from STAR..resolution
where ReleaseLev in ('5.20', '6.00', '6.10', '6.20', '7.00', '7.10', '7.20', '7.30', '7.40', '7.50', '8.0', 'BI')
~

my $sth = $dbh->prepare($query);
$sth->execute();

while (my $hashref = $sth->fetchrow_hashref())
{
	$hashref->{description} =~ s/^(.{3}([^.\n]|\.\d)*)(.|\n|$).*$/$1/gs;
	$hashref->{description} =~ s/&/&amp;/gs;
	$hashref->{description} =~ s/</&lt;/gs;
	$hashref->{description} =~ s/>/&gt;/gs;
	my $fh = IO::File->new("> $tmpXml") or die "Failed to write $tmpXml";
	binmode($fh, ':utf8');
	print $fh <<"~";
<?xml version="1.0" encoding="UTF-8"?>
<newIssue issueDB="$depot">
	<issue>
		<shortDescription fid="4">$hashref->{description}</shortDescription>
		<type fid="7">defect</type>
	</issue>
</newIssue>
~
	$fh->close;
	
	my @result = `$accuRev $tmpXml`;
	if ($? != 0)
	{
		print STDERR 'Failed to create issue for transmittal ' . $hashref->{TransmittalId} . "\n";
	} else {
		my $xmlResult = join "\n",@result;
		if ($xmlResult =~ m/fid="1">([^<]+)</)
		{
			push @issueInfo, {issueNum => $1, transmittal => $hashref->{TransmittalId}};
			print STDOUT 'Transmittal ' . $hashref->{TransmittalId} . ' => ' . $1 . ': ' . $hashref->{description} . "\n";
		} else {
			print STDOUT "$xmlResult\n";
			print STDERR 'Failed to locate issue number for transmittal ' . $hashref->{TransmittalId} . "\n";
		}
	}
}

$sth->finish;

$query = <<'~';
if OBJECT_ID('StarMap..AccuWorkLink') is not null drop table StarMap..AccuWorkLink
create table StarMap..AccuWorkLink(TransmittalId int not null, Issue int not null)
~

$sth = $dbh->prepare($query) or die "Failed to prepare $query";
$sth->execute() or die "Failed to execute $query";
$sth->finish;

for my $issue (@issueInfo)
{
	$query = 'insert into StarMap..AccuWorkLink(TransmittalId, Issue) values(' .
		$issue->{transmittal} . ',' . $issue->{issueNum} . ')';
	$sth = $dbh->prepare($query) or die "Failed to prepare $query";
	$sth->execute() or die "Failed to execute $query";
	$sth->finish();
}
