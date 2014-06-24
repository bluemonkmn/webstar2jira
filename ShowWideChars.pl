use DBI;

my $dbs = 'dbi:ODBC:DRIVER={SQL Server};SERVER=.\R2;Integrated Security=Yes';
my $dbh = DBI->connect($dbs);
if (defined($dbh))
{
	binmode(STDOUT, ":raw");
	print "\xEF\xBB\xBF"; # UTF-8 Byte Order Mark
	binmode(STDOUT, ':utf8');
	binmode(STDERR, ':utf8');
	$dbh->{LongReadLen} = 50000;
	my $query = <<'~';
	select SDRNum, Severity, Status, ReasonCode
	, isnull(us.NTUserName, s.Submitter) submitter
	, isnull(u.NTUserName, s.AssignedTo) AssignedTo
	, s.Date_Reported
	, s.DateClosed
	, s.Version
	, case when s.Level3 is null then s.Level2 else s.Level2 + '_' + s.Level3 end Component
	, ProblemBrief
	, REPLACE(cast(ProblemDetail as varchar(max)), CHAR(13) + CHAR(10), CHAR(10)) ProblemDetail
	from STAR..sdr s
	left join STAR..UserInfo u on u.UserName = s.AssignedTo
	left join STAR..UserInfo us on us.UserName = s.Submitter
~

	my $sth = $dbh->prepare($query);
	$sth->execute();

	my $fields = join(',', @{$sth->{NAME}});
	print "$fields\n";

	while(my @row = $sth->fetchrow_array()) {
		foreach(@row) {
			if ($_ =~ /[^\x00-\xFF]/)
			{
				print STDERR @row[0] . ": ";
				print STDERR $_ . "\n";
			}
		}
	}
	$sth->finish;
	$dbh->disconnect;
}
else
{
	print "Error: $DBI::errstr\n";
}