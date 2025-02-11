# Copyright (C) 2017-2019 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, see <http://www.gnu.org/licenses/>.
#
# Package: tigervnc dhcp-client
# Summary: Remote Login: Persistent VNC Session with tigervnc and xvnc
# Maintainer: Grace Wang <grace.wang@suse.com>
# Tags: tc#1586209

use strict;
use warnings;
use base 'basetest';
use testapi;
use lockapi;
use utils;
use x11utils 'handle_login';

sub start_vncviewer {
    x11_start_program('vncviewer 10.0.2.1:1 -Fullscreen', target_match => [qw(displaymanager vncmanager-greeter vnc_certificate_warning)]);
    if (match_has_tag 'vnc_certificate_warning') {
        send_key 'ret';
        assert_screen [qw(displaymanager vncmanager-greeter vnc_certificate_warning-2)];
        if (match_has_tag 'vnc_certificate_warning-2') {
            send_key 'ret';
        }
    }
}

sub vncviewer_login_presession {
    assert_screen 'vncmanager-greeter';
    assert_and_click 'vncmanager-greeter-presession';
    assert_screen 'vncmanager-greeter-login';
    type_string "$username";
    wait_still_screen 2;
    send_key 'tab';
    wait_still_screen 2;
    type_password;
    wait_still_screen 2;
    send_key 'ret';
    assert_screen 'gnome-terminal-launched';
}

sub run {
    my $self = shift;

    # Wait for supportserver if not yet ready
    mutex_lock 'dhcp';
    mutex_unlock 'dhcp';
    mutex_lock 'xvnc';

    # Make sure the client gets the IP address
    x11_start_program('xterm');
    become_root;
    assert_script_run 'dhclient';
    enter_cmd "exit";
    send_key 'alt-f4';

    # First time login and configure the visibility
    $self->start_vncviewer;
    handle_login;
    # Hold Alt key inside the vncviewer
    send_key 'f8';
    assert_screen 'vncviewer-menu';
    send_key 'a';
    wait_still_screen 3;
    send_key 'f2';
    assert_screen 'desktop-runner';
    # Release key inside the vncviewer
    send_key 'f8';
    assert_screen 'vncviewer-menu';
    send_key 'a';
    wait_still_screen 3;
    enter_cmd "gnome-terminal";
    assert_screen 'gnome-terminal-launched';
    enter_cmd "vncmanager-controller";
    assert_screen 'vncmanager-controller';
    assert_and_click 'vncmanager-controller-visibility';
    assert_and_click 'vncmanager-controller-sharing';
    send_key 'alt-o';
    enter_cmd "clear";

    # Exit the vncviewer
    send_key 'f8';
    assert_screen 'vncviewer-menu';
    send_key 'x';
    assert_screen 'generic-desktop';

    # Re-login to the previous session
    $self->start_vncviewer;
    $self->vncviewer_login_presession;

    # Minimize the vncviewer
    send_key 'f8';
    assert_screen 'vncviewer-menu';
    send_key 'z';

    # Login to the sharing session using another vncviewer
    $self->start_vncviewer;
    $self->vncviewer_login_presession;
    # Exit the sharing session
    send_key 'f8';
    assert_screen 'vncviewer-menu';
    send_key 'x';

    # Terminate the minimized session
    hold_key 'alt';
    send_key_until_needlematch('vncviewer-minimize', 'tab');
    release_key 'alt';
    assert_screen 'gnome-terminal-launched';
    assert_and_click 'system-indicator';
    assert_and_click 'user-logout-sector';
    assert_and_click 'logout-system';
    assert_screen 'logout-dialogue';
    send_key 'ret';
    assert_screen 'generic-desktop';

    mutex_unlock 'xvnc';
}

1;
