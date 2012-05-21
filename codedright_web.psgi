use strict;
use warnings;

use CodedRight::Web;

my $app = CodedRight::Web->apply_default_middlewares(CodedRight::Web->psgi_app);
$app;

