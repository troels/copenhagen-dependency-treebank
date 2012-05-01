#!/usr/bin/perl -w

use strict;
use warnings;
use open IN  => ":crlf";

use File::Copy;
use Data::Dumper; $Data::Dumper::Indent = 1;
sub d { print STDERR Data::Dumper->Dump([ @_ ]); }

binmode STDOUT, ":utf8";
binmode STDERR, ":utf8";


# Escape characters 
my $map = { map { $_ => 1 } split( //o, "\\<> \t\n\r\f\"" ) };


my $usage =
  "Produce ProgGraph files: \n".
  "  -A in:  Alignment file <filename>.{atag,src,tgt}\n".
  "     out: Write output   <filename>.{srcTok,tgtTok}\n".
  "Options:\n".
  "  -O out: Write output   <filename>.{srcTok,tgtTok}\n".
  "  -v verbose mode [0 ... ]\n".
  "  -h this help \n".
  "\n";

use vars qw ($opt_O $opt_A $opt_v $opt_h);

use Getopt::Std;
getopts ('A:O:v:t:h');

die $usage if defined($opt_h);

my $Verbose = 0;
my $fn = '';

if (defined($opt_v)) {$Verbose = $opt_v;}

### Read and Tokenize Translog log file
if(defined($opt_O)) { $fn = $opt_O;}
else { $fn = $opt_A;}
if(defined($opt_A)) {
  my $A=ReadAtag($opt_A);
  ReadAlign("$opt_A.giza", $A);
  PrintAtag($fn, $A);
  exit;
}

printf STDERR "No Output produced\n";
die $usage;

exit;

############################################################
# escape
############################################################

sub escape {
  my ($in) = @_;
#printf STDERR "in: $in\n";
  $in =~ s/(.)/exists($map->{$1})?sprintf('\\%04x',ord($1)):$1/egos;
  return $in;
}

sub unescape {
  my ($in) = @_;
  $in =~ s/\\([0-9a-f]{4})/sprintf('%c',hex($1))/egos;
  return $in;
}

sub MSunescape {
  my ($in) = @_;

  $in =~ s/&amp;/\&/g;
  $in =~ s/&gt;/\>/g;
  $in =~ s/&lt;/\</g;
  $in =~ s/&#xA;/\n/g;
  $in =~ s/&#xD;/\r/g;
  $in =~ s/&#x9;/\t/g;
  $in =~ s/&quot;/"/g;
  $in =~ s/&nbsp;/ /g;
  return $in;
}

sub MSescape {
  my ($in) = @_;

  $in =~ s/\&/&amp;/g;
  $in =~ s/\>/&gt;/g;
  $in =~ s/\</&lt;/g;
  $in =~ s/\n/&#xA;/g;
  $in =~ s/\r/&#xD;/g;
  $in =~ s/\t/&#x9;/g;
  $in =~ s/"/&quot;/g;
  $in =~ s/ /&nbsp;/g;
  return $in;
}



sub ReadAlign {
  my ($fn,$A) = @_;
  my ($H, $k, $s, $D, $n);

  if(!open(DATA, "<:encoding(utf8)", $fn)) {
    printf STDERR "ReadAlign: cannot open: $fn\n";
    exit ;
  }

  if($Verbose) {printf STDERR "ReadDtag: %s\n", $fn;}

  $n = 0;
  while(defined($_ = <DATA>)) {
    chomp;
    my $L = [split(/\s+/)];
    for (my $i = 0; $i < $#{$L}; $i++) {
      my ($in, $out) = split(/-/, $L->[$i]);
      $A->{'align'}{$n}{$in}{$out} ++;
printf STDERR "$in-$out ";
    }
    $n++;
  }
}
      
#printf STDERR "$_\n";
    
    
###########################################################
# Read src and tgt files
############################################################


sub ReadDTAG {
  my ($fn) = @_;
  my ($x, $k, $s, $D, $n); 

  if(!open(DATA, "<:encoding(utf8)", $fn)) {
    printf STDERR "ReadDTAG: cannot open: $fn\n";
    exit ;
  }

  if($Verbose) {printf STDERR "ReadDtag: %s\n", $fn;}

  $n = 1;
  while(defined($_ = <DATA>)) {
    if($_ =~ /^\s*$/) {next;}
    if($_ =~ /^#/) {next;}
    chomp;
#printf STDERR "$_\n";

    if(!/<W ([^>]*)>([^<]*)/) {next;} 
    $x = $1;
    $s = unescape($2);
    if(/id="([^"])"/ && $1 != $n) {
      printf STDERR "Read $fn: unmatching n:$n and id:$1\n";
      $n=$1;
    }

    $s =~ s/([\(\)\\\/])/\\$1/g;
    $D->{$n}{'tok'}=$s;
#printf STDERR "\tvalue:$2\t";
    $x =~ s/\s*([^=]*)\s*=\s*"([^"]*)\s*"/AttrVal($D, $n, $1, $2)/eg;
    if(defined($D->{$n}{id}) && $D->{$n}{id} != $n)  {
      print STDERR "ReadDTAG: IDs $fn: n:$n\tid:$D->{$n}{id}\n";
    }
    $n++;
  }
  close (DATA);
  return $D;
}

