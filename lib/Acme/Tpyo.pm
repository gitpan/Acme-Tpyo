package Acme::Tpyo;

use 5.008003;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Acme::Misspell ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(misspell);

our $VERSION = '0.03';


# Preloaded methods go here.

my $keysets = {
US_QWERTY => 
   { noshift => 
     [
       {klay => "`1234567890-=\\", offset => 0},
       {klay => "qwertyuiop[]",    offset => 1.5},
       {klay => "asdfghjkl;'",     offset => 1.75},
       {klay => "zxcvbnm,./",      offset => 2},
     ],
     yesshift =>
     [
       {klay => "~!#$%^&*()_+|", offset => 0},
       {klay => "QWERTYUIOP{}",  offset => 1.5},
       {klay => "ASDFGHJKL:\"",  offset => 1.75},
       {klay => "ZXCVBNM<>?",    offset => 2},
     ],
     _allow_table_jump => 1,
     _prob_table_jump => .25,
   }
};

sub getcoords($$)
{
  my $char = shift;
  my $keyset = shift;
  
  my ($sh, $ky, $kx) = ("", -1, -1);

  if (length($char) != 1)
  {
    die "bah i fucked up: $char";
  }
  
  
  for my $ksh (grep(!/^_/,keys %{${$keysets}{$keyset}}))
  { my $kyy = 0;
    for my $khs (@{${${$keysets}{$keyset}}{$ksh}})
    {
      if (${$khs}{klay} =~ /\Q$char/ )
      {
        $sh = $ksh;
        $ky = $kyy;
        $kx = index(${$khs}{klay},$char)+${$khs}{offset};
      }
       $kyy++;
    }
  }

  return ($sh, $kx, $ky);
}

sub getnewchar($$$$)
{
  my ($keyset, $sh, $kx, $ky) = @_;
  my ($ybound, $xlbound, $xrbound);
  my $jump = ${${$keysets}{$keyset}}{_allow_table_jump};
  my $jump_prob = ${${$keysets}{$keyset}}{_prob_table_jump};
  
  if (($jump == 1) && (defined($jump_prob)))
  {
    if (rand() < $jump_prob)
    {
      my @candidates = grep {!/^_/} keys %{${$keysets}{$keyset}};
      #print "new $sh == ".$candidates[rand(@candidates)]."\n";
      $sh = $candidates[rand(@candidates)];
    }
  }
 
  $ybound = @{${${$keysets}{$keyset}}{$sh}};

  $ky = int($ky +.5);
  if ($ky >= $ybound-1) {$ky = $ybound-1};  
  if ($ky < 0) {$ky = 0};
  
  my $khash = ${${${$keysets}{$keyset}}{$sh}}[$ky];
 
  my $klay = ${$khash}{klay};
  my $off  = ${$khash}{offset};


  $off = 0 unless $off; #NTS: why the hell does this need to be here?!?

  $kx = int($kx +.5-$off);
  if ($kx < 0) { $kx = 0};
  if ($kx > length($klay)) {$kx = length($klay)};


  return substr($klay, $kx, 1);
}

sub misspell($;$$)
{

  my $string = shift;
  my $keyset = shift;
  my $threshold = shift;
  $keyset = "US_QWERTY" unless $keyset;
  $threshold = .01 unless $threshold;
  my $mispell;

  for my $c (split(//, $string))
  {
    my $x = ((rand 2)-1);
    my $y = ((rand 2)-1);
    my ($sh, $kx, $ky) = getcoords($c, $keyset);
    my $q = $c;
    
    if (($kx != -1) && ($ky != -1) && ($sh ne "") && ((rand 1) < $threshold))
    {
      $y += $ky;
      $x += $kx;
      
      $q = getnewchar($keyset, $sh, $x, $y);
    }
    
    $mispell .= $q;
  }
  
  
  if (rand(1) < $threshold)
  {  
  for (1..(rand(length($mispell)/6)-1))
  {
    my $off = int(rand(length($mispell)-1));
    $mispell =~ s/(.{$off})(.)(.)/$1$3$2/;
  }
  }


  return $mispell
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Acme::Tpyo - Perl extension for misspelling words!

=head1 SYNOPSIS

  use Acme::Tpyo;
  print misspell("one of these days alice, bang zoom, straight to the moon");
  ...
  my $keysetup = {
   PST_LAYOUT => 
    { noshift => 
      [
        {klay => "`1234567890-=\\", offset => 0},
        {klay => "qwertyuiop[]",    offset => 0.5},
        {klay => "asdfghjkl;'",     offset => 1.0},
        {klay => "zxcvbnm,./",      offset => 1.5},
      ],
      yesshift =>
      [
        {klay => "~!@#$%^&*()_+|", offset => 0},
        {klay => "QWERTYUIOP{}",  offset => 0.5},
        {klay => "ASDFGHJKL:\"",  offset => 1.0},
        {klay => "ZXCVBNM<>?",    offset => 2},
      ],
      _allow_table_jump => 1,
    }
   }
=head1 DESCRIPTION

Tired of having to misspell your words on accident? 
Want to do it more often and worse than normal?
Acme::Tpyo is for you!
With Acme::Tpyo you can use your normally perfectly type strings
and make them look like a 2nd grader! Great to give your project that
professional edge your boss is always asking for!

=head2 EXPORT

misspell() use it to misspell stuff

=head1 AUTHOR

Ryan Voots, simcop2387@gmail.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ryan Voots

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
