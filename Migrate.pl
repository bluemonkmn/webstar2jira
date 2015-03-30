use IPC::Open3;
use Data::Printer;
use File::Path qw(remove_tree rmtree);
my $accurev = 'c:\Program Files (x86)\AccuRev\bin\accurev.exe';
my $sscmd = 'c:\Program Files (x86)\Microsoft Visual SourceSafe\ss.exe';
my $tmp = $ENV{'TMP'};
my $depot = 'FSX';
my $prepend = 'DemandStream'; # prepended to created stream names in case multiple test imports need to be done.
my $rootStream = $prepend ? "${depot}_${prepend}" : $depot;
my $ssdb = 'C:\Users\bmarty\Downloads\DemandStream';
my $wsDir = "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}Migrate";

LogMsg('Starting migration at ' . localtime());

# 2.1
$ENV{'SSDIR'}=$ssdb;
MakeStream($rootStream, $depot);
MakeWorkspace(StmName('Migrate'), $rootStream, $wsDir);
chdir $wsDir or die $!;
VSSWorkFold('$/r2.1', $wsDir);
VSSGetLatest('$/r2.1');
remove_tree("$wsDir\\Visiwatch");
CommitAll('Import DemandStream 2.1 tree from SourceSafe.');
MakeSnapshot(StmName('2.1_SP'), $rootStream);
# 2.1a
RecursiveDelete();
VSSWorkFold('$/r2.1a', $wsDir);
VSSGetLatest('$/r2.1a');
remove_tree("$wsDir\\Visiwatch");
CommitAll('Import DemandStream 2.1a tree from SourceSafe.');
MakeSnapshot(StmName('2.1a_SP'), $rootStream);
# 2.1b
RecursiveDelete();
VSSWorkFold('$/r2.1b', $wsDir);
VSSGetLatest('$/r2.1b');
remove_tree("$wsDir\\Visiwatch");
CommitAll('Import DemandStream 2.1b tree from SourceSafe.');
MakeSnapshot(StmName('2.1b_SP'), $rootStream);
# HotfixB
MakeStream(StmName('2.1b_WorkComplete'), StmName('2.1b_SP'));
ReparentWorkspace(StmName('Migrate'), StmName('2.1b_WorkComplete'));
VSSGetTo('$/r2.1HotfixB/Hotfix 001/AlterMRM21b.sql', "$wsDir\\Source\\Scripts\\MRM");
VSSGetTo('$/r2.1HotfixB/Hotfix 001/ds_mrm.vbp', "$wsDir\\Source\\App\\Win\\MRM");
VSSGetTo('$/r2.1HotfixB/Hotfix 001/frmITEM_Import.frm', "$wsDir\\Source\\App\\Win\\MRM");
VSSGetTo('$/r2.1HotfixB/Hotfix 001/usp_ERP_MRM_VendorUpdate.sql', "$wsDir\\Source\\Scripts\\MRM");
VSSGetTo('$/r2.1HotfixB/Hotfix 001/usp_ERP_MRMLoadBillMaster.sql', "$wsDir\\Source\\Scripts\\MRM");
VSSGetTo('$/r2.1HotfixB/Hotfix 001/usp_MRMSynchronizeVendorItems.sql', "$wsDir\\Source\\Scripts\\MRM");
VSSGetTo('$/r2.1HotfixB/Hotfix 001/usp_MRMSynchronizeVendors.sql', "$wsDir\\Source\\Scripts\\MRM");
CommitAll('Import DemandStream 2.1b hotfix 1 from SourceSafe.');
VSSGetTo('$/r2.1HotfixB/Hotfix 002/frmAAM_AddBuyerActivity.frm', "$wsDir\\Source\\App\\Win\\AAM");
VSSGetTo('$/r2.1HotfixB/Hotfix 002/prjDS_AAM.vbp', "$wsDir\\Source\\App\\Win\\AAM");
CommitAll('Import DemandStream 2.1b hotfix 2 from SourceSafe.');
VSSGetTo('$/r2.1HotfixB/Hotfix 003/ds_mrm.vbp', "$wsDir\\Source\\App\\Win\\MRM");
VSSGetTo('$/r2.1HotfixB/Hotfix 003/frmITEM_Manage.frm', "$wsDir\\Source\\App\\Win\\MRM");
VSSGetTo('$/r2.1HotfixB/Hotfix 003/usp_ERP_MRMFetchBillParents.sql', "$wsDir\\Source\\Scripts\\MRM");
VSSGetTo('$/r2.1HotfixB/Hotfix 003/usp_ERP_MRMItemBillUpdate.sql', "$wsDir\\Source\\Scripts\\MRM");
CommitAll('Import DemandStream 2.1b hotfix 3 from SourceSafe.');
VSSGetTo('$/r2.1HotfixB/Hotfix 004/usp_SCEKanbanCardXMLExportRetrieve.sql', "$wsDir\\Source\\Scripts\\SCE");
CommitAll('Import DemandStream 2.1b hotfix 4 from SourceSafe.');
ReparentWorkspace(StmName('Migrate'), $rootStream);
# 2.1c
RecursiveDelete();
VSSWorkFold('$/r2.1c', $wsDir);
VSSGetLatest('$/r2.1c');
remove_tree("$wsDir\\Visiwatch");
CommitAll('Import DemandStream 2.1c tree from SourceSafe.');
MakeSnapshot(StmName('2.1c_SP'), $rootStream);
# HotfixC
MakeStream(StmName('2.1c_WorkComplete'), StmName('2.1c_SP'));
ReparentWorkspace(StmName('Migrate'), StmName('2.1c_WorkComplete'));
VSSGetTo('$/r2.1HotfixC/Hotfix 001/DS_DIM.bas', "$wsDir\\Source\\DLE");
VSSGetTo('$/r2.1HotfixC/Hotfix 001/usp_ERP_DLEGetAllocDeficientDate.sql', "$wsDir\\Source\\Scripts\\DLE");
CommitAll('Import DemandStream 2.1c hotfix from SourceSafe.');
ReparentWorkspace(StmName('Migrate'), $rootStream);
# 2.1d
RecursiveDelete();
VSSWorkFold('$/r2.1d', $wsDir);
VSSGetLatest('$/r2.1d');
remove_tree("$wsDir\\Visiwatch");
mkdir "$wsDir\\Utilities";
VSSWorkFold('$/Utilities', "$wsDir\\Utilities");
VSSGetLatest('$/Utilities');
remove_tree("$wsDir\\Utilities\\VSSPinTool");
CommitAll('Import DemandStream 2.1d tree and Utilities tree from SourceSafe.');

sub StmName {
	return "${depot}_${prepend}_" . $_[0];
}

sub VSSGetLatest {
	my $ssPath = $_[0];
	system("\"$sscmd\" Get \"$ssPath\" -R -GF -GWR -I-Y -W");
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

sub VSSWorkFold {
	my $ssPath = $_[0];
	my $localPath = $_[1];
	system("\"$sscmd\" Workfold $ssPath \"$localPath\"");
	if ($?)
	{
		die "Failed to retrieve $label";
	}
}

sub VSSGetTo {
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