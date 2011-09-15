#!/usr/bin/perl
use strict;
use Device::SerialPort qw( :PARAM :STAT 0.07 );

my $PortName = $ARGV[0];
my $quiet = 0;
my $lockfile = "/tmp/seriallock";

my $PortObj = new Device::SerialPort ($PortName) || die "Can't open $PortName: $!\n";


$PortObj->baudrate(9600);
$PortObj->parity("none");
$PortObj->databits(8);
$PortObj->stopbits(1);

$PortObj->read_char_time(0);
$PortObj->read_const_time(20);


my $id =$ARGV[1];
my $r =$ARGV[2];
my $g =$ARGV[3];
my $b =$ARGV[4];
my $d13 =$ARGV[5];

my $send_data = pack("cccccccccccccc",0x23,$id,2,0x53,0,0,0,0,0,$r,$g,$b,0,$d13);
$PortObj->write($send_data);
print "$send_data\n";


sleep(.5);

