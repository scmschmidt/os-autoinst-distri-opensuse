# SUSE's openQA tests
#
# Copyright © 2018-2019 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# Package: zypper-docker
# Summary: Test zypper-docker installation and its usage
#    Cover the following aspects of zypper-docker:
#      * zypper-docker package can be installed
#      * zypper-docker can list local images:                    'zypper-docker images ls'
#      * zypper-docker can list updates/patches:                 'zypper-docker list-updates' 'zypper-docker list-patches'
#      * zypper-docker can list outdated containers:             'zypper-docker ps'
#      * zypper-docker can list updates/patches for a container: 'zypper-docker list-updates-container' 'zypper-docker list-patches-container'
#      * zypper-docker can apply the updates:                    'zypper-docker update'
# Maintainer: Antonio Caristia <acaristia@suse.com>

use base "consoletest";
use testapi;
use Utils::Architectures;
use utils;
use version_utils 'get_os_release';
use strict;
use warnings;
use containers::common;

sub run {
    my ($self) = @_;
    $self->select_serial_terminal;

    my ($running_version, $sp, $host_distri) = get_os_release;

    install_docker_when_needed($host_distri);

    # install zypper-docker and verify installation
    zypper_call('in zypper-docker');
    validate_script_output("zypper-docker -h", sub { m/zypper-docker - Patching Docker images safely/ }, 180);
    my $testing_image = 'registry.opensuse.org/opensuse/leap';

    # Leap container image is missing in s390x
    if ((is_s390x) && ($testing_image =~ /leap/)) {
        record_soft_failure("bsc#1171672 Missing Leap:latest container image for s390x");
        return 0;
    } else {
        # pull image and check zypper-docker's images funcionalities
        assert_script_run("docker image pull $testing_image", timeout => 600);
        my $local_images_list = script_output('docker images');
        die("docker image $testing_image not found") unless ($local_images_list =~ /opensuse\s*/);
        validate_script_output("zypper-docker images ls", sub { m/opensuse/ }, 180);
        assert_script_run("zypper-docker list-updates $testing_image", timeout => 1200);
        assert_script_run("zypper-docker list-patches $testing_image", timeout => 1200);
        # run a container and check zypper-docker's containers funcionalities
        assert_script_run("docker container run -d --name tmp_container $testing_image tail -f /dev/null");
        assert_script_run("zypper-docker ps",                                   timeout => 600);
        assert_script_run("zypper-docker list-updates-container tmp_container", timeout => 1200);
        assert_script_run("zypper-docker list-patches-container tmp_container", timeout => 600);
        # apply all the updates to a new_image
        assert_script_run("zypper-docker update --auto-agree-with-licenses $testing_image new_image", timeout => 900);
        clean_container_host(runtime => 'docker');
    }

}

1;
