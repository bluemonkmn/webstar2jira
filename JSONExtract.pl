use strict;
use DBI;
use JSON;
use Data::Printer;
use 5.10.1;

no if $] >= 5.018, warnings => "experimental";

my $dbs = 'dbi:ODBC:DRIVER={SQL Server};SERVER=.\R2;Integrated Security=Yes';
my $dbh = DBI->connect($dbs) or die "Error: $DBI::errstr\n";

binmode(STDOUT, ":raw");
# print "\xEF\xBB\xBF"; # UTF-8 Byte Order Mark
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
$dbh->{LongReadLen} = 50000;

my $query = <<'~';
select NTUserName, EmailAddr, UserName, Access, FullName, Active
from StarMap..UserInfo
~

my $sth = $dbh->prepare($query);
$sth->execute();

my %userMap = ();

# Releases ('5.20', '6.00', '6.10', '6.20', '7.00', '7.10', '7.20', '7.30', '7.40', '7.50', '8.0', 'BI')

while (my @userInfo = $sth->fetchrow_array())
{	
	$userInfo[0] =~ /^([^\\]*)\\(.*$)/ or die 'Failed to parse ' . $userInfo[0];
	my $domain = $1;
	my $userName = $2;
	
	my $userRec;
	
	if ($userInfo[5] == 1)
	{
		$userRec = {name=>$userName,groups=>['jira-users'],active=>JSON::true};
		if ($userInfo[3] eq 'Analyst' or $userInfo[3] eq 'Reviewer' or $userInfo[3] eq 'Admin')
		{
			push $userRec->{groups}, 'jira-developers';
		}
	} else {
		$userRec = {name=>"WebStar_$userName",active=>JSON::false};
	}
	
	if ($userInfo[1] =~ m/\S/)
	{
		$userRec->{email}=$userInfo[1];
	} else {
		$userRec->{email}='no.reply@infor.com';
	}
	if ($userInfo[4])
	{
		$userRec->{fullname} = $userInfo[4];
	}
	$userMap{$userInfo[2]} = $userRec;
}
$sth->finish;

