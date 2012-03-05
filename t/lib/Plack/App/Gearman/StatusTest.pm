package Plack::App::Gearman::StatusTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;
use Test::TCP;
use IO::Socket::INET;

use Plack::App::Gearman::Status;

sub new_test: Test(1) {
	my ($self) = @_;

	my $app = Plack::App::Gearman::Status->new();
	isa_ok($app, 'Plack::App::Gearman::Status', 'instance created');
}

sub get_status_test : Test(1) {
	my ($self) = @_;

	test_tcp(
		client => sub {
			my ($port) = @_;

			my $app = Plack::App::Gearman::Status->new({
				job_servers => ['127.0.0.1:'.$port],
			});
			is_deeply($app->get_status(), [{
				job_server => '127.0.0.1:10001',
				version    => '0.13',
				status     => [{
					busy    => 2,
					free    => 1,
					name    => 'add',
					queue   => 1,
					running => 3
				}],
				workers    => [{
					client_id       => '-',
					file_descriptor => 8432,
					functions       => [ 'job' ],
					ip_address      => '192.168.0.1'
				}]
			}], 'status ok');
		},
		server => sub {
			my ($port) = @_;
			$self->mock_gearman($port);
		}
	);
}


sub mock_gearman {
	my ($self, $port) = @_;

	my $sock = IO::Socket::INET->new(
		Listen    => 5,
		LocalAddr => 'localhost',
		LocalPort => $port,
		Proto     => 'tcp',
		ReuseAddr => 1,
	);
	while (my $res = $sock->accept()) {
		while (my $line = $res->getline()) {
			if (index($line, 'workers') == 0) {
				$res->print("8432 192.168.0.1 - : job\n.\n");
			}
			elsif (index($line, 'status') == 0) {
				$res->print("add 1       2       3\n.\n");
			}
			elsif (index($line, 'version') == 0) {
				$res->print("0.13\n");
			}
		}
	}
}

1;
