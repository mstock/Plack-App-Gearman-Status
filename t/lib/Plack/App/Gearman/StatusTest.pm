package Plack::App::Gearman::StatusTest;
use parent qw(Test::Class);

use strict;
use warnings;

use Carp;
use Test::More;
use Test::Exception;

use Plack::App::Gearman::Status;

sub new_test: Test(1) {
	my ($self) = @_;

	my $app = Plack::App::Gearman::Status->new();
	isa_ok($app, 'Plack::App::Gearman::Status', 'instance created');
}

1;
