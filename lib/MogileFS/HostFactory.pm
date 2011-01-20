package MogileFS::HostFactory;
use strict;
use warnings;
use base 'MogileFS::MogFactory';

use MogileFS::NewHost;

sub set {
    my ($self, $args) = @_;
    my $devfactory = MogileFS::DeviceFactory->get_factory;
    return $self->SUPER::set(MogileFS::NewHost->new_from_args($args, $devfactory));
}

1;
