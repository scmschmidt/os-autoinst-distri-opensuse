# SUSE's openQA tests
#
# Copyright © 2012-2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Package: iproute2
# Summary: Check that an interface is configured and show some network info
# - check from logs that an interface is already configured, if NETWORK_INIT_PARAM is set
# - get some info using 'ip addr'
# Maintainer: Zaoliang Luo <zluo@suse.de>

use base "consoletest";
use testapi;
use Utils::Backends;
use strict;
use warnings;

sub run {
    # let's see how it looks at the beginning
    save_screenshot;
    is_ipmi ? use_ssh_serial_console : select_console 'root-console';

    # https://fate.suse.com/320347 https://bugzilla.suse.com/show_bug.cgi?id=988157
    if (check_var('NETWORK_INIT_PARAM', 'ifcfg=eth0=dhcp')) {
        # grep all also compressed files e.g. y2log-1.gz
        assert_script_run 'less /var/log/YaST2/y2log*|grep "Automatic DHCP configuration not started - an interface is already configured"';
    }
    # check the network configuration
    script_run "ip addr show";
    script_run "cat /etc/resolv.conf";
}

1;
