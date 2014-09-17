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
$dbh->{LongReadLen} = 100000;

my $query = <<'~';
select NTUserName, EmailAddr, UserName, Access, FullName, Active
from StarMap..UserInfo
~

my $sth = $dbh->prepare($query);
$sth->execute();

my %userMap = ('nobody' => {name=>'WebStar_nobody', active=>JSON::false, email=>'nobody@softbrands.com', fullname=>'Nobody Imported'});
my %usersUsed = ();

my $argCount = @ARGV;
die 'Releases must be specified on command line.' if ($argCount == 0);
my $subsetMode = 1; # 0 = All releases; 1 = specified releases only.
my $userCSVMode = 0; # 1 = Only output user list in CSV form instead of everything in JSON format.
if (lc $ARGV[0] eq 'u')
{
	$subsetMode = 0;
	$userCSVMode = 1;
}
my $releaseList = join(',', map { "'$_'" } @ARGV);

while (my @userInfo = $sth->fetchrow_array())
{	
	$userInfo[0] =~ /^([^\\]*)\\(\S*)\s*$/ or die 'Failed to parse ' . $userInfo[0];
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
		#$userRec->{email}='no.reply@infor.com';
		$userRec->{email}=$userName . '@softbrands.com';
	}
	if ($userInfo[4])
	{
		$userRec->{fullname} = $userInfo[4];
	}
	$userMap{$userInfo[2]} = $userRec;
}
$sth->finish;

$query = <<'~';
select s.SDRNum
, case Severity when 'A' then '1 - Show-Stopper' when 'B' then '2 - Critical' when 'C' then '3 - Major' when 'D' then '4 - Minor' else null end ReportedPriority
, case Priority when '@' then 'P1' when 'ß' then 'P2' when '*' then 'P3' when 'H' then 'P4' else 'P5' end priority
, case when tc.TransCount > 0 then case when r.IsReleased=1 then 'Resolved' else 'Awaiting Resolutions' end else
  case Status
  when 'W' then 'Resolved'
  when 'C' then 'Resolved'
  else 'Open' end end status
, case when tc.TransCount > 0 then case when r.IsReleased=1 then 'Fixed' else 'Waiting' end else
  case Status when 'W' then case ReasonCode
  when 'Future Release' then 'No Plans to Fix'
  when 'Need More Info' then 'Incomplete'
  when 'Mystery' then 'Cannot Reproduce'
  else '' end -- Unresolved
  when 'C' then case ReasonCode
  when 'No Problem' then 'Works As Designed'
  when 'No Fix' then 'No Plans to Fix'
  when 'Duplicate' then 'Duplicate'
  when 'Fixed' then 'Fixed Other'
  else 'Fixed Other' end
  else '' end end resolution -- Unresolved
