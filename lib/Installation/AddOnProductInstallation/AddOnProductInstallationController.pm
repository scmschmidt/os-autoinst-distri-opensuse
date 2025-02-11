# SUSE's openQA tests
#
# Copyright © 2021 SUSE LLC
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved. This file is offered as-is,
# without any warranty.

# Summary: The class introduces business actions for Add-On Product
# Installation dialog.
#
# Maintainer: QE YaST <qa-sle-yast@suse.de>

package Installation::AddOnProductInstallation::AddOnProductInstallationController;
use strict;
use warnings;
use Installation::AddOnProductInstallation::AddOnProductInstallationPage;
use YuiRestClient;

sub new {
    my ($class, $args) = @_;
    my $self = bless {}, $class;
    return $self->init($args);
}

sub init {
    my ($self, $args) = @_;
    $self->{AddOnProductInstallation} = Installation::AddOnProductInstallation::AddOnProductInstallationPage->new({app => YuiRestClient::get_app()});
    return $self;
}

sub get_add_on_product_installation_page {
    my ($self) = @_;
    die "Add-On Product Installation page is not displayed" unless $self->{AddOnProductInstallation}->is_shown();
    return $self->{AddOnProductInstallation};
}

sub accept_add_on_products {
    my ($self) = @_;
    $self->get_add_on_product_installation_page()->press_next();
}

1;
