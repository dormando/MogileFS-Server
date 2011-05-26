package MogileFS::Factory::Domain;
use strict;
use warnings;
use base 'MogileFS::Factory';

use MogileFS::Domain;

sub set {
    my ($self, $args) = @_;
    my $classfactory = MogileFS::Factory::Class->get_factory;
    return $self->SUPER::set(MogileFS::Domain->new_from_args($args, $classfactory));
}

1;
