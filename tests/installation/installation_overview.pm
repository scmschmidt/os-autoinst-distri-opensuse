# SUSE's openQA tests
#
# Copyright © 2009-2013 Bernhard M. Wiedemann
# Copyright © 2012-2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Summary: Check installation overview before and after any pattern change
# - Check if install scenario has proposals
# - Check if xen pattern is going to be installed if XEN is defined
# - Unblock sshd
# - Disable firewall if DISABLE_FIREWALL is set
# - Check system target
# Maintainer: Richard Brown <RBrownCCB@opensuse.org>

use base 'y2_installbase';
use strict;
use warnings;
use testapi;
use version_utils qw(is_microos is_sle_micro is_upgrade);
use Utils::Backends qw(is_remote_backend is_hyperv);
use Test::Assert ':all';

sub ensure_ssh_unblocked {
    if (!get_var('UPGRADE') && is_remote_backend) {

        send_key_until_needlematch [qw(ssh-blocked ssh-open)], 'tab', 25;
        if (match_has_tag 'ssh-blocked') {
            if (check_var('VIDEOMODE', 'text')) {
                send_key 'alt-c';
                assert_screen 'inst-overview-options';
                send_key 'alt-e';
                send_key 'alt-f';
                assert_screen 'firewall-config';
                send_key 'alt-p';
                send_key 'alt-o';
            }
            else {
                send_key_until_needlematch 'ssh-blocked-selected', 'tab', 25;
                send_key 'ret';
                send_key_until_needlematch 'ssh-open', 'tab';
            }
        }
        #performance ci need disable firewall
        if (get_var('DISABLE_FIREWALL')) {
            send_key_until_needlematch [qw(firewall-enable firewall-disable)], 'tab';
            if (match_has_tag 'firewall-enable') {
                send_key 'alt-c';
                assert_screen 'inst-overview-options';
                send_key 'alt-e';
                send_key 'alt-f';
                assert_screen 'firewall-config';
                send_key 'alt-e';
                assert_screen 'firewall-config-dis';
                send_key 'alt-o';
                assert_screen 'back_to_installation_settings';
            }
        }
    }
}

sub check_default_target {
    # Check the systemd target where scenario make it possible
    return if (is_microos || is_sle_micro || is_upgrade || is_hyperv ||
        get_var('REMOTE_CONTROLLER') || (get_var('BACKEND', '') =~ /spvm|pvm_hmc|ipmi/));
    # exclude non-desktop environment and scenarios with edition of package selection (bsc#1167736)
    return if (!get_var('DESKTOP') || get_var('PATTERNS'));
    return if (get_var 'BSC1167736');

    # Set expectations
    my $expected_target = check_var('DESKTOP', 'textmode') ? "multi-user" : "graphical";

    select_console 'install-shell';

    my $target_search = 'default target has been set';
    # default.target is not yet linked, so we parse logs and assert expectations
    if (my $log_line = script_output("grep '$target_search' /var/log/YaST2/y2log | tail -1",
            proceed_on_failure => 1)) {
        $log_line =~ /$target_search: (?<current_target>.*)/;
        assert_equals($expected_target, $+{current_target}, "Mismatch in default.target");
    }

    select_console 'installation';
}

sub run {
    my ($self) = shift;
    # overview-generation
    # this is almost impossible to check for real
    if (is_microos && check_var('HDDSIZEGB', '10')) {
        # boo#1099762
        assert_screen('installation-settings-overview-loaded-impossible-proposal');
    }
    else {
        # Refer to: https://progress.opensuse.org/issues/47369
        assert_screen "installation-settings-overview-loaded", 420;
        if (get_var('XEN')) {
            if (!check_screen('inst-xen-pattern')) {
                assert_and_click 'installation-settings-overview-loaded-scrollbar-up';
                assert_screen 'inst-xen-pattern';
            }
        }
        ensure_ssh_unblocked;
        check_default_target;
    }
}

1;
