#!/usr/bin/perl
use strict;
use Device::SerialPort qw( :PARAM :STAT 0.07 );
use IPC::ShareLite;
use Data::Dumper;
use Storable;
my $PortName = $ARGV[0];
my $quiet = 0;


my $share = IPC::ShareLite->new(
    -key     => 0x1515,
    -create  => 'yes',
    -destroy => 'no'
) or die $!;

#$share->store( "This is stored in shared memory" );


my $PortObj = new Device::SerialPort ($PortName) || die "Can't open $PortName: $!\n";

print "Waiting for data\n";

$PortObj->baudrate(9600);
$PortObj->parity("none");
$PortObj->databits(8);
$PortObj->stopbits(1);

$PortObj->read_char_time(0);
$PortObj->read_const_time(20);


#Create a hash to store the data;

my $mote_data = [];

print "Reading data on $PortName\n";
my $send;
my $timeout = 3000; 
my $chars=0;
my $buffer="";
while ($timeout>0) {
        my ($count,$saw)=$PortObj->read(16); # will read _up to_ 255 chars
        if ($count > 0) {
	      my($d,$to,$from,$type,$a1,$a2) = unpack("AccAnnnnn",$saw);
	
	      print "$d $to $from $type $a1 $a2\n";
	      if($type eq 'D') {
		 $mote_data->[$from] = {"id" => $from, "temp" => $a1, "photo" =>$a2, "timestamp" => time()};
		$share->store(Storable::freeze($mote_data));
	      }
	      $timeout = 3000;
	      sleep(.1);
	    }

        else {
               
		$timeout--;
	}
 }

 if ($timeout==0) {
    print "Out of time\n";
 }
