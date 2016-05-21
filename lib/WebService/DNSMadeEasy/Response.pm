package WWW::DNSMadeEasy::Response;

use Moo;
use JSON::MaybeXS;

has http_response => (
    is       => 'ro',
    required => 1,
    handles   => [qw/
        is_success
        content
        decoded_content
        status_line
        code
        header
        as_string
    /],
);

sub data { shift->as_hashref(@_) }

sub as_hashref { 
    my ($self) = @_;
    return unless $self->http_response->content; # DELETE return 200 but empty content
    return decode_json($self->http_response->content);
}

sub error {
    my ($self) = @_;
    my $err = $self->data->{error};
    $err = [$err] unless ref($err) eq 'ARRAY';
    return wantarray ? @$err : join("\n", @$err);
}

sub request_id {
    my ( $self ) = @_;
    $self->header('x-dnsme-requestId');
}

sub request_limit {
    my ( $self ) = @_;
    $self->header('x-dnsme-requestLimit');
}

sub requests_remaining {
    my ( $self ) = @_;
    $self->header('x-dnsme-requestsRemaining');
}

1;
__END__

=encoding utf8

=head1 SYNOPSIS

  my $response = WWW::DNSMadeEasy->new(...)->request(...);
  if ($response->is_success) {
      my $data = $response->as_hashref;
      my $requestsremaining = $response->header('x-dnsme-requestsremaining');
  } else {
      my @errors = $response->error;
  }

=head1 DESCRIPTION

Response object to fetch headers and error data

=head1 METHODS

=head2 is_success

=head2 content

=head2 decoded_content

=head2 status_line

=head2 code

=head2 header

=head2 as_string

All above are from L<HTTP::Response>

    my $requestsremaining = $response->header('x-dnsme-requestsremaining');
    my $json_data = $response->as_string;

=head2 as_hashref

    my $data = $response->as_hashref;

convert response JSON to HashRef

=head2 error

    my @errors = $response->error;

get the detailed request errors

