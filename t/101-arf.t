use strict;
use Test::More;
use lib qw(./lib ./blib/lib);
use Sisimai::ARF;

my $PackageName = 'Sisimai::ARF';
my $MethodNames = {
    'class' => [ 
        'version', 'description', 'headerlist', 'scan', 'is_arf',
        'DELIVERYSTATUS', 'RFC822HEADERS',
    ],
    'object' => [],
};
my $ReturnValue = {
    '01' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/abuse/ },
    '02' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/abuse/ },
    '03' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/abuse/ },
    '04' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/abuse/ },
    '05' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/abuse/ },
    '06' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/abuse/ },
    '07' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/auth-failure/ },
    '08' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/auth-failure/ },
    '09' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/auth-failure/ },
    '10' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/abuse/ },
    '11' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/abuse/ },
    '12' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/opt-out/ },
    '13' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/abuse/ },
    '14' => { 'status' => qr/\A\z/, 'reason' => qr/feedback/, 'feedbacktype' => qr/auth-failure/ },
};

use_ok $PackageName;
can_ok $PackageName, @{ $MethodNames->{'class'} };

MAKE_TEST: {
    my $v = undef;
    my $c = 0;

    $v = $PackageName->version;
    ok $v, '->version = '.$v;
    $v = $PackageName->description;
    ok $v, '->description = '.$v;
    isa_ok $PackageName->headerlist, 'ARRAY';

    is $PackageName->scan, undef, '->scan';
    is $PackageName->is_arf( { 'content-type' => 'multipart/report; report-type=feedback-report;' } ), 1;

    use Sisimai::Data;
    use Sisimai::Mail;
    use Sisimai::Message;

    PARSE_EACH_MAIL: for my $n ( 1..20 ) {

        my $emailfn = sprintf( "./eg/maildir-as-a-sample/new/arf-%02d.eml", $n );
        my $mailbox = Sisimai::Mail->new( $emailfn );
        my $emindex = sprintf( "%02d", $n );
        next unless defined $mailbox;
        ok -f $emailfn, 'email = '.$emailfn;

        while( my $r = $mailbox->read ) {

            my $p = Sisimai::Message->new( 'data' => $r );
            my $o = undef;
            isa_ok $p, 'Sisimai::Message';
            isa_ok $p->ds, 'ARRAY';
            isa_ok $p->header, 'HASH';
            isa_ok $p->rfc822, 'HASH';
            ok length $p->from;

            for my $e ( @{ $p->ds } ) {
                ok length $e->{'date'}, '->date = '.$e->{'date'};
                ok length $e->{'recipient'}, '->recipient = '.$e->{'recipient'};
                ok length $e->{'diagnosis'}, '->diagnosis = '.$e->{'diagnosis'};
                ok length $e->{'agent'}, '->agent = '.$e->{'agent'};

                ok defined $e->{'spec'}, '->spec = '.$e->{'spec'};
                ok defined $e->{'reason'}, '->reason = '.$e->{'reason'};
                ok defined $e->{'status'}, '->status = '.$e->{'status'};
                ok defined $e->{'command'}, '->command = '.$e->{'command'};
                ok defined $e->{'action'}, '->action = '.$e->{'action'};
                ok defined $e->{'rhost'}, '->rhost = '.$e->{'rhost'};
                ok defined $e->{'lhost'}, '->lhost = '.$e->{'lhost'};
                ok defined $e->{'alias'}, '->alias = '.$e->{'alias'};
                ok defined $e->{'feedbacktype'}, '->feedbacktype = ""';
                ok defined $e->{'softbounce'}, '->softbounce = '.$e->{'softbounce'};
            }

            $o = Sisimai::Data->make( 'data' => $p );
            ok scalar @$o, 'entry = '.scalar @$o;
            for my $e ( @$o ) {
                isa_ok $e, 'Sisimai::Data';
                like $e->deliverystatus, $ReturnValue->{ $emindex }->{'status'}, '->status = '.$e->deliverystatus;
                like $e->reason, $ReturnValue->{ $emindex }->{'reason'}, '->reason = '.$e->reason;
                like $e->feedbacktype, $ReturnValue->{ $emindex }->{'feedbacktype'}, '->feedbacktype = '.$e->feedbacktype;
            }
            $c++;
        }
    }
    ok $c, 'the number of emails = '.$c;
}
done_testing;

