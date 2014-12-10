use LWP::UserAgent;
use Data::Printer;
use Term::ReadKey;
use JSON;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
my $rootURL = 'http://jira.lawson.com/rest';
my $authURL = "$rootURL/auth/1";
my $apiURL = "$rootURL/api/2";
my $project = 'FS';

my %compAssigns = ();

while (<>)
{
	if (m/^([^,]*),([^,\n]*)$/)
	{
		$compAssigns{$1} = $2;
	}
}

print STDERR "User: ";
my $user = <>;
chomp $user;
print STDERR "Password: ";
ReadMode('noecho');
my $password = <>;
ReadMode(0);
chomp $password;
print STDERR "\n";

print STDERR "Retrieving project info from $apiURL/project/$project\n";
my $response = $ua->get("$apiURL/project/$project");
if (not $response->is_success) {
	die $response->status_line;
}
print STDERR "Project info retrieved.\n";

my $projectData = decode_json $response->decoded_content;

print STDERR "Project info parsed.\n";

my $request = new HTTP::Request 'PUT', "$apiURL/component";
$request->authorization_basic($user, $password);
$request->content_type('application/json');

print "ComponentId,ComponentName,Assignee,Result\n";

for my $component (@{$projectData->{components}})
{
	print STDERR 'Processing ' . $component->{id} . ' (' . $component->{name} . ").\n";
	print $component->{id} . ', ' . $component->{name} . ',';
	my $user = '';
	if (exists $compAssigns{$component->{name}})
	{
		$user = $compAssigns{$component->{name}};
		delete $compAssigns{$component->{name}};
		print "$user,";
	} else {
		print "not specified,";
	}
	if ($user)
	{
		$request->uri("$apiURL/component/" . $component->{id});
		$request->content("{\"leadUserName\":\"$user\",\"assigneeType\":\"COMPONENT_LEAD\"}");
		$response = $ua->request($request);
		if ($response->is_success)
		{
			print "success\n";
		} else {
			print STDERR $response->decoded_content . "\n";
			die $response->status_line . "\n";
		}
	} else {
		print "no change\n";
	}
}

for my $compName (keys %compAssigns)
{
	print "Not Found,$compName,,\n";
}