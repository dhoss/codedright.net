use Mojolicious::Lite;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;
use Email::Valid;
use HTML::Scrubber;
use Data::Dumper;

get '/' => sub {
  my $self = shift;
  $self->render('contact');
} => 'index';

post '/' => sub {
  my $self = shift;
  $self->check_form;
  warn "PARAMS " . Dumper $self->req->param;
  unless ( $self->stash('error') ) {
    warn "no errors";
    $self->send_email(
      $self->email_template(
        $self->get_email_content($_)
      )
    ) for qw( incoming reply );
    $self->stash( message => "Message submitted successfully!" );
    return $self->render(ok => 1, template => 'contact');
  }
  warn "errors " . Dumper $self->stash;
  return $self->render('contact');
};


helper check_form => sub {
  my $self = shift;
  my $cleaned = $self->clean_params;

#  $self->stash->{'error'}{captcha} = !( $cleaned->{'captcha'} == 4 ) ? "Invalid" : undef;
#  $self->stash->{'error'}{'email'} = !Email::Valid->address($cleaned->{'email'}) ? "Invalid" : undef;
#  $self->stash(error => {
#    (map { $_ => 'Empty'       } grep { !$cleaned->{$_} } qw(name email comments captcha)),
#  });
   $self->stash( error => "Invalid captcha" ) if !( $cleaned->{'captcha'} == 4 );
   $self->stash( error => "invalid email" ) if !Email::Valid->address($cleaned->{'email'});
   $self->stash( error => "Empty fields" ) if grep { !$cleaned->{$_} } qw(name email comments captcha);
};

helper email_template => sub {
  my $self = shift;
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
};

helper send_email => sub {
  my $self = shift;
  my $email_content = shift;
  warn "Email content " . Dumper $email_content;
  my $email = Email::Simple->create(
   @{ $email_content }
  );

  sendmail($email);
};

helper clean_params => sub {
  my $self = shift;
  my $scrubber = HTML::Scrubber->new;
  my %cleaned = map { $_ => $scrubber->scrub($self->req->param($_)) }  $self->req->param;
  return \%cleaned;
};

helper get_email_content => sub {
  my $self = shift;
  my $template_name = shift;
  my $cleaned = $self->clean_params( $self->req->param );
  my $template = {
    incoming => {
      to => 'devin@codedright.net',
      from => 'contact@codedright.net',
      subject => "Contact request from " . $cleaned->{'email'},
      body   => $cleaned->{'comments'}
    },
    reply => {
      to => $cleaned->{'email'},
      from => 'no-reply@codedright.net',
      subject => "Thanks for contacting CodedRight.net, $cleaned->{'name'}",
      body   => "Hi $cleaned->{'name'}, your comments have been received.  We'll be in touch ASAP!"
    }
  };

  return $template->{$template_name};
};


app->start;
