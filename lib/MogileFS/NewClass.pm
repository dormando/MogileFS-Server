package MogileFS::NewClass;
use strict;
use warnings;
use MogileFS::Util qw(throw);

=head1

MogileFS::NewClass - Class class.

=cut

sub new_from_args {
    my ($class, $args, $domain_factory) = @_;
    return bless {
        domain_factory => $domain_factory,
        %{$args},
    }, $class;
}

# Instance methods:

sub id   { $_[0]{classid} }
sub name { $_[0]{classname} }
sub mindevcount { $_[0]{mindevcount} }

sub add_to_db {
    my $self = shift;
    # can throw 'dup'
    my $clid = Mgd::get_store()->create_class($self->{dmid}, $self->name);
    $self->{classid} = $clid;
}

sub remove_from_db {
    my $self = shift;
    throw("has_files") if $self->has_files;
    Mgd::get_store()->delete_class($self->{dmid}, $self->id);
    return 1;
}

sub repl_policy_string {
    my $self = shift;
    return $self->{replpolicy} ? $self->{replpolicy}
        : 'MultipleHosts()';
}

sub repl_policy_obj {
    my $self = shift;
    if (! $self->{_repl_policy_obj}) {
        my $polstr = $self->repl_policy_string;
        # Parses the string.
        $self->{_repl_policy_obj} =
            MogileFS::ReplicationPolicy->new_from_policy_string($polstr);
    }
    return $self->{_repl_policy_obj};
}

sub domain {
    my $self = shift;
    return $self->{domain_factory}->get_by_id($self->{dmid});
}

sub set_name {
    my ($self, $name) = @_;
    return 1 if $self->name eq $name;
    Mgd::get_store()->update_class_name(dmid      => $self->{dmid},
                                        classid   => $self->id,
                                        classname => $name);
    $self->{classname} = $name;
    return 1;
}

sub set_mindevcount {
    my ($self, $n) = @_;
    return 1 if $self->{mindevcount} == $n;
    Mgd::get_store()->update_class_mindevcount(dmid        => $self->{dmid},
                                               classid     => $self->id,
                                               mindevcount => $n);
    $self->{mindevcount} = $n;
}

sub set_replpolicy {
    my ($self, $pol) = @_;
    return 1 if $self->repl_policy_string eq $pol;
    Mgd::get_store()->update_class_replpolicy(dmid       => $self->{dmid},
                                              classid    => $self->id,
                                              replpolicy => $pol);
    $self->{replpolicy} = $pol;
    return 1;
}

sub has_files {
    my $self = shift;
    return Mgd::get_store()->class_has_files($self->{dmid}, $self->id);
}

1;
