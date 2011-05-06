# -*-perl-*-

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

use MogileFS::Server;
use MogileFS::Util qw(error_code);
use MogileFS::Test;
use MogileFS::MogFactory;
use MogileFS::HostFactory;
use MogileFS::DeviceFactory;
use MogileFS::NewHost;
use MogileFS::NewDevice;

use Data::Dumper qw/Dumper/;

my $sto = eval { temp_store(); };
if ($sto) {
    plan tests => 20;
} else {
    plan skip_all => "Can't create temporary test database: $@";
    exit 0;
}

# Fetch the factories.
my $hostfac = MogileFS::HostFactory->get_factory;
ok($hostfac, "got a host factory");
my $devfac = MogileFS::DeviceFactory->get_factory;
ok($devfac, "got a device factory");

MogileFS::Config->set_config_no_broadcast("min_free_space", 100);

# Ensure the inherited singleton is good.
ok($hostfac != $devfac, "factories are not the same singleton");

{
    # Test host.
    my $host = $hostfac->set({ hostid => 1, hostname => 'foo', hostip =>
'127.0.0.5', status => 'alive', http_port => 7500, observed_state =>
'reachable'});
    ok($host, 'made a new host object');
    is($host->id, 1, 'host id is 1');
    is($host->name, 'foo', 'host name is foo');

    # Test device.
    my $dev = $devfac->set({ devid => 1, hostid => 1, status => 'alive',
weight => 100, mb_total => 5000, mb_used => 300, mb_asof => 1295217165,
observed_state => 'writeable'});
    ok($dev, 'made a new dev object');
    is($dev->id, 1, 'dev id is 1');
    is($dev->host->name, 'foo', 'name of devs host is foo');
    ok($dev->can_delete_from, 'can_delete_from works');
    ok($dev->can_read_from, 'can_read_from works');
    ok($dev->should_get_new_files, 'should_get_new_files works');

    $hostfac->remove($host);
    $devfac->remove($dev);
}

# Might be able to skip the factory tests, as domain/class cover those.

{
    # Add a host and two devices to the DB.
    my $host = MogileFS::NewHost->new_from_args({ hostname => 'foo',
        hostip => '127.0.0.7' }, $devfac);

    is($host->add_to_db, 1, 'new host got id 1');

    # It's not possible to pass a prebuilt object into the cache, as the only
    # place which should ever update the cache should be dealing with
    # serialized objects. These tests are outside of that pattern.
    $host = $hostfac->set($host->fields);

    my $dev1 = MogileFS::NewDevice->new_from_args({ devid => 1, hostid => 1,
        status => 'alive', observed_state => 'unreachable' }, $hostfac);
    my $dev2 = MogileFS::NewDevice->new_from_args({ devid => 2, hostid => 1,
        status => 'down', observed_state => 'writeable' }, $hostfac);

    is($dev1->add_to_db, 1, 'new dev1 succeeded');
    is($dev2->add_to_db, 1, 'new dev2 succeeded');

    # Reload from DB and confirm they match what we had before.
    my @hosts = $sto->get_all_hosts;
    my @devs  = $sto->get_all_devices;

    is_deeply($hosts[0], {
            'http_get_port' => undef,
            'status' => 'down',
            'http_port' => '7500',
            'hostip' => '127.0.0.7',
            'hostname' => 'foo',
            'hostid' => '1',
            'altip' => undef,
            'altmask' => undef
    }, 'host is as expected');

    is_deeply($devs[0], {
            'mb_total' => undef,
            'mb_used' => undef,
            'status' => 'alive',
            'devid' => '1',
            'weight' => '100',
            'mb_asof' => undef,
            'hostid' => '1'
    }, 'dev1 is as expected');
    is_deeply($devs[1], {
            'mb_total' => undef,
            'mb_used' => undef,
            'status' => 'down',
            'devid' => '2',
            'weight' => '100',
            'mb_asof' => undef,
            'hostid' => '1'
    }, 'dev2 is as expected');

    # Update host details to DB and ensure they stick.


    # Update device details in DB and ensure they stick.
}
