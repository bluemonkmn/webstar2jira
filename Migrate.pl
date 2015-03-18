use IPC::Open3;
use Data::Printer;
use File::Path qw(make_path rmtree);
my $accurev = 'c:\Program Files (x86)\AccuRev\bin\accurev.exe';
my $sscmd = 'c:\Program Files (x86)\Microsoft Visual SourceSafe\ss.exe';
my $tmp = $ENV{'TMP'};
my $depot = 'FSX';
my $prepend = 'DMS'; # prepended to created stream names in case multiple test imports need to be done.
my $rootStream = $prepend ? "${depot}_${prepend}" : $depot;
my $ssdb = 'C:\Users\bmarty\Downloads\DMS_VSS';
my $wsDir = "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}Migrate";
my $ssDMSOld = '$/DMS';
my $ssDMS2 = '$/DMS_FS75E';

LogMsg('Starting migration at ' . localtime());

$ENV{'SSDIR'}=$ssdb;
MakeStream($rootStream, $depot);
# DMS Old
MakeStream(StmName("Old"), $rootStream);
MakeWorkspace(StmName('Migrate'), StmName("Old"), $wsDir);
chdir $wsDir or die $!;
VSSWorkFold($ssDMSOld, $wsDir);
RecursiveDelete();
VSSGetByDate($ssDMSOld, '8/15/2013;8:22p');
CommitAll('Import DMS 3.0.1 code as of 8/15/2013 8:22 pm');
MakeSnapshot(StmName("3.0.1_SP"), StmName("Old"));
RecursiveDelete();
VSSGetByDate($ssDMSOld, '9/11/2013;7:22p');
CommitAll('Import DMS 3.0.2 code as of 9/11/2013 7:22 pm');
MakeSnapshot(StmName("3.0.2_SP"), StmName("Old"));
RecursiveDelete();
VSSGetByDate($ssDMSOld, '9/12/2013;7:51p');
CommitAll('Import DMS 3.0.3 code as of 9/12/2013 7:51 pm');
MakeSnapshot(StmName("3.0.3_SP"), StmName("Old"));
RecursiveDelete();
VSSGetByDate($ssDMSOld, '9/13/2013;3:54a');
CommitAll('Import DMS 3.0.4 code as of 9/13/2013 3:54 am');
MakeSnapshot(StmName("3.0.4_SP"), StmName("Old"));
RecursiveDelete();
VSSGetByDate($ssDMSOld, '10/30/2013;8:19p');
CommitAll('Import DMS 3.0.5 code as of 10/30/2013 8:19 pm');
MakeSnapshot(StmName("3.0.5_SP"), StmName("Old"));
RecursiveDelete();
VSSGetByDate($ssDMSOld, '11/07/2013;6:58p');
CommitAll('Import DMS 3.0.6 code as of 11/07/2013 6:58 pm');
MakeSnapshot(StmName("3.0.6_SP"), StmName("Old"));
RecursiveDelete();
VSSGetByDate($ssDMSOld, '11/17/2013;7:43p');
CommitAll('Import DMS 3.0.7 code as of 11/17/2013 7:43 pm');
MakeSnapshot(StmName("3.0.7_SP"), StmName("Old"));
RecursiveDelete();
VSSGetByDate($ssDMSOld, '6/30/2014;11:18p');
CommitAll('Import DMS 3.0.8 code as of 6/30/2014 11:18 pm');
MakeSnapshot(StmName("3.0.8_SP"), StmName("Old"));

# DMS 2
MakeStream(StmName("2"), StmName("Old"));
print STDERR "Make sure $wsDir is clean, then press enter.\n";
<STDIN>;
ReparentWorkspace(StmName('Migrate'), StmName("2"));
chdir $wsDir or die $!;
VSSWorkFold($ssDMS2, $wsDir);
RecursiveDelete();
VSSGetByDate($ssDMS2 '6/30/2014;11:18p');
CommitAll('Import DMS 2.0 code as of 6/30/2014 11:18 pm');

sub StmName {
	return "${depot}_${prepend}_" . $_[0];
}

