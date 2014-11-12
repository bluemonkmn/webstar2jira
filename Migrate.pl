use IPC::Open3;
use Data::Printer;
use File::Path;
my $accurev = 'c:\Program Files (x86)\AccuRev\bin\accurev.exe';
my $sscmd = 'c:\Program Files (x86)\Microsoft Visual SourceSafe\ss.exe';
my $tmp = $ENV{'TMP'};
my $depot = 'FS';
my $prepend = ''; # prepended to created stream names in case multiple test imports need to be done.
my $rootStream = $prepend ? "${depot}_${prepend}" : $depot;
my $ssdb73 = 'C:\Users\bmarty\Downloads\R73';
my $ssdb74 = 'C:\Users\bmarty\Downloads\R74';
my $ssdb75 = 'C:\Users\bmarty\Downloads\R75';
my $wsDir = "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}Migrate";
my $ss73pin = '$/R73pin';
my $ss74pin = '$/R74pin';
my $ss73 = '$/R73';
my $ss74 = '$/R74';
my $ss75 = '$/R75';

LogMsg('Starting migration at ' . localtime());

# 7.30
$ENV{'SSDIR'}=$ssdb73;
MakeWorkspace(StmName('Migrate'), $rootStream, $wsDir);
VSSWorkFold($ss73pin, $wsDir);
chdir $wsDir or die $!;
VSSGet($ss73pin,'7.30');
CommitAll('Import FS Label 7.30');
MakeSnapshot(StmName('7.30_GA'), $rootStream);
MakeStream(StmName('7.30'), StmName('7.30_GA'));
ReparentWorkspace(StmName('Migrate'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin,'7.30A');
CommitAll('Import FS Label 7.30A');
MakeSnapshot(StmName('7.30A_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30B');
CommitAll('Import FS Label 7.30B');
MakeSnapshot(StmName('7.30B_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30C');
CommitAll('Import FS Label 7.30C');
MakeSnapshot(StmName('7.30C_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30D');
CommitAll('Import FS Label 7.30D');
MakeSnapshot(StmName('7.30D_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30E');
CommitAll('Import FS Label 7.30E');
MakeSnapshot(StmName('7.30E_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30F');
CommitAll('Import FS Label 7.30F');
MakeSnapshot(StmName('7.30F_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30G');
CommitAll('Import FS Label 7.30G');
MakeSnapshot(StmName('7.30G_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30H');
CommitAll('Import FS Label 7.30H');
MakeSnapshot(StmName('7.30H_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30I');
CommitAll('Import FS Label 7.30I');
MakeSnapshot(StmName('7.30I_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30J');
CommitAll('Import FS Label 7.30J');
MakeSnapshot(StmName('7.30J_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, '7.30K');
CommitAll('Import FS Label 7.30K');
MakeSnapshot(StmName('7.30K_SP'), StmName('7.30'));
RecursiveDelete();
VSSGet($ss73pin, 'R7.30L');
CommitAll('Import FS Label R7.30L');
MakeSnapshot(StmName('7.30L_SP'), StmName('7.30'));
RecursiveDelete();
VSSWorkFold($ss73, $wsDir);
VSSGetLatest($ss73);
CommitAll('Import latest FS 7.30 code after 7.30L release.');
MakeStream(StmName('7.30_WorkComplete'), StmName('7.30'));
# 7.40
ReparentWorkspace(StmName('Migrate'), $rootStream);
$ENV{'SSDIR'}=$ssdb74;
VSSWorkFold($ss74pin, $wsDir);
RecursiveDelete();
VSSGet($ss74pin, '7.40');
CommitAll('Import FS Label 7.40');
MakeSnapshot(StmName('7.40_GA'), $rootStream);
MakeStream(StmName('7.40'), StmName('7.40_GA'));
ReparentWorkspace(StmName('Migrate'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40A');
CommitAll('Import FS Label 7.40A');
MakeSnapshot(StmName('7.40A_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40B');
CommitAll('Import FS Label 7.40B');
MakeSnapshot(StmName('7.40B_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40C');
CommitAll('Import FS Label 7.40C');
MakeSnapshot(StmName('7.40C_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40D');
CommitAll('Import FS Label 7.40D');
MakeSnapshot(StmName('7.40D_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40E');
CommitAll('Import FS Label 7.40E');
MakeSnapshot(StmName('7.40E_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40F');
CommitAll('Import FS Label 7.40F');
MakeSnapshot(StmName('7.40F_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40G');
CommitAll('Import FS Label 7.40G');
MakeSnapshot(StmName('7.40G_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40H');
CommitAll('Import FS Label 7.40H');
MakeSnapshot(StmName('7.40H_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40I');
CommitAll('Import FS Label 7.40I');
MakeSnapshot(StmName('7.40I_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40J');
CommitAll('Import FS Label 7.40J');
MakeSnapshot(StmName('7.40J_SP'), StmName('7.40'));
RecursiveDelete();
VSSGet($ss74pin, '7.40K');
CommitAll('Import FS Label 7.40K');
MakeSnapshot(StmName('7.40K_SP'), StmName('7.40'));
RecursiveDelete();
VSSWorkFold($ss74, $wsDir);
VSSGetLatest($ss74);
CommitAll('Import latest FS 7.40 code after 7.40K release.');
MakeStream(StmName('7.40_WorkComplete'), StmName('7.40'));
# 7.50
MakeStream(StmName('7.50'), $rootStream);
print STDERR "Please make sure the AccuRev workspace is clean, the press Enter.\n";
<STDIN>;
ReparentWorkspace(StmName('Migrate'), StmName('7.50'));
print STDERR "Please, again, make sure the AccuRev workspace is clean, the press Enter.\n";
<STDIN>;
$ENV{'SSDIR'}=$ssdb75;
VSSWorkFold($ss75, $wsDir);
RecursiveDelete();
VSSGetByDate($ss75, '7-23-2006');
CommitAll('Import initial FS 7.50 source tree state as of 7-23-2006.');

sub StmName {
	return "${depot}_${prepend}" . $_[0];
}

sub VSSGet {
	my $ssPath = $_[0];
	my $label = $_[1];
	print STDERR "From $ssPath retrieve label $label, then press enter to continue.\n";
	<STDIN>;
	#system("\"$sscmd\" Get \"$ssPath\" -R -GF -GWR -I-Y -W -Vl$label");
	#if ($?)
	#{
	#	die "Failed to retrieve $label";
	#}
	print STDERR "Proceeding with $label...\n";
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
	print STDERR "From $ssPath retrieve the latest code, then press enter to continue.\n";
	<STDIN>;
	#system("\"$sscmd\" Get \"$ssPath\" -R -GF -GWR -I-Y -W");
	#if ($?)
	#{
	#	die "Failed to retrieve latest code.";
	#}
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
	system("\"$sscmd\" Workfold $ssPath \"$localPath\"");
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