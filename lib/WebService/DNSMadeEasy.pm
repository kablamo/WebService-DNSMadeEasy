package WWW::DNSMadeEasy;

use feature qw/say/;

use Moo;
use DateTime;
use DateTime::Format::HTTP;
use Digest::HMAC_SHA1 qw(hmac_sha1 hmac_sha1_hex);
use LWP::UserAgent;
use HTTP::Request;
use JSON::MaybeXS;

use WWW::DNSMadeEasy::Domain;
use WWW::DNSMadeEasy::ManagedDomain;
use WWW::DNSMadeEasy::Response;

our $VERSION = "0.01";

has api_key         => (is => 'ro', required => 1);
has secret          => (is => 'ro', required => 1);
has sandbox         => (is => 'ro', default => sub { 0 });
has last_response   => (is => 'rw');
has _http_agent     => (is => 'lazy');
has http_agent_name => (is => 'lazy');
has api_version     => (
    is      => 'ro',
    isa     => sub { $_ && ($_ eq '1.2' or $_ eq '2.0') },
    default => sub { '2.0' },
);

sub _build__http_agent {
    my $self = shift;
    my $ua = LWP::UserAgent->new;
    $ua->agent($self->http_agent_name);
    return $ua;
}

sub _build_http_agent_name { __PACKAGE__.'/'.$VERSION }

sub api_endpoint {
    my ( $self ) = @_;
    if ($self->sandbox) {
        return 'https://api.sandbox.dnsmadeeasy.com/V'.$self->api_version.'/';
    } else {
        return 'https://api.dnsmadeeasy.com/V'.$self->api_version.'/';
    }
}

sub get_request_headers {
    my ( $self, $dt ) = @_;
    $dt = DateTime->now->set_time_zone( 'GMT' ) if !$dt;
    my $date_string = DateTime::Format::HTTP->format_datetime($dt);
    return {
        'x-dnsme-requestDate' => $date_string,
        'x-dnsme-apiKey'      => $self->api_key,
        'x-dnsme-hmac'        => hmac_sha1_hex($date_string, $self->secret),
    };
}

sub request {
    my ( $self, $method, $path, $data ) = @_;
    my $url = $self->api_endpoint.$path;
    say "$method $url" if $ENV{WWW_DME_DEBUG};
    my $request = HTTP::Request->new( $method => $url );
    my $headers = $self->get_request_headers;
    $request->header($_ => $headers->{$_}) for (keys %{$headers});
    $request->header('Accept' => 'application/json');
    if (defined $data) {
        $request->header('Content-Type' => 'application/json');
        $request->content(encode_json($data));
        use DDP; p $data if $ENV{WWW_DME_DEBUG};
    }
    my $res = $self->_http_agent->request($request);
    $res = WWW::DNSMadeEasy::Response->new( http_response => $res );
    say $res->content if $ENV{WWW_DME_DEBUG};
    $self->last_response($res);
    die ' HTTP request failed: ' . $res->status_line . "\n" unless $res->is_success;
    return $res;
}

sub requests_remaining {
    my ( $self ) = @_;
    return $self->last_response ? $self->last_response->requests_remaining : undef;
}

sub last_request_id {
    my ( $self ) = @_;
    return $self->last_response ? $self->last_response->request_id : undef;
}

sub request_limit {
    my ( $self ) = @_;
    return $self->last_response ? $self->last_response->request_limit : undef;
}

#
# V2 Managed domains (TODO - move this into a role)
#

sub domain_path {'dns/managed/'}

sub create_managed_domain {
    my ($self, $name) = @_;
    my $data     = {name => $name};
    my $response = $self->request(POST => $self->domain_path, $data);
    return WWW::DNSMadeEasy::ManagedDomain->new(
        dme        => $self,
        name       => $response->as_hashref->{name},
        as_hashref => $response->as_hashref,
    );
}

sub get_managed_domain {
    my ($self, $name) = @_;
    return WWW::DNSMadeEasy::ManagedDomain->new(
        name => $name,
        dme  => $self,
    );
}

sub managed_domains {
    my ($self) = @_;
    my $data   = $self->request(GET => $self->domain_path)->as_hashref->{data};

    my @domains;
    push @domains, WWW::DNSMadeEasy::ManagedDomain->new({
        dme  => $self,
        name => $_->{name},
    }) for @$data;

    return @domains;
}


1;


=encoding utf8

=head1 SYNOPSIS

    use WWW::DNSMadeEasy;
  
    my $dns = WebService::DNSMadeEasy->new({
        api_key     => $api_key,
        secret      => $secret,
        sandbox     => 1,     # defaults to 0
    });

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

=item http_agent_name

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

    $domain->as_hashref;
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

    $record->as_hashref;
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

