use strict;
use DBI;
use JSON;
use Data::Printer;
use 5.10.1;

no if $] >= 5.018, warnings => "experimental";

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
	select 'JIT-' + cast(SDRNum as varchar(50)) [key]
	, SDRNum
	, case Severity when 'A' then 'P1' when 'B' then 'P2' when 'C' then 'P3' when 'D' then 'P4' else null end priority
	, case Status when 'W' then 'Awaiting Approval' when 'C' then 'Resolved' else 'Accepted' end status
	, ReasonCode resolution
	, us.NTUserName reporter
	, u.NTUserName assignee
	, convert(varchar(20), s.Date_Reported, 126) created
	, s.Version affectedVersions
	, case when s.Level3 is null then s.Level2 else s.Level2 + '_' + s.Level3 end components
	, ProblemBrief summary
	, REPLACE(cast(ProblemDetail as varchar(max)), CHAR(13) + CHAR(10), CHAR(10)) description
	, 'Bug' issueType
	from STAR..sdr s
	left join STAR..UserInfo u on u.UserName = s.AssignedTo
	left join STAR..UserInfo us on us.UserName = s.Submitter
	where SDRNum in (57003, 57021, 57022, 57068)
~
	#, convert(varchar(20), s.DateClosed, 126) resolved

	my $sth = $dbh->prepare($query);
	$sth->execute() or die 'Failed to execute SDR query.';

	my $json = JSON->new->allow_nonref->pretty->ascii;
	my %sdrLookup = ();
	my %component_list = ();
	my %version_list = ();
	
	while (my $hashref = $sth->fetchrow_hashref())
	{
		$component_list{$hashref->{'components'}} = 1;
		$hashref->{'components'} = [$hashref->{'components'}];
		$version_list{$hashref->{'affectedVersions'}} = 1;
		$hashref->{'affectedVersions'} = [$hashref->{'affectedVersions'}];
		$sdrLookup{$hashref->{'key'}} = $hashref;
		$hashref->{customFieldValues} = [
			{fieldName=>'ExternalID',fieldType=>'com.atlassian.jira.plugin.system.customfieldtypes:textfield',value=>'S-' . $hashref->{SDRNum}}
		];
		$hashref->{externalId} = $hashref->{SDRNum};
		delete $hashref->{SDRNum};
	}
	
	$sth->finish;

	$query = <<'~';
	select 'JIT-' + cast(SDR_Num as varchar(50)) [issueKey]
	,convert(varchar(25), EntryDate, 126) created
	,isnull(p.NTUserName, l.Person) author
	,LineType
	,ReasonCode
	,[Description]
	,hu.NTUserName HistoryUser
	from STAR..sdr_log l
	left join STAR..UserInfo p on l.Person = p.UserName
	left join STAR..UserInfo hu on l.ReasonCode = hu.UserName
	where SDR_Num in (57003, 57021, 57022, 57068)
