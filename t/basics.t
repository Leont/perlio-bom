#! /usr/bin/perl

use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More 0.89;
use Encode qw/encode/;
my $BOM = "\x{FEFF}";
my $text = "Hèló Wörld";

for my $shortname (qw/8 16BE 16LE 32BE 32LE/) {
	my $encoding = "UTF-$shortname";
	my $encoded = encode($encoding, $BOM . $text);
	open my $fh, '<:bom', \$encoded or die "Couldn't open $encoding: $!";
	my $read = <$fh>;
	is($read, $text, "Input is correct for $encoding with BOM");
}

for my $shortname (qw/8 16BE 16LE 32BE 32LE/) {
	my $encoding = "UTF-$shortname";
	my $encoded = encode($encoding, $text);
	open my $fh, "<:bom($encoding)", \$encoded or die "Couldn't open for $encoding: $!";
	my $read = <$fh>;
	is($read, $text, "Input is correct for $encoding with default");
}

done_testing();
