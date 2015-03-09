use IPC::Open2;
use Date::Parse;
use Date::Format;
use Data::Printer;
my $accurev = 'c:\Program Files (x86)\AccuRev\bin\accurev.exe';
my $depot = 'FSX';
my $prepend = 'INAP'; # prepended to created stream names in case multiple test imports need to be done.
my $rootStream = $prepend ? "${depot}_${prepend}" : $depot;
chdir "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}Migrate" or die 'Failed to set current directory.';

LogMsg('Starting labeling process ' . localtime());

my $SPLabels = [
	['7.50.3_SP','2011-09-26T14:08:00']
	];

my $pid = open2(\*CHLD_OUT, \*CHLD_IN, "\"$accurev\" hist -s ${depot}_${prepend} -a -fe");
my $tranNum;
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
}
waitpid $pid, 0;

for my $tx (@{$SPLabels})
{
	my $label = $tx->[0];
	my $dt = str2time($tx->[1]);
	my $lastTran = getTransNum($dt);
	my $lastTranDt = time2str("%c", $transDates{$lastTran}->[0]);
	print "$label -> $lastTran ($lastTranDt)\n";
	MakeSnapshot($label, "${depot}_${prepend}", $lastTran);
}

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
	my $newStream = "${depot}_${prepend}_" . $_[0];
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