package FusionInventory::LoggerBackend::Syslog;

use strict;
use warnings;

use Sys::Syslog qw(:standard :macros);

my %syslog_levels = (
    fault => LOG_ERR,
    error => LOG_WARNING,
    info  => LOG_INFO,
    debug => LOG_DEBUG
);

sub new {
    my ($class, $params) = @_;

    my $self = {};
    bless $self, $class;

    openlog("fusinv-agent", 'cons,pid', $params->{config}->{logfacility});

    return $self;
}

sub addMsg {
    my (undef, $args) = @_;

    my $level = $args->{level};
    my $message = $args->{message};

    syslog($syslog_levels{$level}, $message);
}

sub DESTROY {
    closelog();
}

1;
__END__

=head1 NAME

FusionInventory::LoggerBackend::Syslog - A syslog backend for the logger

=head1 DESCRIPTION

This is a syslog-based backend for the logger.

=head1 METHODS

=head2 new($params)

The constructor. The following named parameters are allowed:

=over

=item config (mandatory)

=back

=head2 addMsg($params)

Add a log message, with a specific level. The following arguments are allowed:

=over

=item level (mandatory)

Can be one of:

=over

=item debug

=item info

=item error

=item fault

=back

=item message (mandatory)

=back
