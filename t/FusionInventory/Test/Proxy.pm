package FusionInventory::Test::Proxy;

use strict;
use warnings;
use HTTP::Proxy;
use File::Temp;

our $pid;

sub new {
    die 'An instance of Test::Proxy has already been started.' if $pid;

    my $class = shift;

    my $proxy = HTTP::Proxy->new(port => 0);
    $proxy->init();
    $proxy->agent()->no_proxy('localhost');
    $proxy->logfh(File::Temp->new());

    my $self = {
        proxy => $proxy
    };
    bless $self, $class;

    return $self;
}

# the proxy accepts an optional coderef to run after serving all requests
sub background {
    my ($self, $sub) = @_;

    $pid = fork;
    die "Unable to fork proxy" if not defined $pid;

    if ( $pid == 0 ) {
        $0 .= " (proxy)";

        # this is the http proxy
        $self->{proxy}->start();
        $sub->($self->{proxy}) if ( defined $sub and ref $sub eq 'CODE' );
        exit 0;
    }

    # back to the parent
    return $pid;
}

sub url {
    my ($self) = @_;

    return $self->{proxy}->url();
}

sub stop {
    my $signal = ($^O eq 'MSWin32') ? 9 : 15;
    if ( $pid ) {
        kill( $signal, $pid ) unless $^S;
        undef $pid;
    }

    return;
}

1;
