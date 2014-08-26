use IPC::Open3;
use Data::Printer;
use File::Path;
my $accurev = 'c:\Program Files (x86)\AccuRev\bin\accurev.exe';
my $sscmd = 'c:\Program Files (x86)\Microsoft Visual SourceSafe\ss.exe';
my $tmp = $ENV{'TMP'};
my $depot = 'FS1';
my $rootStream = 'Auto';
my $prepend = 'Sql'; # prepended to created stream names in case multiple test imports need to be done
my $ssdb73 = 'C:\Users\bmarty\Downloads\R73';
my $ws73 = "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}7.30";
my $ss73 = '$/R73pin/Src/Sql';
my $ssdb74 = 'C:\Users\bmarty\Downloads\R74';
my $ws74 = "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}7.40";
my $ss74 = '$/R74pin/Src/Sql';
my $ssdb75 = 'C:\Users\bmarty\Downloads\R75';
my $ws75 = "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}7.50";
my $ss75 = '$/R75/Src/Sql';

$ENV{'SSDIR'}=$ssdb73;

LogMsg('Starting migration at ' . localtime());

MakeWorkspace('7.30', $rootStream, $ws73);
VSSWorkFold($ss73, $ws73);
chdir $ws73 or die $!;
VSSGet($ss73,'7.30');
CommitAll('Import FS Label 7.30');
MakeSnapshot('7.30_GA', $rootStream);
MakeStream('7.30', '7.30_GA');
ReparentWorkspace('7.30', '7.30');
RecursiveDelete();
VSSGet($ss73,'7.30A');
CommitAll('Import FS Label 7.30A');
MakeSnapshot('7.30A_SP', '7.30');
MakeStream('7.40', '7.30A_SP');
MakeWorkspace('7.40', '7.40', $ws74);
$ENV{'SSDIR'}=$ssdb74;
VSSWorkFold($ss74, $ws74);
chdir $ws74 or die $!;
RecursiveDelete();
VSSGet($ss74, '7.40');
CommitAll('Import FS Label 7.40');
MakeSnapshot('7.40_GA', '7.40');
$ENV{'SSDIR'}=$ssdb73;
chdir $ws73 or die $!;
RecursiveDelete();
VSSGet($ss73, '7.30B');
CommitAll('Import FS Label 7.30B');
MakeSnapshot('7.30B_SP', '7.30');
RecursiveDelete();
VSSGet($ss73, '7.30C');
CommitAll('Import FS Label 7.30C');
MakeSnapshot('7.30C_SP', '7.30');
RecursiveDelete();
VSSGet($ss73, '7.30D');
CommitAll('Import FS Label 7.30D');
MakeSnapshot('7.30D_SP', '7.30');
RecursiveDelete();
VSSGet($ss73, '7.30E');
CommitAll('Import FS Label 7.30E');
MakeSnapshot('7.30E_SP', '7.30');
RecursiveDelete();
VSSGet($ss73, '7.30F');
CommitAll('Import FS Label 7.30F');
MakeSnapshot('7.30F_SP', '7.30');
RecursiveDelete();
VSSGet($ss73, '7.30G');
CommitAll('Import FS Label 7.30G');
MakeSnapshot('7.30G_SP', '7.30');
$ENV{'SSDIR'}=$ssdb74;
chdir $ws74 or die $!;
RecursiveDelete();
VSSGet($ss74, '7.40A');
CommitAll('Import FS Label 7.40A');
MakeSnapshot('7.40A_SP', '7.40');
RecursiveDelete();
VSSGet($ss74, '7.40B');
CommitAll('Import FS Label 7.40B');
MakeSnapshot('7.40B_SP', '7.40');
MakeStream('7.50', '7.40B_SP');
MakeWorkspace('7.50', '7.50', $ws75);
$ENV{'SSDIR'}=$ssdb75;
VSSWorkFold($ss75, $ws75);
chdir $ws75 or die $!;
RecursiveDelete();
VSSGetByDate($ss75, '7-23-2006');
CommitAll('Import initial FS 7.50 source tree state as of 7-23-2006.');
MakeSnapshot('7.50_Not_GA', '7.50');
$ENV{'SSDIR'}=$ssdb73;
chdir $ws73 or die $!;
RecursiveDelete();
VSSGet($ss73, '7.30H');
CommitAll('Import FS Label 7.30H');
MakeSnapshot('7.30H_SP', '7.30');
$ENV{'SSDIR'}=$ssdb74;
chdir $ws74 or die $!;
RecursiveDelete();
VSSGet($ss74, '7.40C');
CommitAll('Import FS Label 7.40C');
MakeSnapshot('7.40C_SP', '7.40');
RecursiveDelete();
VSSGet($ss74, '7.40D');
CommitAll('Import FS Label 7.40D');
MakeSnapshot('7.40D_SP', '7.40');
$ENV{'SSDIR'}=$ssdb73;
chdir $ws73 or die $!;
RecursiveDelete();
VSSGet($ss73, '7.30I');
CommitAll('Import FS Label 7.30I');
MakeSnapshot('7.30I_SP', '7.30');
$ENV{'SSDIR'}=$ssdb74;
chdir $ws74 or die $!;
RecursiveDelete();
VSSGet($ss74, '7.40E');
CommitAll('Import FS Label 7.40E');
MakeSnapshot('7.40E_SP', '7.40');
$ENV{'SSDIR'}=$ssdb73;
chdir $ws73 or die $!;
RecursiveDelete();
VSSGet($ss73, '7.30J');
CommitAll('Import FS Label 7.30J');
MakeSnapshot('7.30J_SP', '7.30');
$ENV{'SSDIR'}=$ssdb74;
chdir $ws74 or die $!;
RecursiveDelete();
VSSGet($ss74, '7.40F');
CommitAll('Import FS Label 7.40F');
MakeSnapshot('7.40F_SP', '7.40');
$ENV{'SSDIR'}=$ssdb73;
chdir $ws73 or die $!;
RecursiveDelete();
VSSGet($ss73, '7.30K');
CommitAll('Import FS Label 7.30K');
MakeSnapshot('7.30K_SP', '7.30');
$ENV{'SSDIR'}=$ssdb74;
chdir $ws74 or die $!;
RecursiveDelete();
VSSGet($ss74, '7.40G');
CommitAll('Import FS Label 7.40G');
MakeSnapshot('7.40G_SP', '7.40');
RecursiveDelete();
VSSGet($ss74, '7.40H');
CommitAll('Import FS Label 7.40H');
MakeSnapshot('7.40H_SP', '7.40');
RecursiveDelete();
VSSGet($ss74, '7.40I');
CommitAll('Import FS Label 7.40I');
MakeSnapshot('7.40I_SP', '7.40');
$ENV{'SSDIR'}=$ssdb73;
chdir $ws73 or die $!;
RecursiveDelete();
VSSGet($ss73, '7.30L');
CommitAll('Import FS Label 7.30L');
MakeSnapshot('7.30L_SP', '7.30');
$ENV{'SSDIR'}=$ssdb74;
chdir $ws74 or die $!;
RecursiveDelete();
VSSGet($ss74, '7.40J');
CommitAll('Import FS Label 7.40J');
MakeSnapshot('7.40J_SP', '7.40');
RecursiveDelete();
VSSGet($ss74, '7.40K');
CommitAll('Import FS Label 7.40K');
MakeSnapshot('7.40K_SP', '7.40');
$ENV{'SSDIR'}=$ssdb73;
chdir $ws73 or die $!;
RecursiveDelete();
VSSGetLatest($ss73);
CommitAll('Import latest FS 7.30 code after 7.30L release.');
$ENV{'SSDIR'}=$ssdb74;
chdir $ws74 or die $!;
RecursiveDelete();
VSSGetLatest($ss74);
CommitAll('Import latest FS 7.40 code after 7.40K release.');

