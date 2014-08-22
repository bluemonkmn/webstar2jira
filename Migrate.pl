use IPC::Open3;
use Data::Printer;
my $accurev = 'c:\Program Files (x86)\AccuRev\bin\accurev.exe';
my $vss = 'c:\Program Files (x86)\Microsoft Visual SourceSafe\ss.exe';
my $tmp = $ENV{'TMP'};
my $depot = 'FS1';
my $vss73 = 'C:\Users\bmarty\Downloads\R73';
my $ws73 = "C:\\Users\\bmarty\\AccuRev\\${depot}_7.30";
my $vss74 = 'C:\Users\bmarty\Downloads\R74';
my $ws74 = "C:\\Users\\bmarty\\AccuRev\\${depot}_7.40";
print $ws73;

$ENV{'SSDIR'}=$vss73;

LogMsg('Starting migration at ' . localtime());

CommitAll("Import VSS Label 7.30D");
`$accurev mkstream -s ${depot}_7.30D_SP -t now`;
VSSGet('$/R73','7.30E');
CommitAll("Import VSS Label 7.30E");
`$accurev mkstream -s ${depot}_7.30E_SP -t now`;
VSSGet('$/R73','7.30F');

$ENV{'SSDIR'}=$ws74;


sub VSSGet {
	my $ssPath = $_[0];
	my $label = $_[1];
	`"$vss" Get "$ssPath" -R -GF -GWR -I-Y -W -Vl$label 2>&1`;
	if ($?)
	{
		die "Failed to retrieve $label";
	}
}

sub CommitAll {
	my $groupCmt = $_[0];
	AccuRev("add -x","$groupCmt - Add new files.");
	AccuRev("keep -m","$groupCmt - Keep changed files.");
	if (AccuRevTo("stat -M -fal","$tmp\\accurev.txt","$groupCmt - Retrieving missing file list."))
	{
		AccuRev("defunct -l \"$tmp\\accurev.txt\"","$groupCmt - Defunct missing files.");
	}
	if (-e "$tmp\\accurev.txt")
	{
		unlink "$tmp\\accurev.txt" or die "Failed to delete $tmp\\accurev.txt";
	}
	AccuRev("promote -d",$groupCmt);
}

sub LogMsg {
	my $msg = $_[0];
	print "$msg\n";
}

sub AccuRevTo {
	my $cmd = $_[0];
	my $out = $_[1];
	my $cmt = $_[2];
	LogMsg $cmt;
	my $cmdLine = "\"$accurev\" $cmd";
	$cmdLine .= " -c \"$cmt\"" if $_[3];
	local *CATCHERR = IO::File->new_tmpfile();
	LogMsg $cmdLine;
	my $in = '';
	my $pid = open3($in,\*CATCHOUT,">&CATCHERR",$cmdLine);
	local $/ = "\r\n";
	my @results = <CATCHOUT>;
	waitpid $pid, 0;
	seek CATCHERR, 0, 0;
	my @errText = <CATCHERR>;
	chomp @errText;
	chomp @results;
	if ($?)
	{
		if (@errText[0] eq "No elements selected.")
		{
			LogMsg("No elements is OK.");
		} else {
			die join("\r\n", @errText) . "\n";
		}
	}
	if (@results)
	{
		open FH,">$out" or die "Failed to write to $out";
		print FH join("\r\n", @results) . "\n";
		close FH;
	}
	if (@errText)
	{
		print join("\r\n", @errText) . "\n";
	}
	return @results;
}

sub AccuRev {
	my @results = AccuRevTo($_[0], "&STDOUT", $_[1], 1);
	return @results;
}