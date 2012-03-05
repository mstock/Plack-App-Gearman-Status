package Plack::App::Gearman::Status;
use parent qw(Plack::Component);

# ABSTRACT: Plack application to display the status of Gearman job servers

use strict;
use warnings;

use Carp;


=head1 SYNOPSIS

	use Plack::App::Gearman::Status;

	my $app = Plack::App::Gearman::Status->new(
		job_servers => ['127.0.0.1:4730']
	);

=head1 DESCRIPTION

Plack::App::Gearman::Status displays the status of Gearman job servers.

=cut

1;

