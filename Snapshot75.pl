use IPC::Open2;
use Date::Parse;
use Date::Format;
use Data::Printer;
my $accurev = 'c:\Program Files (x86)\AccuRev\bin\accurev.exe';
my $depot = 'FS';
my $rootStream = ''; # If depot is 'FS', rootStream is 'Auto' and prepend is 'Ben', all streams will go under FS_BenAuto.
my $prepend = 'SqlImport'; # prepended to created stream names in case multiple test imports need to be done.
chdir "C:\\Users\\bmarty\\AccuRev\\${depot}_${prepend}Migrate" or die 'Failed to set current directory.';

LogMsg('Starting labeling process ' . localtime());

my $r75Labels = [
	['7.50_GA', '2008-06-30T09:26:00'],
	['7.50A_SP','2009-05-21T11:05:00'],
	['7.50B_SP','2010-02-18T13:26:00'],
	['7.50C_SP','2011-04-28T03:21:00'],
	['7.50D_SP','2012-09-26T09:07:00'],
	['7.50E_SP','2014-02-28T08:14:00']
	];

my $pid = open2(\*CHLD_OUT, \*CHLD_IN, "\"$accurev\" hist -s ${depot}_${prepend}7.50 -a -fe");
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

for my $tx (@{$r75Labels})
{
	my $label = $tx->[0];
	my $dt = str2time($tx->[1]);
	my $lastTran = getTransNum($dt);
	my $lastTranDt = time2str("%c", $transDates{$lastTran}->[0]);
	print "$label -> $lastTran ($lastTranDt)\n";
	MakeSnapshot($label, '7.50', $lastTran);
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
	my $newStream = "${depot}_${prepend}" . $_[0];
	my $basis = "${depot}_${prepend}" . $_[1];
	my $tranNum = $_[2];
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