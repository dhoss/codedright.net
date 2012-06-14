use Mojolicious::Lite;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use HTML::Scrubber;
use Data::Dumper;

get '/' => sub {
  my $self = shift;
  $self->render('contact');
};

post '/' => sub {
  my $self = shift;
  my $scrubber = HTML::Scrubber->new;
  my %cleaned = map { $_ => $scrubber->scrub($self->param($_)) }  $self->param;
  warn "Cleaned" . Dumper \%cleaned;
  unless ( $cleaned{'name'} && $cleaned{'email'} && $cleaned{'comments'} ) {
    $self->stash( message => "Name, email and comments are required" );
    $self->render('contact');
  }

  send_email(
    email_template({
      to => 'devin@codedright.net',
      from => 'contact@codedright.net',
      subject => "Contact request from " . $cleaned{'email'},
      body   => $cleaned{'comments'}
    })
  );
  send_email(
    email_template({
      to => $cleaned{'email'},
      from => 'no-reply@codedright.net',
      subject => "Thanks for contacting CodedRight.net, $cleaned{'name'}",
      body   => "Hi $cleaned{'name'}, your comments have been received.  We'll be in touch ASAP!"
    })
  );
  $self->stash( message => "Message submitted successfully!" );
  $self->render('contact');
};

sub email_template {
  my $params = shift;
  warn "PAarams " . Dumper $params;
  my @email = (
    header => [
      To      => $params->{'to'},
      From    => $params->{'from'} || 'contact@codedright.net',
      Subject => $params->{'subject'},
    ],
    body => $params->{'body'},
  );
  return \@email
}

sub send_email {
  my $email_content = shift;
  warn "Email content " . Dumper $email_content;
  my $email = Email::Simple->create(
   @{ $email_content }
  );

  sendmail($email);
}

app->start;