sub VSSGet {
	my $ssPath = $_[0];
	my $label = $_[1];
	system("\"$sscmd\" Get \"$ssPath\" -R -GF -GWR -I-Y -W -Vl$label 2>&1");
	if ($?)
	{
		die "Failed to retrieve $label";
	}
	system('del *.scc /S /Q /F');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving code for label $label.";
	}
}

sub VSSGetByDate {
	my $ssPath = $_[0];
	my $date = $_[1];
	system("\"$sscmd\" Get \"$ssPath\" -R -GF -GWR -I-Y -W -Vd$date 2>&1");
	if ($?)
	{
		die "Failed to retrieve ss code by date for $date.";
	}
	system('del *.scc /S /Q /F');
	if ($?)
	{
		die "Failed to clean up *.scc files after retrieving code for date $date.";
	}
}

sub VSSGetLatest {
	my $ssPath = $_[0];
	system("\"$sscmd\" Get \"$ssPath\" -R -GF -GWR -I-Y -W 2>&1");
	if ($?)
	{
		die "Failed to retrieve latest code.";
	}
	system('del *.scc /S /Q /F');
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
	my $newStream = "${depot}_${prepend}" . $_[0];
	my $basis = "${depot}_${prepend}" . $_[1];
	AccuRev("mkstream -s $newStream -b $basis", "Create stream $newStream under $basis.");
}

sub MakeSnapshot {
	my $newStream = "${depot}_${prepend}" . $_[0];
	my $basis = "${depot}_${prepend}" . $_[1];
	AccuRev("mksnap -s $newStream -b $basis -t now", "Create stream $newStream under $basis.");
}

sub MakeWorkspace {
	my $wsName = "${depot}_${prepend}" . $_[0];
	my $basis = "${depot}_${prepend}" . $_[1];
	my $location = $_[2];
	AccuRev("mkws -w $wsName -b $basis -l $location", "Create workspace $wsName under $basis at $location.");
	AccuRev('update');
}

sub ReparentWorkspace {
	my $wsName = "${depot}_${prepend}" . $_[0];
	my $basis = "${depot}_${prepend}" . $_[1];
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