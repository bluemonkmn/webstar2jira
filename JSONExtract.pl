use DBI;
use JSON;
use Data::Printer;

my $dbs = 'dbi:ODBC:DRIVER={SQL Server};SERVER=.\R2;Integrated Security=Yes';
my $dbh = DBI->connect($dbs);
if (defined($dbh))
{
	#binmode(STDOUT, ":raw");
	#print "\xEF\xBB\xBF"; # UTF-8 Byte Order Mark
	binmode(STDOUT, ':utf8');
	binmode(STDERR, ':utf8');
	$dbh->{LongReadLen} = 50000;
	
	my $query = <<'~';
	select SDRNum externalId
	, case Severity when 'A' then 'P1' when 'B' then 'P2' when 'C' then 'P3' when 'D' then 'P4' else null end priority
	, case Status when 'W' then 'Awaiting Approval' when 'C' then 'Resolved' else 'Accepted' end status
	, ReasonCode resolution
	, isnull(us.NTUserName, null) reporter
	, isnull(u.NTUserName, null) assignee
	, convert(varchar(20), s.Date_Reported, 126) created
	, s.Version affectedVersions
	, case when s.Level3 is null then s.Level2 else s.Level2 + '_' + s.Level3 end components
	, ProblemBrief summary
	, REPLACE(cast(ProblemDetail as varchar(max)), CHAR(13) + CHAR(10), CHAR(10)) description
	from STAR..sdr s
	left join STAR..UserInfo u on u.UserName = s.AssignedTo
	left join STAR..UserInfo us on us.UserName = s.Submitter
	where SDRNum in (57021, 57022)
~
	#, convert(varchar(20), s.DateClosed, 126) resolved

	my $sth = $dbh->prepare($query);
	$sth->execute();

	my $json = JSON->new->allow_nonref;
	my @sdrArray;
	my %sdrLookup = ();
	my %component_list = ();
	my %version_list = ();
	
	while (my $hashref = $sth->fetchrow_hashref())
	{
		$component_list{$hashref->{'components'}} = 1;
		$hashref->{'components'} = [$hashref->{'components'}];
		$version_list{$hashref->{'affectedVersions'}} = 1;
		$hashref->{'affectedVersions'} = [$hashref->{'affectedVersions'}];
		push @sdrArray, $hashref;
		$sdrLookup{$hashref->{'externalId'}} = $hashref;
	}
	
	$sth->finish;

	$query = <<'~';
	select SDR_Num externalId
	,convert(varchar(25), EntryDate, 126) created
	,isnull(p.NTUserName, null) author
	,LineType + case when p.NTUserName is null then ' (' + l.Person + '): ' else ': ' end + isnull(cast([Description] as varchar(max)),'') + ISNULL(ReasonCode, '') body
	from STAR..sdr_log l
	left join STAR..UserInfo p on l.Person = p.UserName
	where SDR_Num in (57021, 57022)
~
	$sth = $dbh->prepare($query);
	$sth->execute();
	
	while (my $comments = $sth->fetchrow_hashref())
	{
		my $sdr = $sdrLookup{$comments->{'externalId'}};
		next if (!$sdr);
		# Remove the externalId column from the object before encoding it into JSON
		delete $comments->{'externalId'};		
		if ($sdr->{'comments'})
		{
			push $sdr->{'comments'}, $comments;
		}
		else
		{
			$sdr->{'comments'} = [$comments];
		}
	}
	my %import = (projects => [{name=>'JSON Importer Test', key=>'JIT',
		components=>[keys %component_list], versions=>[map({name=>$_}, keys %version_list)], issues=>\@sdrArray}]);
	#@{$import{'components'}} = keys %component_list;
	print $json->encode(\%import);
	
	$sth->finish;

	$dbh->disconnect;
}
else
{
	print "Error: $DBI::errstr\n";
}