sub VSSGetByDate {
	my $ssPath = $_[0];
	my $date = $_[1];
	system("\"$sscmd\" Get \"$ssPath\" -R -GF -GWR -I-Y -W -Vd$date");
	if ($?)
	{
		die "Failed to retrieve ss code by date for $date.";
	}
	system('del *.scc /S /Q /F');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving code for date $date.";
	}
	system('del *.scc /S /Q /F /AH');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving code for date $date.";
	}
}

sub VSSGetLatest {
	my $ssPath = $_[0];
   my $localPath = $_[1];
   
   VSSWorkFold($ssPath, $localPath);
   chdir $localPath or die $!;
   RecursiveDelete();
	#print STDERR "From $ssPath retrieve the latest code, then press enter to continue.\n";
	#<STDIN>;
	system("\"$sscmd\" Get \"$ssPath\" -R -GF -GWR -I-Y -W");
	if ($?)
	{
		die "Failed to retrieve latest code.";
	}
	system('del *.scc /S /Q /F');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving latest code.";
	}
	system('del *.scc /S /Q /F /AH');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving latest code.";
	}
}

sub VSSWorkFold {
	my $ssPath = $_[0];
	my $localPath = $_[1];
   make_path($localPath);
	system("\"$sscmd\" Workfold \"$ssPath\" \"$localPath\"");
	if ($?)
	{
		die "Failed to retrieve $label";
	}
}

sub CommitAll {
	my $groupCmt = $_[0];
	AccuRev("add -x","$groupCmt - Add new files.", 1);
	AccuRev("keep -m","$groupCmt - Keep changed files.", 1);
	if (AccuRevTo("stat -M -fal","$tmp\\accurev.txt","$groupCmt - Retrieving missing file list."))
	{
		AccuRev("defunct -l \"$tmp\\accurev.txt\"","$groupCmt - Defunct missing files.", 1);
	}
	if (-e "$tmp\\accurev.txt")
	{
		unlink "$tmp\\accurev.txt" or die "Failed to delete $tmp\\accurev.txt";
	}
	AccuRev("promote -d",$groupCmt, 1);
}

sub MakeStream {
	my $newStream = $_[0];
	my $basis = $_[1];
	AccuRev("mkstream -s $newStream -b $basis", "Create stream $newStream under $basis.");
}

sub MakeSnapshot {
	my $newStream = $_[0];
	my $basis = $_[1];
	AccuRev("mksnap -s $newStream -b $basis -t now", "Create stream $newStream under $basis.");
}

sub MakeWorkspace {
	my $wsName = $_[0];
	my $basis = $_[1];
	my $location = $_[2];
	AccuRev("mkws -w $wsName -b $basis -l $location", "Create workspace $wsName under $basis at $location.");
	chdir $location or die $!;
	AccuRev('update');
}

sub ReparentWorkspace {
	my $wsName = $_[0];
	my $basis = $_[1];
	AccuRev("chws -w $wsName -b $basis");
	AccuRev('update');
}

sub LogMsg {
	my $msg = $_[0];
	print "$msg\n";
}

sub AccuRevTo {
	my $cmd = $_[0];
	my $out = $_[1];
	my $cmt = $_[2];
	#$_[3] = Switch: also use Log comment as comment on AccuRev command line
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
    #$_[0] = Command line
	#$_[1] = Log comment
	#$_[2] = Switch: also use Log comment as comment on AccuRev command line
	@results = AccuRevTo($_[0], "&STDOUT", $_[1], $_[2]);
	return @results;
}

sub RecursiveDelete {
	`del *.* /F /S /Q /A-H`; # Holy risky, Batman!
	if ($?)
	{
		die "Error deleting files from $pattern.";
	}
	my @visibleDirs = `dir "$pattern" /B /a-h`;
	if ($?)
	{
		die "Error listing directories from $pattern.";
	}
	if (@visibleDirs)
	{
		chomp @visibleDirs;
		rmtree(\@visibleDirs) or die $!;
	}
}