############################################################
# Read Atag file
############################################################

sub AttrVal {
  my ($D, $n, $attr, $val) = @_;

#printf STDERR "$n:$attr:$val\t";
  $D->{$n}{$attr}=unescape($val);
}


sub ReadAtag {
  my ($fn) = @_;
  my ($A, $K, $fn1, $i, $is, $os, $lang, $n); 

  if(!open(ALIGN,  "<:encoding(utf8)", "$fn.atag")) {
    printf STDERR "ReadAtag: cannot open for reading: $fn.atag\n";
    exit 1;
  }

  if($Verbose) {printf STDERR "ReadAtag: $fn.atag\n";}

## read alignment file
  $n = 0;
  while(defined($_ = <ALIGN>)) {
    if($_ =~ /^\s*$/) {next;}
    if($_ =~ /^#/) {next;}
    chomp;

#printf STDERR "Alignment %s\n", $_;
## read aligned files
    if(/<alignFile/) {
      my $path = $fn;
      if(/href="([^"]*)"/) { $fn1 = $1;}

## read reference file "a"
      if(/key="a"/) { 
        $A->{'a'}{'fn'} =  $fn1;
        if($fn1 =~ /src$/)    { $lang='Source'; $A->{'a'}{'lang'} = 'Source'; $path .= ".src";}
        elsif($fn1 =~ /tgt$/) { $lang='Final'; $A->{'a'}{'lang'} = 'Final'; $path .= ".tgt";}
      }
## read reference file "b"
      elsif(/key="b"/) { 
        $A->{'b'}{'fn'} =  $fn1;
        if($fn1 =~ /src$/) { $lang='Source'; $A->{'b'}{'lang'} = 'Source'; $path .= ".src";}
        elsif($fn1 =~ /tgt$/) { $lang='Final'; $A->{'b'}{'lang'} = 'Final';$path .= ".tgt";}
      }
      else {printf STDERR "Alignment wrong %s\n", $_;}

#      $A->{$lang}{'D'} =  ReadDTAG("$path/$fn1"); 
      $A->{$lang}{'D'} =  ReadDTAG("$path"); 
  
      next;
    }

    if(/<align /) {
#printf STDERR "ALN: $_\n";
      if(/in="([^"]*)"/) { $is=$1;}
      if(/out="([^"]*)"/){ $os=$1;}

      ## aligned to itself
      if($is eq $os) {next;}

      if(/insign="([^"]*)"/) { $is=$1;}
      if(/outsign="([^"]*)"/){ $os=$1;}

      if(/in="([^"]*)"/) { 
        $K = [split(/\s+/, $1)];
        for($i=0; $i <=$#{$K}; $i++) {
          if($K->[$i] =~ /([ab])(\d+)/) { 
            $A->{'n'}{$n}{$A->{$1}{'lang'}}{'id'}{$2} ++;
            $A->{'n'}{$n}{$A->{$1}{'lang'}}{'s'}=$is;
          }
#printf STDERR "IN:  %s\t$1\t$2\n", $K->[$i];
        }
      }
      if(/out="([^"]*)"/) { 
        $K = [split(/\s+/, $1)];
        for($i=0; $i <=$#{$K}; $i++) {
          if($K->[$i] =~ /([ab])(\d+)/) { 
            $A->{'n'}{$n}{$A->{$1}{'lang'}}{'id'}{$2} ++;
            $A->{'n'}{$n}{$A->{$1}{'lang'}}{'s'}=$os;
          }
        }
      }
      $n++;
    }
  }
  close (ALIGN);
  return ($A);
}

sub PrintAtag{
  my ($fn, $A) = @_;

  print STDOUT "<DTAGalign>\n";
  print STDOUT "<alignFile key=\"a\" href=\"$fn.src\" />\n";
  print STDOUT "<alignFile key=\"b\" href=\"$fn.tgt\" >\n";

  my $m = -1;
  my $type = '';
  foreach my $n (sort {$a<=>$b} keys %{$A->{align}}) {
#d($A->{n}{$n}{Source}{id});
    foreach my $src (sort {$a<=>$b} keys %{$A->{align}{$n}}) {
      foreach my $tgt (sort {$a<=>$b} keys %{$A->{align}{$n}{$src}}) {
        if($n != $m) { $type = "first";}
        else {$type = '';}
        print STDERR "<atag out=\"a$src\" type=\"$type\" in=\"b$tgt\" />\n";
        print STDOUT "<atag out=\"a$src\" type=\"$type\" in=\"b$tgt\" />\n";
        $m=$n;
      }
print STDERR "XXX\n";
    }
  }
  print STDOUT "</DTAGalign>\n";
}