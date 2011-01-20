package MogileFS::NewDomain;
use strict;
use warnings;
use MogileFS::Util qw(throw);

=head1

MogileFS::NewDomain - domain class.

=cut

sub new_from_args {
    my ($class, $args, $class_factory) = @_;
    return bless {
        class_factory => $class_factory,
        %{$args},
    }, $class;
}

# Instance methods:

sub id   { $_[0]{dmid} }
sub name { $_[0]{namespace} }

sub add_to_db {
    my $self = shift;
    # Can throw 'dup'
    my $dmid = Mgd::get_store()->create_domain($self->name)
        or die "create domain didn't return a dmid";
    # Fill in the ID that we now have.
    $self->{dmid} = $dmid;
}

sub remove_from_db {
    my $self = shift;
    throw("has_files") if $self->has_files;
    # FIXME:
    # This is using the cache. Do we care?
    # Race would be: add domain, add class to domain, delete domain before
    # cache is updated.
    throw("has_classes") if $self->classes;
    my $rv = Mgd::get_store()->delete_domain($self->id);
}

sub has_files {
    my $self = shift;
    return 1 if $Mgd::_T_DOM_HAS_FILES;
    return Mgd::get_store()->domain_has_files($self->id);
}

sub classes {
    my $self = shift;
    return $self->{class_factory}->get_all($self);
}

sub class {
    my $self = shift;
    return $self->{class_factory}->get_by_name($self, $_[0]);
}

1;
