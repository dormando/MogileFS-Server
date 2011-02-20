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
    plan tests => 12;
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
'reachable'}, $devfac);
    ok($host, 'made a new host object');
    is($host->id, 1, 'host id is 1');
    is($host->name, 'foo', 'host name is foo');

    # Test device.
    my $dev = $devfac->set({ devid => 1, hostid => 1, status => 'alive',
weight => 100, mb_total => 5000, mb_used => 300, mb_asof => 1295217165,
observed_state => 'writeable'}, $hostfac);
    ok($dev, 'made a new dev object');
    is($dev->id, 1, 'dev id is 1');
    is($dev->host->name, 'foo', 'name of devs host is foo');
    ok($dev->can_delete_from, 'can_delete_from works');
    ok($dev->can_read_from, 'can_read_from works');
    ok($dev->should_get_new_files, 'should_get_new_files works');
}

# Might be able to skip the factory tests, as domain/class cover those.

# Add a host and two devices to the DB.

# Forget about them from the cache.

# Ensure they're gone from the cache.

# Reload from DB and confirm they match what we had before.

# Update host details to DB and ensure they stick.

# Update device details in DB and ensure they stick.
