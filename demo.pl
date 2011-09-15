#!/usr/bin/perl
use Mojolicious::Lite;
use IPC::ShareLite;
use Data::Dumper;
use Storable;
use Device::SerialPort qw( :PARAM :STAT 0.07 );

my $PortName = '/dev/ttyUSB0';
my $quiet = 0;
my $lockfile = "/tmp/seriallock";
my $PortObj = new Device::SerialPort ($PortName) || die "Can't open $PortName: $!\n";


my $share = IPC::ShareLite->new(
    -key     => 0x1515,
    -create  => 'no',
    -destroy => 'no'
) or die $!;


# Route with placeholder
get '/read.cgi' => sub {
    my $self = shift;

    my $mote_data = Storable::thaw($share->fetch);

    my $xml = "<data>\n";

    my $mote;
    foreach $mote (@$mote_data) {

            if(defined $mote)
            {
                    $xml .= "    <mote id=\"$mote->{id}\" timestamp=\"$mote->{timestamp}\">\n";
                    $xml .= "        <sensor name=\"photo\">$mote->{photo}</sensor>\n";
                    $xml .= "        <sensor name=\"temp\">$mote->{temp}</sensor>\n";
                    $xml .= "    </mote>\n";

            }
    }
    $mote .= "</data>\n";
    $self->render(type => "xml",text => $xml);
};


get '/send.cgi' => sub {
        my $self = shift;

        my $id = $self->param('id');
        my $r  = $self->param('r');
        my $g  = $self->param('g');
        my $b  = $self->param('b');
        my $d13 =$self->param('led');

        my $send_data = pack("cccccccccccccc",0x23,$id,0,0x53,0,0,0,0,0,$r,$g,$b,0,$d13);
        $PortObj->write($send_data); 

        my $html =<<EOF;
<html>
<h2>ok</h2>
<h2>id=$id r=$r b=$b g=$b led=$d13</h2>
</html>
EOF

        $self->render(text => $html);
};




# Start the Mojolicious command system
app->start;

