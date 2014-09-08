use IPC::Open2;
use Date::Parse;
use Date::Format;
use Data::Printer;
my $accurev = 'c:\Program Files (x86)\AccuRev\bin\accurev.exe';
my $depot = 'FS';
my $prepend = ''; # prepended to created stream names in case multiple test imports need to be done.
my $rootStream = $prepend ? "${depot}_${prepend}" : $depot;
chdir "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}Migrate" or die 'Failed to set current directory.';

LogMsg('Starting labeling process ' . localtime());

my $r75GALabel = ['7.50_GA', '2008-06-30T09:26:00'];
my $r75SPLabels = [
	['7.50A_SP','2009-05-21T11:05:00'],
	['7.50B_SP','2010-02-18T13:26:00'],
	['7.50C_SP','2011-04-28T03:21:00'],
	['7.50D_SP','2012-09-26T09:07:00'],
	['7.50E_SP','2014-02-28T08:14:00']
	];

my $pid = open2(\*CHLD_OUT, \*CHLD_IN, "\"$accurev\" hist -s ${depot}_${prepend}7.50 -a -fe");
my $tranNum;
my $initialTran = 0;
my %transDates =(); # key=AccuRev transaction number; value=array of dates of SS transactions included.
while(<CHLD_OUT>)
{
	if (m/^transaction (\d+);/)
	{
		$tranNum = $1;
	}
	if (m/^  # SS \N+Time: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})/)
	{
		my $dt = str2time($1);
		if ($transDates{$tranNum})
		{
			push $transDates{$tranNum}, $dt;
		} else {
			$transDates{$tranNum} = [$dt];
		}
	}
	if (m/^  # Import initial FS 7\.50 source/)
	{
		$initialTran = $tranNum;
	}
}
waitpid $pid, 0;

for my $tx (@{$r75SPLabels})
{
	my $label = $tx->[0];
	my $dt = str2time($tx->[1]);
	my $lastTran = getTransNum($dt);
	my $lastTranDt = time2str("%c", $transDates{$lastTran}->[0]);
	print "$label -> $lastTran ($lastTranDt)\n";
	MakeSnapshot($label, "${depot}_${prepend}7.50", $lastTran);
}

if ($initialTran)
{
	print "Include initial import of 7.50 tree from #$initialTran.\n";
} else {
	die "Did not find initial transaction.";
}

my $gaDate = str2time($r75GALabel->[1]);
my @promoteTxns = ($initialTran);
foreach my $key (keys %transDates)
{
	my $lastDate = 0;
	foreach my $dt (@{$transDates{$key}})
	{
		if ($dt > $lastDate)
		{
			$lastDate = $dt;
		}
	}
	if ($lastDate <= $gaDate)
	{
		push @promoteTxns, $key;
	}
}

@promoteTxns = sort(@promoteTxns);

my $xmlTranList = join("\n", map {"<id>$_</id>"} @promoteTxns);

$xmlTranList = <<"~";
<?xml version="1.0" encoding="UTF-8"?>
<transactions>
$xmlTranList
</transactions>
~

my $tranFile = $ENV{'temp'} . '\\Snapshot75.xml';

open (my $fh, '>', $tranFile) or die "Failed to open $tranFile for writing: $!";
print $fh $xmlTranList;
close $fh;

my $promoteCmd = "promote -Fx -c \"Promote 7.50 GA code as of " . time2str("%c", $gaDate) . " from ${depot}_${prepend}7.50 to ${rootStream}\" -s ${depot}_${prepend}7.50 -S ${rootStream} -l $tranFile";
print "$promoteCmd\nWith xml:\n$xmlTranList\n";
AccuRev($promoteCmd);
unlink $tranFile or warn "Failed to clean up $tranFile: $!";

MakeSnapshot($r75GALabel->[0], $rootStream, 'now');

sub getTransNum {
	my $latestTranDate = 0;
	my $latestTranNum;
	my $targetDate = $_[0];
	foreach my $key (keys %transDates)
	{
		foreach my $dt (@{$transDates{$key}})
		{
			if ($dt > $latestTranDate and $dt <= $targetDate)
			{
				$latestTranNum = $key;
				$latestTranDate = $dt;
			}
		}
	}
	return $latestTranNum;
}

sub MakeSnapshot {
	my $newStream = "${depot}_${prepend}" . $_[0];
	my $basis = $_[1];
	my $tranNum = $_[2];
	die "Failed to specify snapshot timestamp." if (not $tranNum);
	LogMsg("Create snapshot $newStream under $basis.");
	AccuRev("mksnap -s $newStream -b $basis -t $tranNum");
}

sub LogMsg {
	my $msg = $_[0];
	print "$msg\n";
}

sub AccuRev {
	my $cmd = $_[0];
	my $cmdLine = "\"$accurev\" $cmd";
	LogMsg $cmdLine;
	system($cmdLine);
	if ($?)
	{
		die "AccuRev command failed.";
	}
}