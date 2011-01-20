package MogileFS::DeviceFactory;
use strict;
use warnings;
use base 'MogileFS::MogFactory';

use MogileFS::NewDevice;

sub set {
    my ($self, $args) = @_;
    my $hostfactory = MogileFS::HostFactory->get_factory;
    return $self->SUPER::set(MogileFS::NewDevice->new_from_args($args, $hostfactory));
}

1;
