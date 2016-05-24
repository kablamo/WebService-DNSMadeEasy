package WebService::DNSMadeEasy;

use Moo;

use WebService::DNSMadeEasy::Client;
use WebService::DNSMadeEasy::ManagedDomain;

our $VERSION = "0.01";

has api_key           => (is => 'ro', required => 1);
has secret            => (is => 'ro', required => 1);
has sandbox           => (is => 'ro', default => sub { 0 });
has user_agent_header => (is => 'rw', lazy => 1, builder => 1);
has client            => (is => 'lazy', handles => [qw/get/]);

sub _build_user_agent_header { __PACKAGE__ . "/" . $VERSION }

sub _build_client {
    my $self = shift;
    my $client = WebService::DNSMadeEasy::Client->new(
        api_key           => $self->api_key,
        secret            => $self->secret,
        sandbox           => $self->sandbox,
        user_agent_header => $self->user_agent_header,
    );

    $client->user_agent_header($self->user_agent_header)
        if $self->user_agent_header;

    return $client;
}

sub create_managed_domain {
    my ($self, $name) = @_;
    return WebService::DNSMadeEasy::ManagedDomain->create(
        client => $self->client,
        name   => $name,
    );
}

sub get_managed_domain {
    my ($self, $name) = @_;
    return WebService::DNSMadeEasy::ManagedDomain->new(
        client => $self->client,
        name   => $name,
    );
}

sub managed_domains { WebService::DNSMadeEasy::ManagedDomain->find(client => shift->client) }

1;

=encoding utf8

=head1 SYNOPSIS

    use WebService::DNSMadeEasy;
  
    my $dns = WebService::DNSMadeEasy->new({
        api_key => $api_key,
        secret  => $secret,
        sandbox => 1,     # defaults to 0
    });

    # DOMAINS - see WebService::DNSMadeEasy::ManagedDomain
    my @domains = $dns->managed_domains;
    my $domain  = $dns->get_managed_domain('example.com');
    my $domain  = $dns->create_managed_domain('stegasaurus.com');
    $domain->update(...); # update some attributes
    $domain->delete;
    ...

    # RECORDS - see WebService::DNSMadeEasy::ManagedDomain::Record
    my @records = $domain->records();                # Returns all records
    my @records = $domain->records(type => 'CNAME'); # Returns all CNAME records
    my @records = $domain->records(name => 'www');   # Returns all wwww records
    $record->update(...); # update some attributes
    $record->delete;
    ...

    # MONITORS - see WebService::DNSMadeEasy::Monitor
    my $monitor = $record->get_monitor;
    $monitor->disable;     # disable failover and system monitoring
    $monitor->update(...); # update some attributes
    ...

=head1 DESCRIPTION

This distribution implements v2 of the DNSMadeEasy API as described in
L<http://dnsmadeeasy.com/integration/pdf/API-Docv2.pdf>.

=head1 ATTRIBUTES

=over 4

=item api_key

You can get find this here: L<https://cp.dnsmadeeasy.com/account/info>.

=item secret

You can find this here: L<https://cp.dnsmadeeasy.com/account/info>.

=item sandbox

Uses the sandbox api endpoint if set to true.  Creating a sandbox account is a
good idea so you can test before messing with your live/production account.
You can create a sandbox account here: L<https://sandbox.dnsmadeeasy.com>.

=item user_agent_header

Here you can set the User-Agent http header.  

=back

=head1 DOMAINS

These methods return L<WebService::DNSMadeEasy::ManagedDomain> objects.

    my @domains = $dns->managed_domains;
    my $domain  = $dns->get_managed_domain('example.com');
    my $domain  = $dns->create_managed_domain('stegasaurus.com');

Domain actions

    $domain->delete;
    $domain->update(...); # update domain attributes
    my @records = $domain->records();                # Returns all records
    my @records = $domain->records(type => 'CNAME'); # Returns all CNAME records
    my @records = $domain->records(name => 'www');   # Returns all wwww records

Domain attributes

    $domain->data; # returns all attributes as a hashref
    $domain->active_third_parties;
    $domain->created;
    $domain->delegate_name_servers;
    $domain->folder_id;
    $domain->gtd_enabled;
    $domain->id;
    $domain->name_servers;
    $domain->pending_action_id;
    $domain->process_multi;
    $domain->updated;

=head1 RECORDS

These methods return L<WebService::DNSMadeEasy::ManagedDomain::Record> objects.

    my @records = $domain->records;
    my $record  = $domain->update(...);
    my $record  = $domain->create_record(
        ttl          => 120,
        gtd_location => 'DEFAULT',
        name         => 'www',
        data         => '1.2.3.4',
        type         => 'A',
    );

Record actions

    $record->delete;
    $record->update(...); # update any record attribute
    my $monitor = $record->get_monitor;

Record attributes

    $record->data; # returns all attributes as a hashref
    $record->description;
    $record->dynamic_dns;
    $record->failed;
    $record->failover;
    $record->gtd_location;
    $record->hard_link;
    $record->id;
    $record->keywords;
    $record->monitor
    $record->mxLevel;
    $record->name;
    $record->password;
    $record->port;
    $record->priority;
    $record->redirect_type;
    $record->source;
    $record->source_id;
    $record->title;
    $record->ttl;
    $record->type;
    $record->value;
    $record->weight;

=head1 MONITORS

Monitor actions
    $monitor->disable;     # disable failover and system monitoring
    $monitor->update(...); # update any attribute

Monitor attributes

    $monitor->data; # returns all attributes as a hashref
    $monitor->auto_failover;
    $monitor->contact_list_id;
    $monitor->failover;
    $monitor->http_file;
    $monitor->http_fqdn;
    $monitor->http_query_string;
    $monitor->ip1;
    $monitor->ip1_failed;
    $monitor->ip2;
    $monitor->ip2_failed;
    $monitor->ip3;
    $monitor->ip3_failed;
    $monitor->ip4;
    $monitor->ip4_failed;
    $monitor->ip5;
    $monitor->ip5_failed;
    $monitor->max_emails;
    $monitor->monitor;
    $monitor->port;
    $monitor->protocol_id;
    $monitor->record_id;
    $monitor->sensitivity;
    $monitor->source;
    $monitor->source_id;
    $monitor->system_description;

    $monitor->ips();       # returns a list of the failover ips
    $monitor->protocol();  # returns the protocol being monitored
                           #     protocol_id    protocol
                           #         1      =>    TCP
                           #         2      =>    UDP
                           #         3      =>    HTTP
                           #         4      =>    DNS
                           #         5      =>    SMTP
                           #         6      =>    HTTP

=head1 LICENSE

Copyright (C) Eric Johnson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>
Forked from Torsten Raudssus's WWW::DNSMadeEasy module.

=cut

