package WebService::Stormpath;
$VERSION = '0.1.0';

use strict;
use warnings;

use LWP::UserAgent;
use HTTP::Headers;
use JSON;

my $headers = HTTP::Headers->new();
$headers->header(Accept => 'application/json');

my $ua = LWP::UserAgent->new();
$ua->agent('Stormpath Perl Connector');
$ua->default_headers($headers);


sub new {
    my ( $class, $self ) = @_;
    bless $self, $class;
    die 'apiid does not exist in self' unless exists $self->{'apiid'};
    die 'apikey does not exist in self' unless exists $self->{'apikey'};
    return $self;
}

sub query {
    my ( $self, $resource, $action, $data ) = @_;
    die 'resource does not exist in self' unless $resource;

    $ua->credentials(
        'api.stormpath.com:443',
        'Stormpath IAM',
        $self->{'apiid'},
        $self->{'apikey'},
    );
    my $path = "https://api.stormpath.com/v1/$resource";
    $path .= "/$action" if $action;

    my $req = HTTP::Request->new(GET => $path);
    if ( $data ) {
        if ( $data eq ':delete:' ) {
            $req = HTTP::Request->new(DELETE => $path);
        }
        else {
            $req = HTTP::Request->new(POST => $path);
            $req->content_type('application/json;charset=UTF-8');
            $req->content(encode_json $data);
        }
    }
    my $response = $ua->request($req);

    if ( $response->content() ) {
        return decode_json $response->content();
    }
    else {
        return undef;
    }
}

sub accounts {
    my ( $self ) = @_;
    return $self->query('accounts', 'current');
}

sub account {
    my ( $self, $account_id ) = @_;
    return $self->query('accounts', $account_id);
}

sub tenants {
    my ( $self ) = @_;
    return $self->query('tenants', 'current');
}

sub tenant_id {
    my ( $self ) = @_;
    my $tenant = $self->tenants();
    my @comps = split m{/}, $tenant->{'href'};
    return $comps[-1];
}

sub directories {
    my ( $self ) = @_;
    my $tenant_id = $self->tenant_id();
    return $self->query('tenants', "$tenant_id/directories");
}

sub applications {
    my ( $self ) = @_;
    my $tenant_id = $self->tenant_id();
    return $self->query('tenants', "$tenant_id/applications");
}

sub groups {
    my ( $self ) = @_;
    my $tenant_id = $self->tenant_id();
    return $self->query('tenants', "$tenant_id/groups");
}

sub create_account {
    my ( $self, $directory_id, $info ) = @_;
    die 'directory_id was not specified'      unless $directory_id;
    die 'email does not exist in info'        unless $info->{'email'};
    die 'password does not exist in info'     unless $info->{'password'};
    die 'givenName does not exist in info'    unless $info->{'givenName'};
    die 'surname does not exist in info'      unless $info->{'surname'};

    my $response = $self->query(
        'directories',
        "$directory_id/accounts",
        $info,
    );
    return $response;
}

sub update_account {
    my ( $self, $account_id, $items ) = @_;

    $self->query(
        'accounts',
        $account_id,
        $items,
    );

    return $self->account($account_id);
}

sub delete_account {
    my ( $self, $account_id ) = @_;

    $self->query(
        'accounts',
        $account_id,
        ':delete:',
    );
}

1;

__END__

=head1 NAME

WebService::Stormpath

=head1 SYNOPSIS

 use WebService::Stormpath;
 use Data::Dumper;

 my $stormpath = WebService::Stormpath->new({
     'apiid' => '0123456789ABCDEF012345678',
     'apikey' => '0123456789+abcdef0123456789ABCDEF0123456789',
 });

 print Dumper $stormpath->accounts();

=head1 DESCRIPTION

C<WebService::Stormpath> is a module that provides Perl bindings to the REST
API service provided Stormpath.

=head1 COPYRIGHT

Copyright 2015 Joseph Hall

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