~
	$sth = $dbh->prepare($query);
	$sth->execute();
	
	while (my $comments = $sth->fetchrow_hashref())
	{
		my $sdr = $sdrLookup{$comments->{'issueKey'}};
		next if (!$sdr);
		# Remove the issueKey column from the object before encoding it into JSON
		delete $comments->{'issueKey'};		
		
		my %history = ();
		my $histTo;
		my $histToStr;
		
		given (lc $comments->{LineType})
		{
			when ('reported') {$histTo = 1; $histToStr = 'Open';}
			when ('wait') {$histTo = 3; $histToStr = 'Accepted';}
			when ('closed') {$histTo = 6; $histToStr = 'Resolved';}
			when ('open') {$histTo = 1; $histToStr = 'Open';}
			default {undef $histTo; undef $histToStr;}
		}
		if ($histTo)
		{
			$history{items} = [{
				fieldType => 'jira',
				field => 'status',
				from => -1,
				fromString => 'Unknown',
				to => $histTo,
				toString => $histToStr
			}];
			my %reason = GetReason($comments->{ReasonCode});
			if (%reason)
			{
				push $history{items}, {(
					fieldType => 'jira',
					field => 'resolution',
					from => -1,
					fromString => 'Unknown'),
					%reason
				};
			}
		}
		elsif (lc $comments->{LineType} eq 'assigned' && $comments->{ReasonCode})
		{
			$history{items} = [{
				fieldType => 'jira',
				field => 'assignee',
				from => 'unknown',
				fromString => 'Unknown',
				to => $comments->{ReasonCode},
				toString => $comments->{HistoryUser} // ''
			}];
		}
		elsif (lc $comments->{LineType} eq 'severity' && $comments->{ReasonCode})
		{
			my $sev = $comments->{ReasonCode};
			$history{items} = [{
				fieldType => 'jira',
				field => 'priority',
				from => 'P0',
				fromString => 'Unknown',
				to => ($sev eq 'A') ? 'P1' : ($sev eq 'B') ? 'P2' : ($sev eq 'C') ? 'P3' : ($sev eq 'D') ? 'P4' : 'P0',
				toString => ($sev eq 'A') ? '1' : ($sev eq 'B') ? '2' : ($sev eq 'C') ? '3' : ($sev eq 'D') ? '4' : 'None'
			}];
		}
		elsif (lc $comments->{LineType} eq 'reason' && $comments->{ReasonCode})
		{
			my %reason = GetReason($comments->{ReasonCode});
			if (%reason)
			{
				$history{items} = [{(
					fieldType => 'jira',
					field => 'resolution',
					from => -1,
					fromString => 'Unknown'),
					%reason
				}];	
			}
		}
		
		if (%history)
		{
			$history{author} = $comments->{'author'};
			$history{created} = $comments->{'created'};
			if ($sdr->{'history'})
			{
				push $sdr->{'history'}, \%history;
			}
			else
			{
				$sdr->{'history'} = [\%history];				
			}
			if ($comments->{'Description'})
			{
				$comments->{Description} =~ s/^\s*(.*?)\s*$/$1/;
			}				
			if ($comments->{'Description'})
			{
				$comments->{'body'} = $comments->{LineType};
				if ($comments->{'ReasonCode'})
				{
					$comments->{'body'} .= " ($comments->{'ReasonCode'})";
				}
				$comments->{'body'} .= ": $comments->{Description}";
				if ($sdr->{'comments'})
				{
					push $sdr->{'comments'}, $comments;
				}
				else
				{
					$sdr->{'comments'} = [$comments];
				}
			}
		}
		else
		{
			if (lc $comments->{LineType} ne 'comment')
			{
				$comments->{'body'} = $comments->{LineType};
			}
			if ($comments->{'Description'})
			{
				$comments->{Description} =~ s/^\s*(.*?)\s*$/$1/;
				$comments->{'body'} .= $comments->{Description};
			}
			if ($comments->{'ReasonCode'})
			{
				$comments->{'body'} .= $comments->{'ReasonCode'};
			}
			if ($comments->{'body'})
			{
				if ($sdr->{'comments'})
				{
					push $sdr->{'comments'}, $comments;
				}
				else
				{
					$sdr->{'comments'} = [$comments];
				}
			}
		}
		
		delete $comments->{'LineType'};
		delete $comments->{'ReasonCode'};
		delete $comments->{'HistoryUser'};
		delete $comments->{'Description'};
	}
	$sth->finish;
	
	$query = <<'~';
	select
		 r.TransmittalId 
		,'JIT-' + cast((100000 + r.TransmittalId) as varchar(50)) [key]
		,case when isnull(s.SDRCount, 0) = 0 then 'Task' else 'Resolution' end issueType
		,case r.WaitingOn
		 when 'Analyst' then a.NTUserName
		 when 'Team Leader' then l.NTUserName
		 when 'QA' then isnull(q.NTUserName, l.NTUserName)
		 else l.NTUserName end assignee
		,case r.WaitingOn
		 when 'Analyst' then 'Accepted'
		 when 'Team Leader' then 'Development Complete'
		 when 'Release Mgr' then 'Development Complete'
		 when 'Build' then 'Development Complete'
		 when 'QA' then 'Awaiting Verification'
		 when 'Pull' then 'Awaiting Release'
		 when 'Done' then 'Resolved' end [status]
		,r.RlsLevelTarget affectedVersions
		,r.FunctionalArea components
		,REPLACE(cast(r.ReadMe as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) [description]
		,case SDRSeverity when 'A' then 'P1' when 'B' then 'P2' when 'C' then 'P3' when 'D' then 'P4' else null end severity
		,convert(varchar(20), r.TransmitDt, 126) TransmitDt
		,a.NTUserName Analyst
		,convert(varchar(20), r.BuildDt, 126) BuildDt
		,convert(varchar(20), r.QADt, 126) QADt
		,q.NTUserName QA
		,r.DocoNotes
	from STAR..resolution r
	left join STAR..UserInfo a on r.Analyst = a.UserName
	left join STAR..UserInfo l on r.TeamLeader = l.UserName
	left join STAR..UserInfo q on r.QATester = q.UserName
	left join (
	select TransmittalID, count(*) SDRCount
	from STAR..Resolution_SDRs
	group by TransmittalID
	) s on s.TransmittalID = r.TransmittalId
	where r.TransmittalId in (48174, 48175, 48603, 48827, 48921, 48922)
~
	$sth = $dbh->prepare($query);
	$sth->execute();
	
	my %resolutions = ();

	while (my $hashref = $sth->fetchrow_hashref())
	{
		my %resolution = %{$hashref};
		($resolution{summary} = $resolution{description}) =~ s/^(.{3}([^.\n]|\.\d)*)(.|\n|$).*$/$1/gs;
		$resolution{affectedVersions} = [$resolution{affectedVersions}];
		$resolution{components} = [$resolution{components}];
		if ($resolution{TransmitDt})
		{
			$resolution{history} = [
			{created => $resolution{TransmitDt},
			 items=> [{fieldType=>'jira',field=>'status',from=>'3',fromString=>'Accepted',to=>'5',toString=>'Development Complete'}]
			}];
			if ($resolution{Analyst})
			{
				$resolution{history}->[0]->{author} = $resolution{Analyst};
			}
		}
		if ($resolution{BuildDt})
		{
			my $hist = {
			 created => $resolution{BuildDt},
			 items=> [{fieldType=>'jira',field=>'status',from=>'5',fromString=>'Development Complete',to=>'10002',toString=>'Awaiting Verification'}]
			};
			if ($resolution{history})
			{
				push $resolution{history}, $hist
			} else {
				$resolution{history} = [$hist];
			}
		}
		if ($resolution{QADt})
		{
			my $hist = {
			 created => $resolution{QADt},
			 items=> [{fieldType=>'jira',field=>'status',from=>'10002',fromString=>'Awaiting Verification',to=>'10003',toString=>'Awaiting Release'}]
			};
			if ($resolution{QA})
			{
				$hist->{author} = $resolution{QA};
			}
			if ($resolution{history})
			{
				push $resolution{history}, $hist;
			} else {
				$resolution{history} = [$hist];
			}
		}
		if ($resolution{DocoNotes})
		{
			$resolution{description} .= '\n' . $resolution{DocoNotes};
		}

		@resolution{customFieldValues} = [
			{fieldName=>'ExternalID',fieldType=>'com.atlassian.jira.plugin.system.customfieldtypes:textfield',value=>'X-' . $resolution{TransmittalId}}
		];
		
		$resolution{externalId} = $resolution{TransmittalId} + 100000;
		$resolutions{$resolution{TransmittalId}} = \%resolution;
		
		delete $resolution{TransmitDt};
		delete $resolution{BuildDt};
		delete $resolution{QADt};
		delete $resolution{DocoNotes};		
		delete $resolution{TransmittalId};
		delete $resolution{QA};
		delete $resolution{Analyst};
	}
	$sth->finish;

	$query = <<'~';
	select r.TransmittalId, s.SDR_Num, s.RowNum
	from STAR..resolution r
	left join (
	select SDR_Num, TransmittalID, ROW_NUMBER() OVER (PARTITION BY TransmittalID ORDER BY SDR_Num DESC) RowNum
	from STAR..Resolution_SDRs) s on s.TransmittalID = r.TransmittalId
	where SDR_Num is not null
	and r.TransmittalId in (48174, 48175, 48603, 48827, 48921, 48922)
	and s.SDR_Num in (57003, 57021, 57022, 57068)
~
	$sth = $dbh->prepare($query);
	$sth->execute();

	my @links = ();
	
	while (my $link = $sth->fetchrow_hashref())
	{
		push @links, {name=>($link->{RowNum}==1)?"sub-task-link":"Fixed",sourceId=>$link->{TransmittalId}+100000,destinationId=>$link->{SDR_Num}}
	}

	$sth->finish;

	my %import = (projects => [{name=>'JSON Importer Test', key=>'JIT',
		components=>[keys %component_list], versions=>[map({name=>$_}, keys %version_list)],
		issues=>[values %sdrLookup, values %resolutions]}],
		links=>\@links);
	#@{$import{'components'}} = keys %component_list;
	print $json->encode(\%import);
	
	$dbh->disconnect;
}
else
{
	print "Error: $DBI::errstr\n";
}

sub GetReason {
	my $histTo;
	my $histToStr;
	
	my %result = ();
	given (lc $_[0])
	{
		when ('fixed') {$result{to} = 1; $result{toString} = 'Fixed';}
		when ('no problem') {$result{to} = 2; $result{toString} = 'Works as Designed';}
		when ('duplicate') {$result{to} = 3; $result{toString} = 'Duplicate';}			
		when ('need more info') {$result{to} = 4; $result{toString} = 'Incomplete';}
		when ('mystery') {$result{to} = 5; $result{toString} = 'Cannot Reproduce';}
		when ('no fix') {$result{to} = 7; $result{toString} = 'No plans to fix';}
		default { return; }
	}

	return %result;
}