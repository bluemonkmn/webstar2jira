use LWP::UserAgent;
use Data::Printer;
use Term::ReadKey;
use JSON;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
my $rootURL = 'http://jiratst.lawson.com/rest';
my $authURL = "$rootURL/auth/1";
my $apiURL = "$rootURL/api/2";
my $project = 'FS';

print "User: ";
my $user = <>;
chomp $user;
print "Password: ";
ReadMode('noecho');
my $password = <>;
ReadMode(0);
chomp $password;
print "\n";

my $response = $ua->get("$apiURL/project/$project");
if (not $response->is_success) {
	die $response->status_line;
}
my $projectData = decode_json $response->decoded_content;

my $request = new HTTP::Request 'PUT', "$apiURL/component";
$request->authorization_basic($user, $password);
$request->content_type('application/json');

for my $component (@{$projectData->{components}})
{
	p $component;
	print $component->{id} . ': ' . $component->{name} . "\n";
	my $user = '';
	if ($component->{name} =~ m/^SYSM_/)
	{
		$user = "ydeng";
	}
	if ($user)
	{
		$request->uri("$apiURL/component/" . $component->{id});
		$request->content("{\"leadUserName\":\"$user\",\"assigneeType\":\"COMPONENT_LEAD\"}");
		$response = $ua->request($request);
		if ($response->is_success)
		{
			print $component->{name} . "->$user\n";
		} else {
			print STDERR $response->decoded_content . "\n";
			die $response->status_line . "\n";
		}	
	} else {
		print $component->{name} . " no change\n";
	}
}
