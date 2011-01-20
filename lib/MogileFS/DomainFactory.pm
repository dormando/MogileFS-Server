package MogileFS::DomainFactory;
use strict;
use warnings;
use base 'MogileFS::MogFactory';

use MogileFS::NewDomain;

sub set {
    my ($self, $args) = @_;
    my $classfactory = MogileFS::ClassFactory->get_factory;
    return $self->SUPER::set(MogileFS::NewDomain->new_from_args($args, $classfactory));
}

1;
