package Plack::App::Gearman::Status;
use parent qw(Plack::Component);

# ABSTRACT: Plack application to display the status of Gearman job servers

use strict;
use warnings;

use Carp;
use MRO::Compat;
use Net::Telnet::Gearman;
use Text::MicroTemplate;
use Plack::Util::Accessor qw(job_servers template);

=head1 SYNOPSIS

In a C<.psgi> file:

	use Plack::App::Gearman::Status;

	my $app = Plack::App::Gearman::Status->new({
		job_servers => ['127.0.0.1:4730'],
	});

As one-liner:

	plackup -MPlack::App::Gearman::Status \
		-e 'Plack::App::Gearman::Status->new({ job_servers => ["127.0.0.1:4730"] })->to_app'

=head1 DESCRIPTION

Plack::App::Gearman::Status displays the status of Gearman job servers.

=cut

chomp(my $template_string = <<'EOTPL');
<?xml version="1.0"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Gearman Server Status</title>
		<meta http-equiv="Content-Type" content="application/xhtml+xml; charset=utf-8" />
		<style type="text/css">
			html, body {
				padding: 0px;
				margin: 5px;
				background-color: #FFFFFF;
				font-family: Helvetica, Sans-Serif;
			}
			h1, h2, h3 {
				border: solid #EAEAEA 1px;
				padding: 5px;
				margin-top: inherit;
				margin-bottom: inherit;
				background-color: #FAFAFA;
				color: #777777;
			}
			h1 {
				border-radius: 10px;
				-moz-border-radius: 10px;
			}
			h2 {
				font-size: 1.25em;
				margin-top: 40px;
				border-radius: 10px 10px 0px 0px;
				-moz-border-radius: 10px 10px 0px 0px;
			}
			h3 {
				font-size: 1em;
			}
			p {
				margin: 5px;
				color: #444444;
				font-size: 0.9em;
			}
			table {
				width: 100%;
				border: 1px solid #DDDDDD;
				border-spacing: 0px;
			}
			table.status {
				border-radius: 0px 0px 10px 10px;
				-moz-border-radius: 0px 0px 10px 10px;
			}
			table th {
				border-bottom: 1px solid #DDDDDD;
				background: #FAFAFA;
				padding: 5px;
				font-size: 0.9em;
				color: #555555;
			}
			table td {
				text-align: center;
				padding: 5px;
				font-size: 0.8em;
				color: #444444;
			}
			table tr:hover {
				background: #FBFBFB;
			}
		</style>
	</head>
	<body>
		<h1>Gearman Server Status</h1>
		<% for my $job_server (@{$_[0]}) { %>
			<h2>Job server <code><%= $job_server->{job_server} %></code></h2>
			<p>Server Version: <%= $job_server->{version} %></p>

			<h3>Workers</h3>
			<table class="workers">
				<tr><th>File Descriptor</th><th>IP Address</th><th>Client ID</th><th>Function</th></tr>
				<% for my $worker (@{$job_server->{workers}}) { %>
					<tr><td><%= $worker->file_descriptor() %></td><td><%= $worker->ip_address() %></td><td><%= $worker->client_id() %></td><td><%= join(', ', sort @{$worker->functions()}) %></td></tr>
				<% } %>
			</table>

			<h3>Status</h3>
			<table class="status">
				<tr><th>Function</th><th>Total</th><th>Running</th><th>Available Workers</th><th>Queue</th></tr>
				<% for my $status (@{$job_server->{status}}) { %>
					<tr><td><%= $status->name() %></td><td><%= $status->running() %></td></td><td><%= $status->busy() %></td><td><%= $status->free() %></td><td><%= $status->queue() %></tr>
				<% } %>
			</table>
		<% } %>
	</body>
</html>
EOTPL


=head2 new

Constructor, creates new L<Plack::App::Gearman::Status|Plack::App::Gearman::Status>
instance.

=head3 Parameters

This method expects its parameters as a hash reference.

=over

=item job_servers

Array reference with the addresses of the job servers the application should
connect to.

=back

=cut

sub new {
	my ($class, @arg) = @_;

	my $self = $class->next::method(@arg);

	$self->job_servers({
		map {
			my ($host, $port) = $self->parse_job_server_address($_);
			$_ => Net::Telnet::Gearman->new(
				Host => $host,
				Port => $port,
			);
		} @{$self->{job_servers}}
	});

	$self->template(Text::MicroTemplate->new(
		template   => $template_string,
		tag_start  => '<%',
		tag_end    => '%>',
		line_start => '%',
	)->build());

	return $self;
}


=head2 parse_job_server_address

Parses a job server address of the form C<hostname:port> with optional C<port>.
If no port is given, it defaults to C<4730>.

=head3 Parameters

This method expects positional parameters.

=over

=item address

The address to parse.

=back

=head3 Result

A list with host and port.

=cut

sub parse_job_server_address {
	my ($self, $address) = @_;

	unless (defined $address) {
		croak("Required job server address parameter not passed");
	}

	$address =~ m{^
		# IPv6 address or hostname/IPv4 address
		(?:\[(?<host>[\d:]+)\]|(?<host>[\w.]+))
		# Optional port
		(?::(?<port>\d+))?
	$}xms;
	my $host = $+{host};
	my $port = $+{port} || 4730;

	unless (defined $host) {
		croak("No valid job server address '$address' passed");
	}

	return ($host, $port);
}


=head2 get_status

Fetch status information from configured Gearman job servers.

=head3 Result

An array reference with hash references containing status information.

=cut

sub get_status {
	my ($self) = @_;

	my @result;
	for my $job_server (keys %{$self->job_servers()}) {
		push @result, {
			job_server => $job_server,
			workers    => [ $self->job_servers()->{$job_server}->workers() ],
			status     => [ $self->job_servers()->{$job_server}->status() ],
			version    => $self->job_servers()->{$job_server}->version(),
		};
	}

	return \@result;
}


=head2 call

Specialized call method which retrieves the job server status information and
transforms it to HTML.

=head3 Result

A L<PSGI|PSGI> response.

=cut

sub call {
	my ($self, $env) = @_;

	return [
		200,
		[ 'Content-Type' => 'text/html; charset=utf-8' ],
		[ $self->template()->($self->get_status()) ]
	];
}


=head1 SEE ALSO

=over

=item *

L<Plack|Plack> and L<Plack::Component|Plack::Component>.

=item *

L<Net::Telnet::Gearman|Net::Telnet::Gearman> which is used to access a Gearman
job server.

=item *

C<gearman-stat.psgi> (L<https://github.com/tokuhirom/gearman-stat.psgi>) by
TOKUHIROM which inspired this application.

=back

=cut

1;

