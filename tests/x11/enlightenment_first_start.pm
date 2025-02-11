# SUSE's openQA tests
#
# Copyright © 2012-2020 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Package: enlightenment
# Summary: Other Desktop Environments: Enlightenment
# Maintainer: Dominique Leuenberger <dimstar@opensuse.org>

use base "x11test";
use strict;
use warnings;
use testapi;
use utils;
use Utils::Architectures;

sub run {
    mouse_hide();
    assert_screen [qw(enlightenment_keyboard_english enlightenment_language_english)];
    if (match_has_tag 'enlightenment_language_english') {
        record_soft_failure('bsc#1076835 - Enlightenment: newly asks for language');
        assert_and_click "enlightenment_language_english";
        assert_and_click "enlightenment_assistant_next";
    }
    assert_and_click "enlightenment_keyboard_english";
    assert_and_click "enlightenment_assistant_next";
    assert_and_click "enlightenment_profile_selection";
    assert_and_click "enlightenment_assistant_next";
    assert_and_click "enlightenment_profile_size";
    assert_and_click "enlightenment_assistant_next";
    assert_screen "enlightenment_windowfocus";
    assert_and_click "enlightenment_assistant_next";
    assert_screen [qw(enlightenment_keybindings enlightenment_bluez_not_found)];
    if (match_has_tag 'enlightenment_keybindings') {
        assert_and_click "enlightenment_assistant_next";
        assert_screen [qw(enlightenment_compositing enlightenment_bluez_not_found)];
    }
    if (match_has_tag 'enlightenment_bluez_not_found') {
        assert_and_click 'enlightenment_assistant_next';
        assert_screen 'enlightenment_compositing';
    }
    assert_and_click "enlightenment_assistant_next";
    assert_and_click 'enlightenment_acpid_missing' if (get_required_var('ARCH') =~ /86/ || is_aarch64);
    assert_screen 'enlightenment_generic_desktop';
}

sub test_flags {
    return {milestone => 1};
}

1;
