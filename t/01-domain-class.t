# -*-perl-*-

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use MogileFS::Server;
use MogileFS::Util qw(error_code);
use MogileFS::Test;
use MogileFS::MogFactory;
use MogileFS::DomainFactory;
use MogileFS::ClassFactory;
use MogileFS::NewDomain;
use MogileFS::NewClass;

use Data::Dumper qw/Dumper/;

my $sto = eval { temp_store(); };
if ($sto) {
    plan tests => 30;
} else {
    plan skip_all => "Can't create temporary test database: $@";
    exit 0;
}

# Fetch the factories.
my $domfac = MogileFS::DomainFactory->get_factory;
ok($domfac, "got a domain factory");
my $classfac = MogileFS::ClassFactory->get_factory;
ok($classfac, "got a class factory");

# Ensure the inherited singleton is good.
ok($domfac != $classfac, "factories are not the same singleton");

{
    # Add in a test domain.
    my $dom = $domfac->set({ dmid => 1, namespace => 'toast'});
    ok($dom, "made a new domain object");
    is($dom->id, 1, "domain id is 1");
    is($dom->name, 'toast', 'domain namespace is toast');

    # Add in a test class.
    my $cls = $classfac->set($dom, { classid => 1, dmid => 1, mindevcount => 3,
        replpolicy => '', classname => 'fried'});
    ok($cls, "got a class object");
    is($cls->id, 1, "class id is 1");
    is($cls->name, 'fried', 'class name is fried');
    is(ref($cls->domain), 'MogileFS::NewDomain',
        'class can find a domain object');
}

# Add a few more classes and domains.
{
    my $dom2 = $domfac->set({ dmid => 2, namespace => 'harro' });
    $classfac->set($dom2, { classid => 1, dmid => 2, mindevcount => 2,
        replpolicy => '', classname => 'red' });
    $classfac->set($dom2, { classid => 2, dmid => 2, mindevcount => 3,
        replpolicy => 'MultipleHosts(2)', classname => 'green' });
    $classfac->set($dom2, { classid => 3, dmid => 2, mindevcount => 4,
        replpolicy => 'MultipleHosts(5)', classname => 'blue' });
}

# Ensure the select and remove factory methods work.
{
    my $dom = $domfac->get_by_id(1);
    is($dom->name, 'toast', 'got the right domain from get_by_id');
}

{
    my $dom = $domfac->get_by_name('harro');
    is($dom->id, 2, 'got the right domain from get_by_name');
}

{
    my @doms = $domfac->get_all;
    is(scalar(@doms), 2, 'got two domains back from get_all');
    for (@doms) {
        is(ref($_), 'MogileFS::NewDomain', 'and both are domains');
    }
    isnt($doms[0]->id, $doms[1]->id, 'and both are not the same');
}

{
    my $dom    = $domfac->get_by_name('harro');
    my $clsmap = $classfac->map_by_id($dom);
    is(ref($clsmap), 'HASH', 'got a mapped class hash');
    is($clsmap->{2}->name, 'green', 'got the right class set');

    $classfac->remove($clsmap->{2});

    my $cls = $classfac->get_by_name($dom, 'green');
    ok(!$cls, "class removed from factory");
}

# Test the domain routines harder.
{
    my $dom = $domfac->get_by_name('harro');
    my @classes = $dom->classes;
    is(scalar(@classes), 2, 'found two classes');

    ok($dom->class('blue'), 'found the blue class');
    ok(!$dom->class('fried'), 'did not find the fried class');
}

# Test the class routines harder.
{
    my $dom = $domfac->get_by_name('harro');
    my $cls = $dom->class('blue');
    my $polobj = $cls->repl_policy_obj;
    ok($polobj, 'class can create policy object');
}

# Add a domain and two classes to the DB.
{
    my $dom = MogileFS::NewDomain->new_from_args({namespace => 'foo'}, $classfac);
    ok(!$dom->id, 'new domain has no id');
    ok($dom->add_to_db, 'added domain to db store');
    ok($dom->id, 'new domain now has an id: ' . $dom->id);

    my $cls1 = MogileFS::NewClass->new_from_args({ classid => 1, dmid => $dom->id,
        mindevcount => 2, replpolicy => '', classname => 'bar' }, $domfac);
    my $cls2 = MogileFS::NewClass->new_from_args({ classid => 2, dmid => $dom->id,
        mindevcount => 3, replpolicy => 'MultipleHosts(6)',
        classname => 'baz' }, $domfac);
    is($cls1->name, 'bar', 'class1 is named bar');
    ok($cls1->add_to_db, 'added class bar to db');
    ok($cls2->add_to_db, 'added class baz to db');

    # TODO: Test double adding domains and classes.
}

# Forget about them from the cache.

# Ensure they're gone from the cache.

# Reload from the DB and confirm they came back the way they went in.

# Update a class name, mindevcount, replpolicy.
