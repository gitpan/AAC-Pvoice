package AAC::Pvoice;

use strict;
use warnings;

use Wx;
use Wx::Perl::Carp;
use AAC::Pvoice::Bitmap;
use AAC::Pvoice::Input;
use AAC::Pvoice::Row;
use AAC::Pvoice::EditableRow;
use AAC::Pvoice::Panel;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.8;
	@ISA         = qw (Exporter);
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}


=pod

=head1 NAME

AAC::Pvoice - Create GUI software for disabled people

=head1 SYNOPSIS

  use AAC::Pvoice
  # this includes all AAC::Pvoice modules


=head1 DESCRIPTION

AAC::Pvoice is a set of modules to create software for people who can't
use a normal mouse and/or keyboard. To see an application that uses this
set of modules, take a look at pVoice (http://www.pvoice.org, or the
sources on http://opensource.pvoice.org). 

AAC::Pvoice is in fact a wrapper around many wxPerl classes, to make it
easier to create applications like pVoice.


=head1 USAGE

See the individual module's documentation

=head1 BUGS

probably a lot, patches welcome!


=head1 AUTHOR

	Jouke Visser
	jouke@pvoice.org
	http://jouke.pvoice.org

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), Wx, AAC::Pvoice::Panel, AAC::Pvoice::Bitmap, AAC::Pvoice::Row
AAC::Pvoice::EditableRow, AAC::Pvoice::Input

=cut


1; 
__END__

