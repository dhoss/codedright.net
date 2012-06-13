use Mojolicious::Lite;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use Email::Simple::Creator;

get '/' => sub {
  my $self = shift;
  $self->render('contact');
};


sub email_template {
  my $self = shift;
  my $params = shift;
  my @email = (
    header => [
      To      => $params->{'to'},
      From    => $params->{'from'} || 'contact@codedright.net',
      Subject => $params->{'subject'},
    ],
    body => $params->{'subject'},
  );
}

sub send {
  my $self = shift;
  my $email_content = shift;
  my $email = Email::Simple->create(
   @{ $email_content }
  );

  sendmail($email);
}

app->start;