$query = <<'~';
select SDRNum
, case Severity when 'A' then '1 - Show-Stopper' when 'B' then '2 - Critical' when 'C' then '3 - Major' when 'D' then '4 - Minor' else null end ReportedPriority
, case Priority when '@' then 'P1' when 'ß' then 'P2' when '*' then 'P3' when 'H' then 'P4' else null end priority
, case Status when 'W' then 'Awaiting Approval' when 'C' then 'Resolved' else 'Accepted' end status
, ReasonCode resolution
, s.Submitter reporter
, s.AssignedTo assignee
, convert(varchar(25), DATEADD(hour, -5, s.Date_Reported), 126) created
, s.Version affectedVersions
, case when s.Level3 is null then s.Level2 else s.Level2 + '_' + s.Level3 end components
, ProblemBrief summary
, REPLACE(cast(ProblemDetail as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) description
, case ProbEnh when 'E' then 'Feature Enhancement' else 'Bug' end issueType
, Source
, Introduced
, REPLACE(Release, '.', '_') Branch
,case Source
 when 'Unknown' then 'Unknown'
 when 'Configuration' then 'Configuration'
 when 'Style Guide Violatn' then 'StyleGuideViolation'
 when 'Spec Violation' then 'SpecViolation'
 when 'Design Error' then 'Design'
 when 'Design' then 'Design'
 when 'No Spec11' then 'NoSpec'
 when 'No Spec' then 'NoSpec'
 when 'Regression' then 'Regression'
 when 'DOCO' then 'Documentation'
 when 'Implementation Error' then 'Implementation'
 else null
 end SourceLabel
from STAR..sdr s
where SDRNum in (57003, 57021, 57022, 57068, 53762, 57675, 56641, 59602, 59558)
~
#, convert(varchar(25), s.DateClosed, 126) resolved

$sth = $dbh->prepare($query);
$sth->execute() or die 'Failed to execute SDR query.';

my $json = JSON->new->allow_nonref->pretty->ascii;
my %sdrLookup = ();
my %component_list = ();
my %version_list = ();
my @dummyBugLinks = ();

while (my $hashref = $sth->fetchrow_hashref())
{
	$component_list{$hashref->{'components'}} = 1;
	$hashref->{'components'} = [$hashref->{'components'}];
	$hashref->{'affectedVersions'} = $hashref->{'affectedVersions'} . ' (' . $hashref->{Branch} . ')';
	$version_list{$hashref->{'affectedVersions'}} = 1;
	$hashref->{'affectedVersions'} = [$hashref->{'affectedVersions'}];
	$sdrLookup{$hashref->{'SDRNum'}} = $hashref;
	$hashref->{customFieldValues} = [
		{fieldName=>'ExternalID',fieldType=>'com.atlassian.jira.plugin.system.customfieldtypes:textfield',value=>'FS-SDR' . $hashref->{SDRNum}}
	];
	my %reason = GetReason($hashref->{resolution});
	if (%reason)
	{
		$hashref->{resolution} = $reason{toString};
	}
	if ($hashref->{ReportedPriority})
	{
		push $hashref->{customFieldValues}, {fieldName=>'Reported Priority', fieldType=>'com.atlassian.jira.plugin.system.customfieldtypes:select',value=>$hashref->{ReportedPriority}};
	}
	$hashref->{externalId} = '' . $hashref->{SDRNum};
	if ($hashref->{assignee})
	{
		$hashref->{assignee} = GetUser($hashref->{assignee});
	}
	if ($hashref->{reporter})
	{
		$hashref->{reporter} = GetUser($hashref->{reporter});
	}
	if ($hashref->{Source})
	{
		$hashref->{description} .= "\nSource: " . $hashref->{Source};
		if ($hashref->{SourceLabel})
		{
			$hashref->{labels} = ['Source_' . $hashref->{SourceLabel}];
		}
	}
	if ($hashref->{Introduced})
	{
		$hashref->{description} .= "\nIntroduced: " . $hashref->{Introduced};
		$hashref->{Introduced} =~ s/\s/_/g;
		$hashref->{Introduced} = 'Introduced_' . $hashref->{Introduced};
		if ($hashref->{labels})
		{
			push $hashref->{labels}, $hashref->{Introduced};
		} else {
			$hashref->{labels} = [$hashref->{Introduced}];
		}
	}
	
	delete $hashref->{SDRNum};
	delete $hashref->{ReportedPriority};
	delete $hashref->{Source};
	delete $hashref->{SourceLabel};
	delete $hashref->{Introduced};
	delete $hashref->{Branch};
}

$sth->finish;

$query = <<'~';
select SDR_Num [issueKey]
,convert(varchar(25), DATEADD(hour, -5, EntryDate), 126) created
,l.Person author
,LineType
,ReasonCode
,REPLACE(cast([Description] as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) [Description]
from STAR..sdr_log l
where SDR_Num in (57003, 57021, 57022, 57068, 53762, 57675, 56641, 59602, 59558)
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
	
	if ($comments->{author})
	{
		$comments->{author} = GetUser($comments->{author});
	}

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
			to => GetUser($comments->{ReasonCode}),
			toString => GetUser($comments->{ReasonCode})
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
		$history{author} = $comments->{author};
		$history{created} = $comments->{created};
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
			$comments->{'ReasonCode'} =~ s/^\s*(.*?)\s*$/$1/;
			if ($comments->{'ReasonCode'})
			{
				$comments->{'body'} .= ' ' . $comments->{'ReasonCode'};
			}
			$comments->{'body'} .= ': ' . $comments->{'Description'};
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
		if ($comments->{'ReasonCode'})
		{
			$comments->{'body'} .= ($comments->{'body'} ? ' ' : '') . '(' . $comments->{'ReasonCode'} . ')';
		}
		$comments->{Description} =~ s/^\s*(.*?)\s*$/$1/;
		if ($comments->{'Description'})
		{
			$comments->{'body'} .= ($comments->{'body'} ? ': ' : '') . $comments->{Description};
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
select sdr_no
	, 'Customer '
	+ case when isnull(CustWaiting, '0') = '1' then 'waiting' else 'reported' end
	+ case when len(isnull(customer, '')) > 0 then ': '
	+ replace(replace(rtrim(customer), char(10), ''), char(13), '') else '' end
	+ case when len(isnull(cust_version, '')) > 0 then char(10) + 'At version: ' + cust_version else '' end
	+ case when len(rtrim(notes)) > 0 then char(10) + ltrim(rtrim(isnull(notes,''))) else '' end body
	, convert(varchar(25), dateadd(hour, -5, s.Date_Reported), 126) created
from STAR..customer c
left join STAR..sdr s on s.SDRNum = c.sdr_no
where sdr_no in (57003, 57021, 57022, 57068, 53762, 57675, 56641, 59602, 59558)
~

$sth = $dbh->prepare($query);
$sth->execute();

while (my $hashref = $sth->fetchrow_hashref())
{
	my $sdr = $sdrLookup{$hashref->{sdr_no}};
	if ($sdr->{comments})
	{
		push $sdr->{comments}, {body=>$hashref->{body}, created=>$hashref->{created}};
	}
	else
	{
		$sdr->{comments} = [{body=>$hashref->{body}, created=>$hashref->{created}}];
	}
}

$sth->finish;

$query = <<'~';
select
	 r.TransmittalId
	,case r.TransmittalType
	 when 'F' then 'New Feature'
	 when 'S' then 'Bug'
	 else 'Feature Enhancement' end parentIssueType
	,s.SDRCount
	,case r.WaitingOn
	 when 'Analyst' then r.Analyst
	 when 'Team Leader' then r.TeamLeader
	 when 'QA' then isnull(r.QATester, r.TeamLeader)
	 else r.TeamLeader end assignee
	,case r.WaitingOn
	 when 'Analyst' then 'Accepted'
	 when 'Team Leader' then 'Development Complete'
	 when 'Release Mgr' then 'Development Complete'
	 when 'Build' then 'Development Complete'
	 when 'QA' then 'Awaiting Verification'
	 when 'Pull' then 'Awaiting Release'
	 when 'Done' then 'Resolved' end [status]
	,case r.WaitingOn
	 when 'Analyst' then 'Awaiting Resolutions'
	 else 'Resolved' end parentIssueStatus
	,case r.WaitingOn
	 when 'Analyst' then 'Waiting'
	 else 'Fixed' end parentIssueResolution	
	,r.RlsLevelTarget affectedVersions
	,r.FunctionalArea components
	,REPLACE(cast(r.ReadMe as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) [description]
	,case SDRSeverity when 'A' then 'P1' when 'B' then 'P2' when 'C' then 'P3' when 'D' then 'P4' else null end priority
	,r.DocoNotes
	,convert(varchar(25), DATEADD(hour, -5, isnull(d.earliest, getdate())), 126) created
	,convert(varchar(25), DATEADD(hour, -5, isnull(d.latest, getdate())), 126) updated
	,FeatOrEnhNum
	,r.Analyst Analyst
	,REPLACE(r.ReleaseLev,'.','_') Branch
from STAR..resolution r
left join (
select TransmittalID, count(*) SDRCount
from STAR..Resolution_SDRs
group by TransmittalID
) s on s.TransmittalID = r.TransmittalId
left join
(select TransmittalID, MIN(entrydate) earliest, MAX(entrydate) latest
from STAR..trans_log
group by TransmittalID) d
on r.TransmittalId = d.TransmittalID
where r.TransmittalId in (48174, 48175, 48603, 48827, 48921, 48922, 50370, 52343, 51651, 51656, 51742, 51612, 51615, 51638)
~
$sth = $dbh->prepare($query);
$sth->execute();

my %resolutions = ();

while (my $hashref = $sth->fetchrow_hashref())
{
	my %resolution = %{$hashref};
	$resolution{issueType} = 'Resolution';
	$resolution{affectedVersions} = $resolution{affectedVersions} . ' (' . $resolution{Branch} . ')';
	($resolution{summary} = '[' . $resolution{Branch} . '] ' . $resolution{description}) =~ s/^(.{3}([^.\n]|\.\d)*)(.|\n|$).*$/$1/gs;
	$version_list{$resolution{'affectedVersions'}} = 1;
	$component_list{$resolution{'components'}} = 1;
	$resolution{components} = [$resolution{components}];
	if ($resolution{DocoNotes})
	{
		$resolution{description} .= "\n" . $resolution{DocoNotes};
		$resolution{labels} = ['documentation'];
	}

	@resolution{customFieldValues} = [
		{fieldName=>'ExternalID',fieldType=>'com.atlassian.jira.plugin.system.customfieldtypes:textfield',value=>'FS-TR' . $resolution{TransmittalId}},
		{fieldName=>'Branch',value=>$resolution{Branch},fieldType=>'com.lawson.tools.jira.customfields:jira-integration-only-field'}
	];
	
	$resolution{affectedVersions} = [$resolution{affectedVersions}];
	$resolution{externalId} = '' . ($resolution{TransmittalId} + 100000);
	$resolutions{$resolution{TransmittalId}} = \%resolution;
	
	if ($resolution{FeatOrEnhNum})
	{
		$resolution{comments} = [{body=>'Enh/Feature ID: ' . $resolution{FeatOrEnhNum},
			created=>$resolution{created},author=>GetUser($resolution{Analyst})}];
	}
	
	if ($resolution{assignee})
	{
		$resolution{assignee} = GetUser($resolution{assignee});
	}
	
	if ($resolution{SDRCount} == 0)
	{
		$sdrLookup{'D'.$resolution{TransmittalId}} =
			 {externalId=>'D'.$resolution{TransmittalId}
			,summary=>$resolution{summary}
			,description=>$resolution{description}
			,status=>$resolution{parentIssueStatus}
			,issueType=>$resolution{parentIssueType}
			,resolution=>$resolution{parentIssueResolution}
			,assignee=>$resolution{assignee}
			,created=>$resolution{created}
			,affectedVersions=>$resolution{affectedVersions}
			,components=>$resolution{components}
		};
		push @dummyBugLinks, {sourceId => $resolution{externalId}, destinationId =>'D'.$resolution{TransmittalId}};
	}
	
	delete $resolution{DocoNotes};		
	delete $resolution{TransmittalId};
	delete $resolution{FeatOrEnhNum};
	delete $resolution{Analyst};
	delete $resolution{parentIssueStatus};
	delete $resolution{parentIssueType};
	delete $resolution{parentIssueResolution};
	delete $resolution{SDRCount};
	delete $resolution{Branch};
}
$sth->finish;

$query = <<'~';
select TransmittalID, convert(varchar(25), DATEADD(hour, -5, entrydate), 126) created
,xl.person author, linetype,
REPLACE(cast([description] as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) [description]
from STAR..trans_log xl
where xl.TransmittalID in (48174, 48175, 48603, 48827, 48921, 48922, 50370, 52343, 51651, 51656, 51742, 51612, 51615, 51638)
~

$sth = $dbh->prepare($query);
$sth->execute();

while (my $transLog = $sth->fetchrow_hashref())
{
	if (exists $resolutions{$transLog->{TransmittalID}})
	{
		my $resolution = $resolutions{$transLog->{TransmittalID}};
		my %hist = %{$transLog};
		
		given (lc $transLog->{linetype})
		{
			when ('transmit') {$hist{items}=[{fieldType=>'jira',field=>'status',from=>'3',fromString=>'Accepted',to=>'5',toString=>'Development Complete'}]}
			when ('built') {$hist{items}=[{fieldType=>'jira',field=>'status',from=>'5',fromString=>'Development Complete',to=>'10002',toString=>'Awaiting Verification'}]}
			when ('tested') {$hist{items}=[{fieldType=>'jira',field=>'status',from=>'10002',fromString=>'Awaiting Verification',to=>'10003',toString=>'Awaiting Release'}]}
			when ('send back') {
				if ($hist{description} =~ m/^to\:\s+Build/)
				{
					$hist{items}=[{fieldType=>'jira',field=>'status',from=>'-1',fromString=>'Unknown',to=>'3',toString=>'Accepted'}]
				}
			}
		}

		if (@hist{items})
		{
			if (exists $resolution->{history})
			{
				push $resolution->{history}, \%hist;
			} else {
				$resolution->{history} = [\%hist];
			}
		}
		$hist{author} = GetUser($hist{author});
		$hist{description} =~ s/^\s*(.*?)\s*$/$1/;
		if ($hist{description} || not @hist{items})
		{
			my $histItem = {created=>$hist{created}, author=>$hist{author}, body=>$hist{linetype} . (($hist{description}) ? ': ' . $hist{description} : '')};
			if(exists $resolution->{comments})
			{
				push $resolution->{comments}, $histItem;
			} else {
				$resolution->{comments} = [$histItem];
			}
		}
		
		delete $hist{TransmittalID};
		delete $hist{linetype};
		delete $hist{description};
	}
}

$sth->finish;

$query = <<'~';
select TransmittalID, isnull(FileToShip, '') + CHAR(9) + isnull(FileChanged, '') + CHAR(9) 
+ isnull(RevisionLevelFrom, '') + '=>' + isnull(RevisionLevelTo, '')
from STAR..FileChanges
where TransmittalID in (48174, 48175, 48603, 48827, 48921, 48922, 50370, 52343, 51651, 51656, 51742, 51612, 51615, 51638)
order by TransmittalID, FCIndex
~
$sth = $dbh->prepare($query);
$sth->execute();
while(my @fileChange = $sth->fetchrow_array())
{
	if (exists $resolutions{$fileChange[0]})
	{
		my $resolution = $resolutions{$fileChange[0]};
		$resolution->{description} .= "\n" . @fileChange[1];
	}
}
$sth->finish;

$query = <<'~';
select r.TransmittalId, s.SDR_Num, s.RowNum
from STAR..resolution r
left join (
select SDR_Num, TransmittalID, ROW_NUMBER() OVER (PARTITION BY TransmittalID ORDER BY SDR_Num DESC) RowNum
from STAR..Resolution_SDRs) s on s.TransmittalID = r.TransmittalId
where SDR_Num is not null
and r.TransmittalId in (48174, 48175, 48603, 48827, 48921, 48922, 50370, 52343, 51651, 51656, 51742, 51612, 51615, 51638)
and s.SDR_Num in (57003, 57021, 57022, 57068, 53762, 57675, 56641, 59602, 59558)
~
$sth = $dbh->prepare($query);
$sth->execute();

my @links = ();

while (my $link = $sth->fetchrow_hashref())
{
	push @links, {name=>($link->{RowNum}==1)?"sub-task-link":"Fixed",sourceId=>(''.($link->{TransmittalId}+100000)),destinationId=>(''.$link->{SDR_Num})};
}
$sth->finish;

for my $dummyLink (@dummyBugLinks)
{
	push @links, {name=>'sub-task-link', %{$dummyLink}};
}

my %import = (users => [values %userMap], projects => [{name=>'JSON Importer Test', key=>'JIT',
	components=>[keys %component_list], versions=>[map({name=>$_}, keys %version_list)],
	issues=>[values %sdrLookup, values %resolutions]}],
	links=>\@links);
print $json->encode(\%import);

# my %linkMap = ();
# my %issMap = ();
# foreach(@{$import{projects}->[0]->{issues}})
# {
	# $issMap{$_->{externalId}} = $_;
# }
# foreach (@links)
# {
   # $linkMap{$_->{sourceId}} = $_->{destinationId};
# }
# say 'parentKey,issueType,status,reporter,priority,description,key,component,ExternalID,assignee,summary,affectedVersion,Branch,resolution,created';
# foreach (@{$import{projects}->[0]->{issues}})
# {
	# my $branch;
	# my $externalId;
	# for (@{$_->{customFieldValues}})
	# {
		# my $custFld = $_;
		# given($custFld->{fieldName})
		# {
			# when ('Branch') {$branch = $custFld->{value};}
			# when ('ExternalID') {$externalId = $custFld->{value};}
		# }
	# }
	# CsvPrint ($issMap{$linkMap{$_->{externalId}}}{key},',');
	# CsvPrint ($_->{issueType},',');
	# CsvPrint ($_->{status},',');
	# CsvPrint ($_->{reporter},',');
	# CsvPrint ($_->{priority},',');
	# CsvPrint ($_->{description},',');
	# CsvPrint ($_->{key},',');
	# CsvPrint ($_->{components}->[0],',');
	# CsvPrint ($externalId,',');
	# CsvPrint ($_->{assignee},',');
	# CsvPrint ($_->{summary},',');
	# CsvPrint ($_->{affectedVersions}->[0],',');
	# CsvPrint ($branch,',');
	# CsvPrint ($_->{resolution},',');
	# CsvPrint ($_->{created});
	# print "\n";
# }

$dbh->disconnect;

sub CsvPrint {
   my $fldVal;
   ($fldVal = $_[0]) =~ s/\"/\"\"/g;
   print "\"$fldVal\"";
   if ($_[1]) { print $_[1] };
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

sub GetUser {
	if (not $_[0] =~ m/\S/)
	{
		return '';
	}
	if (exists $userMap{$_[0]})
	{
		return $userMap{$_[0]}->{name} // 'WebStar_' . $_[0];
	}
	$userMap{$_[0]} = {name=>'WebStar_' . $_[0], active=>JSON::false, email=>'no.reply@infor.com'};
	return 'WebStar_' . $_[0];
}