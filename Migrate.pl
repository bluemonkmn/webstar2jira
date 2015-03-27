use IPC::Open3;
use Data::Printer;
use File::Path;
my $accurev = 'c:\Program Files (x86)\AccuRev\bin\accurev.exe';
my $sscmd = 'c:\Program Files (x86)\Microsoft Visual SourceSafe\ss.exe';
my $tmp = $ENV{'TMP'};
my $depot = 'FSX';
my $prepend = 'VisiWatch'; # prepended to created stream names in case multiple test imports need to be done.
my $rootStream = $prepend ? "${depot}_${prepend}" : $depot;
my $ssdb = 'C:\Users\bmarty\Downloads\DemandStream';
my $wsDir = "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}Migrate";
my $ssPath = '$/VisiWatch';

LogMsg('Starting migration at ' . localtime());

# 2.5.5
$ENV{'SSDIR'}=$ssdb;
MakeStream($rootStream, $depot);
MakeWorkspace(StmName('Migrate'), $rootStream, $wsDir);
mkdir "$wsDir\\Source" or die $!;
mkdir "$wsDir\\Install" or die $!;
mkdir "$wsDir\\Install\\Script Files" or die $!;
chdir $wsDir or die $!;
VSSGet("$ssPath/VisiWatch 2.5.5 Source/*", "$wsDir\\Source");
VSSGet("$ssPath/VisiWatch 2.5.5 Install/*", "$wsDir\\Install\\Script Files");
VSSGet("$ssPath/VisiWatch 2.5.5.ism", "$wsDir\\Install");
rename "$wsDir\\Install\\VisiWatch 2.5.5.ism", "$wsDir\\Install\\VisiWatch.ism" or die $!;
unlink "$wsDir\\Source\\Visiwatch.exe" or die $!;
unlink "$wsDir\\Source\\crystal.bak" or die $!;
CommitAll('Import VisiWatch 2.5.5 Source and Install code.');
MakeSnapshot(StmName('2.5.5_SP'), $rootStream);
# 2.5.6
RecursiveDelete();
mkdir "$wsDir\\Source" or die $!;
mkdir "$wsDir\\Install" or die $!;
mkdir "$wsDir\\Install\\Script Files" or die $!;
VSSGet("$ssPath/VisiWatch 2.5.6 Source/*", "$wsDir\\Source");
VSSGet("$ssPath/VisiWatch 2.5.6/*", "$wsDir\\Install\\Script Files");
VSSGet("$ssPath/VisiWatch 2.5.6.ism", "$wsDir\\Install");
rename "$wsDir\\Install\\VisiWatch 2.5.6.ism", "$wsDir\\Install\\VisiWatch.ism" or die $!;
rename "$wsDir\\Source\\VW256ReleaseNotes.doc", "$wsDir\\VW256ReleaseNotes.doc" or die $!;
unlink "$wsDir\\Source\\VisiWatch.exe" or die $!;
unlink "$wsDir\\Source\\ReleaseNotes.pdf" or die $!;
unlink "$wsDir\\Source\\ReleaseNotes.chm" or die $!;
CommitAll('Import VisiWatch 2.5.6 Source and Install code.');
MakeSnapshot(StmName('2.5.6_SP'), $rootStream);
# 2.5.7
chdir "$wsDir\\Source" or die $!;
RecursiveDelete();
VSSGet("$ssPath/VisiWatch 2.5.7 Source/*", "$wsDir\\Source");
CommitAll('Import VisiWatch 2.5.7 Source.');
MakeSnapshot(StmName('2.5.7_SP'), $rootStream);
# 2.5.8
RecursiveDelete();
VSSGet("$ssPath/VisiWatch 2.5.8/*", "$wsDir\\Source");
unlink glob "$wsDir\\Source\\*.log" or die $!;
unlink "$wsDir\\Source\\VisiWatch.exe" or die $!;
unlink "$wsDir\\Source\\VisiWatch.bak" or die $!;
unlink "$wsDir\\Source\\Visiwatch.asc" or die $!;
CommitAll('Import VisiWatch 2.5.8 Source.');
MakeSnapshot(StmName('2.5.8_SP'), $rootStream);
# 2.5.9
RecursiveDelete();
VSSGet("$ssPath/VisiWatch 2.5.9/*", "$wsDir\\Source");
rename "$wsDir\\Source\\VW258ReleaseNotes.doc", "$wsDir\\VW258ReleaseNotes.doc" or die $!;
unlink "$wsDir\\Source\\VW_2581_Test.zip" or die $!;
unlink "$wsDir\\Source\\Visiwatch258.zip" or die $!;
unlink "$wsDir\\Source\\Visiwatch.exe" or die $!;
unlink glob "$wsDir\\Source\\*.log" or die $!;
unlink glob "$wsDir\\Source\\*.bak" or die $!;
unlink "$wsDir\\Source\\test.bas" or die $!;
unlink "$wsDir\\Source\\tracetest.txt" or die $!;
unlink "$wsDir\\Source\\Visiwatch.asc" or die $!;
CommitAll('Import VisiWatch 2.5.9 Source.');
MakeSnapshot(StmName('2.5.9_SP'), $rootStream);
# 2.6
RecursiveDelete();
VSSGet("$ssPath/VisiWatch 2.6/VisiWatch 2.6/*", "$wsDir\\Source");
chdir $wsDir or die $!; # Make sure *.scc gets deleted in all directories below here during Get
VSSGet("$ssPath/VisiWatch 2.6/VisiWatch 2.6/Support/VisiWatch_26_ReleaseNotes.doc", $wsDir);
chdir "$wsDir\\Source" or die $!;
unlink glob "$wsDir\\Source\\*.log" or die $!;
unlink glob "$wsDir\\Source\\*.bak" or die $!;
unlink "$wsDir\\Source\\Visiwatch.asc" or die $!;
unlink "$wsDir\\Source\\tracetest.txt" or die $!;
CommitAll('Import VisiWatch 2.6 Source.');
MakeSnapshot(StmName('2.6_SP'), $rootStream);
# 2.6 HF001
VSSGet("$ssPath/VisiWatch 2.6/VisiWatch 2.6/HF001/*", "$wsDir\\Source");
unlink "$wsDir\\Source\\Visiwatch.exe" or die $!;
CommitAll('Import VisiWatch 2.6 HF001 Source.');
MakeSnapshot(StmName('2.6_HF001_SP'), $rootStream);
# 2.6.1
chdir $wsDir or die $!;
RecursiveDelete();
mkdir "$wsDir\\Source" or die $!;
mkdir "$wsDir\\Install" or die $!;
mkdir "$wsDir\\Install\\Script Files" or die $!;
VSSGetLabel("$ssPath/VisiWatch 2.6.x/VisiWatch 2.6.x Source/*", "$wsDir\\Source", '2.6.1'); # 10/20/2014 2:35p
VSSGetLabel("$ssPath/VisiWatch 2.6.x/*", "$wsDir\\Install\\Script Files", '2.6.1');
VSSGet("$ssPath/VisiWatch 2.6.1.ism", "$wsDir\\Install");
rename "$wsDir\\Install\\VisiWatch 2.6.1.ism", "$wsDir\\Install\\VisiWatch.ism" or die $!;
unlink glob "$wsDir\\Source\\*.bak" or die $!;
unlink "$wsDir\\Install\\Script Files\\VisiWatch_261_ReleaseNotes.pdf" or die $!;
unlink "$wsDir\\Source\\Visiwatch.asc" or die $!;
rename "$wsDir\\Source\\VisiWatch_261_ReleaseNotes.doc", "$wsDir\\VisiWatch_ReleaseNotes.doc" or die $!;
rename "$wsDir\\Source\\VisiWatch_261_ReleaseNotes.pdf", "$wsDir\\VisiWatch_ReleaseNotes.pdf" or die $!;
CommitAll('Import VisiWatch 2.6.1 Source and Install code.');
MakeSnapshot(StmName('2.6.1_SP'), $rootStream);
# 2.6.2
RecursiveDelete();
mkdir "$wsDir\\Source" or die $!;
mkdir "$wsDir\\Install" or die $!;
mkdir "$wsDir\\Install\\Script Files" or die $!;
VSSGetLabel("$ssPath/VisiWatch 2.6.x/VisiWatch 2.6.x Source/*", "$wsDir\\Source", '2.6.2'); # 02/09/2015 11:01a
VSSGetLabel("$ssPath/VisiWatch 2.6.x/*", "$wsDir\\Install\\Script Files", '2.6.2');
VSSGetLabel("$ssPath/VisiWatch 2.6.x.ism", "$wsDir\\Install", '2.6.2');
unlink "$wsDir\\Source\\Visiwatch.asc" or die $!;
unlink glob "$wsDir\\Source\\*.bak" or die $!;
rename "$wsDir\\Install\\VisiWatch 2.6.x.ism", "$wsDir\\Install\\VisiWatch.ism" or die $!;
unlink "$wsDir\\Install\\Script Files\\VisiWatch_261_ReleaseNotes.pdf" or die $!;
unlink "$wsDir\\Source\\VisiWatch_261_ReleaseNotes.doc" or die $!;
unlink "$wsDir\\Source\\VisiWatch_261_ReleaseNotes.pdf" or die $!;
rename "$wsDir\\Source\\VisiWatch_262_ReleaseNotes.doc", "$wsDir\\VisiWatch_ReleaseNotes.doc" or die $!;
rename "$wsDir\\Source\\VisiWatch_262_ReleaseNotes.pdf", "$wsDir\\VisiWatch_ReleaseNotes.pdf" or die $!;
mkdir "$wsDir\\Install\\Required_MSM_IS2014" or die $!;
VSSGetLabel("$ssPath/VisiWatch 2.6.x/Required_MSM_IS2014/*", "$wsDir\\Install\\Required_MSM_IS2014", '2.6.2');
mkdir "$wsDir\\Install\\Required_MSM_IS2014\\modules_i386" or die $!;
VSSGetLabel("$ssPath/VisiWatch 2.6.x/Required_MSM_IS2014/moudules_i386/*", "$wsDir\\Install\\Required_MSM_IS2014\\modules_i386", '2.6.2');
mkdir "$wsDir\\Third Party Software";
VSSGet("$ssPath/Third Party Software/*", "$wsDir\\Third Party Software");
CommitAll('Import VisiWatch 2.6.2 Source and Install code.');
MakeSnapshot(StmName('2.6.2_SP'), $rootStream);

sub StmName {
	return "${depot}_${prepend}_" . $_[0];
}

sub VSSGet {
	my $ssPath = $_[0];
	my $localPath = $_[1];
	system("\"$sscmd\" Get \"$ssPath\" -GL\"$localPath\" -GWR -I-Y -W");
	if ($?)
	{
		die "Failed to retrieve $ssPath";
	}
	system('del *.scc /S /Q /F');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving code for $ssPath.";
	}
	system('del *.scc /S /Q /F /AH');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving code for $ssPath.";
	}
}

sub VSSGetLabel {
	my $ssPath = $_[0];
	my $localPath = $_[1];
   my $label = $_[2];
	system("\"$sscmd\" Get \"$ssPath\" -GL\"$localPath\" -GWR -I-Y -W -Vl$label");
	if ($?)
	{
		die "Failed to retrieve $label";
	}
	system('del *.scc /S /Q /F');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving code for label $label.";
	}
	system('del *.scc /S /Q /F /AH');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving code for label $label.";
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