, s.Submitter reporter
, s.AssignedTo assignee
, convert(varchar(25), DATEADD(hour, 5, s.Date_Reported), 126) created
, convert(varchar(25), DATEADD(hour, 5, s.DateClosed), 126) resolutionDate
, isnull(r.JIRAVersion, s.Version) affectedVersions
, case when s.Level3 is null then s.Level2 else s.Level2 + '_' + s.Level3 end components
, ProblemBrief summary
, REPLACE(cast(ProblemDetail as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) description
, case ProbEnh when 'E' then 'Feature Enhancement' else 'Bug' end issueType
, Source
, Introduced
, REPLACE(s.Release, '.', '_') Branch
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
, r.HotfixLabel
, r.LanguageLabel
from STAR..sdr s
left join StarMap..ReleaseIDs r on s.[Version] = r.ReleaseID
join StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
left join (
select rs.SDR_Num, COUNT(*) TransCount
from STAR..Resolution_SDRs rs
group by rs.SDR_Num) tc on tc.SDR_Num = s.SDRNum 
~

if ($subsetMode == 1) {
	$query .= "where ri.Release in ($releaseList)";
}

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
	$version_list{$hashref->{'affectedVersions'}} = 1;
	$version_list{$hashref->{'Branch'}} = 1;
	$hashref->{'affectedVersions'} = [$hashref->{'affectedVersions'}];
	$sdrLookup{$hashref->{'SDRNum'}} = $hashref;
	$hashref->{customFieldValues} = [
		{fieldName=>'ExternalID',fieldType=>'com.atlassian.jira.plugin.system.customfieldtypes:textfield',value=>'FS-SDR' . $hashref->{SDRNum}}
	];
	if ($hashref->{ReportedPriority})
	{
		push $hashref->{customFieldValues}, {fieldName=>'Reported Priority', fieldType=>'com.atlassian.jira.plugin.system.customfieldtypes:select',value=>$hashref->{ReportedPriority}};
	}
	$hashref->{externalId} = '' . $hashref->{SDRNum};
	if ($hashref->{assignee})
	{
		$hashref->{assignee} = GetUser($hashref->{assignee});
	} else {
		$hashref->{assignee} = GetUser('yatess');
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
	if ($hashref->{HotfixLabel})
	{
		if ($hashref->{labels})
		{
			push $hashref->{labels}, $hashref->{HotfixLabel};
		} else {
			$hashref->{labels} = [$hashref->{HotfixLabel}];
		}
	}
	if ($hashref->{LanguageLabel})
	{
		if ($hashref->{labels})
		{
			push $hashref->{labels}, $hashref->{LanguageLabel};
		} else {
			$hashref->{labels} = [$hashref->{LanguageLabel}];
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
	
	delete $hashref->{description} if (not $hashref->{description});
	delete $hashref->{resolutionDate} if (not $hashref->{resolutionDate});
	delete $hashref->{SDRNum};
	delete $hashref->{ReportedPriority};
	delete $hashref->{Source};
	delete $hashref->{SourceLabel};
	delete $hashref->{Introduced};
	delete $hashref->{Branch};
	delete $hashref->{HotfixLabel};
	delete $hashref->{LanguageLabel};
}

$sth->finish;

$query = <<'~';
select l.SDR_Num [issueKey]
,convert(varchar(25), DATEADD(hour, -5, l.EntryDate), 126) created
,l.Person author
,l.LineType
,l.ReasonCode
,REPLACE(cast(l.[Description] as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) [Description]
from STAR..sdr_log l
join STAR..sdr s on s.SDRNum = l.SDR_Num
join StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
~

if ($subsetMode == 1) {
	$query .= "where ri.Release in ($releaseList)";
}

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
	elsif (lc $comments->{LineType} eq 'priority' && $comments->{ReasonCode})
	{
		my $sev = $comments->{ReasonCode};
		$history{items} = [{
			fieldType => 'jira',
			field => 'priority',
			from => 'P0',
			fromString => 'Unknown',
			to => ($sev eq '@') ? 'P1' : ($sev eq 'ß') ? 'P2' : ($sev eq '*') ? 'P3' : ($sev eq 'H') ? 'P4' : 'P5',
			toString => ($sev eq '@') ? '1' : ($sev eq 'ß') ? '2' : ($sev eq '*') ? '3' : ($sev eq 'H') ? '4' : '5'
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
	, convert(varchar(25), dateadd(hour, 5, s.Date_Reported), 126) created
from STAR..customer c
left join STAR..sdr s on s.SDRNum = c.sdr_no 
join StarMap..ReleaseIssues ri on ri.SDRNum = s.SDRNum
~

if ($subsetMode == 1) {
	$query .= "where ri.Release in ($releaseList)";
}

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

$query = <<"~";
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
	 when 'Pull' then case when ri.IsReleased=0 then 'Awaiting Release' else 'Resolved' end
	 when 'Done' then 'Resolved' end [status]
	,case when r.WaitingOn='Analyst' or ri.IsReleased=0 then 'Awaiting Resolutions'
	 else 'Resolved' end parentIssueStatus
	,case when r.WaitingOn='Analyst' or ri.IsReleased=0 then 'Waiting'
	 else 'Fixed' end parentIssueResolution
	,case r.WaitingOn
	 when 'Done' then 'Fixed'
	 when 'Pull' then 'Fixed'
	 else '' end resolution -- Unresolved
	,isnull(ri.JIRAVersion, r.RlsLevelTarget) affectedVersions
	,r.FunctionalArea
	,REPLACE(cast(r.ReadMe as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) [description]
	,case SDRSeverity when 'A' then '1 - Show-Stopper' when 'B' then '2 - Critical' when 'C' then '3 - Major' when 'D' then '4 - Minor' else null end ReportedPriority
	,case sd.Priority when '\@' then 'P1' when 'ß' then 'P2' when '*' then 'P3' when 'H' then 'P4' else 'P3' end priority
	,r.DocoNotes
	,convert(varchar(25), DATEADD(hour, 5, isnull(d.earliest, getdate())), 126) created
	,convert(varchar(25), DATEADD(hour, 5, isnull(d.latest, getdate())), 126) updated
	,FeatOrEnhNum
	,r.Analyst Analyst
	,REPLACE(r.ReleaseLev,'.','_') Branch
	,ri.LanguageLabel
	,ri.HotfixLabel
	,case when sd.Level3 is null then sd.Level2 else sd.Level2 + '_' + sd.Level3 end components
from STAR..resolution r
left join (
select ssr.TransmittalID, count(*) SDRCount, max(SDR_Num) LastSDR, min(ss.Release) SdrRelease
from STAR..Resolution_SDRs ssr
join STAR..sdr ss on ssr.SDR_Num = ss.SDRNum
join StarMap..ReleaseIssues ris on ris.SDRNum = ss.SDRNum
group by ssr.TransmittalID
) s on s.TransmittalID = r.TransmittalId
left join
(select TransmittalID, MIN(entrydate) earliest, MAX(entrydate) latest
from STAR..trans_log
group by TransmittalID) d
on r.TransmittalId = d.TransmittalID
left join StarMap..ReleaseIDs ri on ri.ReleaseID = r.RlsLevelTarget
join StarMap..ReleaseIssues riss on riss.TransmittalId = r.TransmittalId
left join STAR..sdr sd on sd.SDRNum = s.LastSDR 
~

if ($subsetMode == 1) {
	$query .= "where riss.Release in ($releaseList)";
}

$sth = $dbh->prepare($query);
$sth->execute();

my %resolutions = ();

while (my $hashref = $sth->fetchrow_hashref())
{
	my %resolution = %{$hashref};
	$resolution{issueType} = 'Resolution';
	($resolution{summary} = '[' . $resolution{Branch} . '] ' . $resolution{description}) =~ s/^(.{3}([^.\n]|\.\d)*)(.|\n|$).*$/$1/gs;
	$version_list{$resolution{'affectedVersions'}} = 1;
	$version_list{$resolution{'Branch'}} = 1;
	if ($resolution{components})
	{
		$component_list{$resolution{'components'}} = 1;
		$resolution{components} = [$resolution{components}];
	} else {
		delete $resolution{components};
	}
	if ($resolution{DocoNotes})
	{
		$resolution{description} .= "\n" . $resolution{DocoNotes};
		$resolution{labels} = ['documentation'];
	}

	if ($resolution{FunctionalArea} =~ m/\S/)
	{
		$resolution{description} .= "\nFunctional Area: " . $resolution{FunctionalArea};
	}
	
	@resolution{customFieldValues} = [
		{fieldName=>'ExternalID',fieldType=>'com.atlassian.jira.plugin.system.customfieldtypes:textfield',value=>'FS-TR' . $resolution{TransmittalId}},
		{fieldName=>'Branch',value=>$resolution{Branch},fieldType=>'com.lawson.tools.jira.customfields:jira-integration-only-field'}
	];
	
	$resolution{affectedVersions} = [$resolution{affectedVersions}];
	if ($resolution{resolution} eq 'Fixed')
	{
		$resolution{fixedVersions} = $resolution{affectedVersions};
	} else {
		$resolution{fixedVersions} = [$resolution{Branch}];
	}
	$resolution{externalId} = '' . ($resolution{TransmittalId} + 100000);
	$resolutions{$resolution{TransmittalId}} = \%resolution;
	
	if ($resolution{FeatOrEnhNum})
	{
		$resolution{comments} = [{body=>'Enh/Feature ID: ' . $resolution{FeatOrEnhNum},
			created=>$resolution{created},author=>GetUser($resolution{Analyst})}];
	}

	$resolution{reporter} = GetUser($resolution{Analyst});
	
	if ($resolution{assignee})
	{
		$resolution{assignee} = GetUser($resolution{assignee});
	} else {
		die "${resolution{TransmittalId}} has no assignee";
	}

	if ($resolution{ReportedPriority})
	{
		push @resolution{customFieldValues}, {fieldName=>'Reported Priority', fieldType=>'com.atlassian.jira.plugin.system.customfieldtypes:select',value=>$resolution{ReportedPriority}};
	}
	
	if ($resolution{LanguageLabel})
	{
		if ($resolution{labels})
		{
			push $resolution{labels}, $resolution{LanguageLabel};
		} else {
			$resolution{labels} = [$resolution{LanguageLabel}];
		}
	}

	if ($resolution{HotfixLabel})
	{
		if ($resolution{labels})
		{
			push $resolution{labels}, $resolution{HotfixLabel};
		} else {
			$resolution{labels} = [$resolution{HotfixLabel}];
		}
	}
	
	if (not $resolution{resolution})
	{
		$resolution{resolutionDate} = '';
	}
	
	if ($resolution{SDRCount} == 0)
	{
		my $dummyBug =
			 {externalId=>'D'.$resolution{TransmittalId}
			,summary=>$resolution{summary}
			,status=>$resolution{parentIssueStatus}
			,issueType=>$resolution{parentIssueType}
			,resolution=>$resolution{parentIssueResolution}
			,assignee=>$resolution{assignee}
			,created=>$resolution{created}
			,affectedVersions=>$resolution{affectedVersions}
			,reporter=>$resolution{reporter}
		};
		
		$dummyBug->{description} = $resolution{description} if ($resolution{description});
		push $dummyBug->{components} = $resolution{components} if ($resolution{components});

		$sdrLookup{'D'.$resolution{TransmittalId}} = $dummyBug;

		push @dummyBugLinks, {sourceId => $resolution{externalId}, destinationId =>'D'.$resolution{TransmittalId}};
	}
	
	delete $resolution{description} if (not $resolution{description});
	delete $resolution{DocoNotes};		
	delete $resolution{TransmittalId};
	delete $resolution{FeatOrEnhNum};
	delete $resolution{Analyst};
	delete $resolution{parentIssueStatus};
	delete $resolution{parentIssueType};
	delete $resolution{parentIssueResolution};
	delete $resolution{SDRCount};
	delete $resolution{Branch};
	delete $resolution{ReportedPriority};
	delete $resolution{LanguageLabel};
	delete $resolution{HotfixLabel};
	delete $resolution{FunctionalArea};
}
$sth->finish;

$query = <<"~";
select xl.TransmittalID, convert(varchar(25), DATEADD(hour, 5, xl.entrydate), 126) created
,xl.person author, xl.linetype,
REPLACE(cast(xl.[description] as nvarchar(max)), CHAR(13) + CHAR(10), CHAR(10)) [description]
,xl.[role]
from STAR..trans_log xl
join STAR..resolution r on r.TransmittalId = xl.TransmittalID 
join StarMap..ReleaseIssues ri on ri.TransmittalId = r.TransmittalId
~

if ($subsetMode == 1) {
	$query .= "where ri.Release in ($releaseList)";
}

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
			my $histItem = {created=>$hist{created}, author=>$hist{author},
				body=>$hist{linetype} . 
				(($hist{role} =~ m/\S/) ? ' (' . $hist{role}. ')' : '') .
				(($hist{description}) ? ': ' . $hist{description} : '')};
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
		delete $hist{role};
	}
}

$sth->finish;

my $whereClause = '';
if ($subsetMode == 1) {
	$whereClause = "where ri.Release in ($releaseList)";
}

$query = <<"~";
select f.TransmittalID, isnull(f.FileToShip, '') + CHAR(9) + isnull(f.FileChanged, '') + CHAR(9) 
+ isnull(f.RevisionLevelFrom, '') + '=>' + isnull(f.RevisionLevelTo, '')
from STAR..FileChanges f
join STAR..resolution r on r.TransmittalId = f.TransmittalId
join StarMap..ReleaseIssues ri on ri.TransmittalId = r.TransmittalId
$whereClause
order by f.TransmittalID, f.FCIndex
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

$query = <<"~";
select r.TransmittalId, s.SDR_Num, s.RowNum
from STAR..resolution r
left join (
select ssr.SDR_Num, ssr.TransmittalID, ss.Release, ROW_NUMBER() OVER (PARTITION BY ssr.TransmittalID ORDER BY SDR_Num DESC) RowNum
from STAR..Resolution_SDRs ssr
join STAR..sdr ss on ss.SDRNum = ssr.SDR_Num
join StarMap..ReleaseIssues ri on ri.SDRNum = ss.SDRNum
) s on s.TransmittalID = r.TransmittalId
join StarMap..ReleaseIssues ri on ri.TransmittalId = r.TransmittalId 
~

if ($subsetMode == 1) {
	$query .= "where ri.Release in ($releaseList)";
}

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

if (exists $version_list{'8.0'})
{
	$version_list{'8.00'} = $version_list{'8.0'};
	delete $version_list{'8.0'};
}

if (exists $version_list{'8_0'})
{
	$version_list{'8_00'} = $version_list{'8_0'};
	delete $version_list{'8_0'};
}

for my $s (values %sdrLookup) {
	@{$s->{affectedVersions}} = map($_ eq '8.0' ? '8.00' : $_, @{$s->{affectedVersions}}) if ($s->{affectedVersions});
	@{$s->{fixedVersions}} = map($_ eq '8.0' ? '8.00' : $_, @{$s->{fixedVersions}}) if ($s->{fixedVersions});
	@{$s->{affectedVersions}} = map($_ eq '8_0' ? '8_00' : $_, @{$s->{affectedVersions}}) if ($s->{affectedVersions});
	@{$s->{fixedVersions}} = map($_ eq '8_0' ? '8_00' : $_, @{$s->{fixedVersions}}) if ($s->{fixedVersions});
	if ($s->{customFieldValues})
	{
		for my $f (values $s->{customFieldValues}) {
			if ($f->{value} eq '8_0') {
				$f->{value} = '8_00';
			}
		}
	}
}

for my $t (values %resolutions) {
	@{$t->{affectedVersions}} = map($_ eq '8.0' ? '8.00' : $_, @{$t->{affectedVersions}}) if ($t->{affectedVersions});
	@{$t->{fixedVersions}} = map($_ eq '8.0' ? '8.00' : $_, @{$t->{fixedVersions}}) if ($t->{fixedVersions});
	@{$t->{affectedVersions}} = map($_ eq '8_0' ? '8_00' : $_, @{$t->{affectedVersions}}) if ($t->{affectedVersions});
	@{$t->{fixedVersions}} = map($_ eq '8_0' ? '8_00' : $_, @{$t->{fixedVersions}}) if ($t->{fixedVersions});
	if ($t->{customFieldValues})
	{
		for my $f (values $t->{customFieldValues}) {
			if ($f->{value} eq '8_0') {
				$f->{value} = '8_00';
			}
		}
	}
	$t->{summary} =~ s/^\[8_0\] /\[8_00\] /;
}

if ($userCSVMode) {
	print "name,email,fullname,active,group1,group2\n";
	for my $u (values %userMap)
	{
		print $u->{name} . ',' . $u->{email} . ',' . $u->{fullname} . ',' . $u->{active} . ',';
		print $u->{groups}->[0] if (exists $u->{groups}->[0]);
		print ',';
		print $u->{groups}->[1] if (exists $u->{groups}->[1]);
		print "\n";
	}	
} else {
	my %import = (users => [values %usersUsed], projects => [{name=>'JSON Importer Test', key=>'JIT',
		components=>[keys %component_list], versions=>[map({name=>$_}, sort keys %version_list)],
		issues=>[values %sdrLookup, values %resolutions]}],
		links=>\@links);
	print $json->encode(\%import);
}

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
		$usersUsed{'WebStar_nobody'} = $userMap{'WebStar_nobody'};
		return 'WebStar_nobody';
	}
	if (exists $userMap{$_[0]})
	{
		$usersUsed{$_[0]} = $userMap{$_[0]};
		return $userMap{$_[0]}->{name} // 'WebStar_' . $_[0];
	}
	$userMap{$_[0]} = {name=>'WebStar_' . $_[0], active=>JSON::false, email=>$_[0] . '@softbrands.com'};
	$usersUsed{$_[0]} = $userMap{$_[0]};
	return 'WebStar_' . $_[0];
}