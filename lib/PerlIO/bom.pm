package PerlIO::bom;

use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

#ABSTRACT: Automatic BOM handling in Unicode IO

__END__

=head1 SYNOPSIS

 open my $fh, '<:bom(utf-8)', $filename;

=head1 DESCRIPTION

This module will automate BOM handling. On a reading handle, it will try to detect a BOM and push an appropriate decoding layer for that encoding. If no BOM is detected the specified encoding is used, or UTF-8 if none is given.

A writing handle will be opened with the specified encoding, and a BOM will be written to it.

=head1 SYNTAX

This modules does not have to be loaded explicitly, it will be loaded automatically by using it in an open mode. The module has the following general syntax: C<:bom(encoding)> or C<:bom>. The encoding may be anything C<:encoding> accepts.

=cut
