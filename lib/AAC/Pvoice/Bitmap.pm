package AAC::Pvoice::Bitmap;

use strict;
use warnings;
use Wx qw(:everything);
use Wx::Perl::Carp;

our $VERSION     = sprintf("%d.%02d", q$Revision: 1.2 $=~/(\d+)\.(\d+)/);

use base qw(Wx::Bitmap);

BEGIN
{
    Wx::InitAllImageHandlers;
}

#----------------------------------------------------------------------
sub new
{
    my $class = shift;
    my ($file, $MAX_X, $MAX_Y, $caption, $background, $blowup) = @_;
    $caption||='';
    my $config = Wx::ConfigBase::Get;
    $caption = $config->ReadInt('Caption')?$caption:'';
    return ReadImage($file, $MAX_X, $MAX_Y, $caption, $background, $blowup);
}


sub ReadImage
{
    my $file = shift;
    my ($x, $y, $caption, $background, $blowup) = @_;
    if (not -f $file)
    {
        warn "File does not exist: $file";
    }
    confess "MaxX and MaxY should be positive" if $x < 1 || $y < 1;
    
    my $capdc = Wx::MemoryDC->new();
    my $cpt = 11;
    my ($cfont, $cw, $ch) = (wxNullFont, 0, 0);
    if ($caption)
    {
	do
	{
	    $cfont = Wx::Font->new( $cpt,             # font size
				    wxSWISS,            # font family
				    wxNORMAL,           # style
				    wxNORMAL,           # weight
				    0,                  
				    'Comic Sans MS',   # face name
				    wxFONTENCODING_SYSTEM);
	    ($cw, $ch, undef, undef) = $capdc->GetTextExtent($caption, $cfont);
	    $cpt--;
	} until ($cw<$x);
    }
    my $img = Wx::Image->new($x, $y-$ch);
    $img->SetOption('quality', 100);
    $img->LoadFile($file, wxBITMAP_TYPE_ANY) if -f $file;
    return undef if not $img;
    my ($w,$h) = ($img->GetWidth, $img->GetHeight);
    if (($w > $x) || ($h > ($y-$ch)))
    {
    	my ($newx, $newy) = ($w, $h);
        if ($w > $x)
        {
            my $factor = $w/$x;
	    $newy = int($h/$factor);
	    ($w,$h) = ($x, $newy);
        }
        if ($h > ($y-$ch))
        {
            my $factor = $h/($y-$ch);
	    ($w, $h) = (int($w/$factor),$y-$ch);
        }
        $img = $img->Scale($w, $h);
    }
    elsif ($blowup)
    {
	# Do we really want to blow up images that are too small??
	my $factor = $w/$x;
	my $newy = int($h/$factor);
	($w,$h) = ($x, $newy);
	if ($h > ($y-$ch))
	{
	    my $factor = $h/($y-$ch);
	    ($w, $h) = (int($w/$factor),$y-$ch);
        }
        $img = $img->Scale($w, $h);
    }
    my $bmp = Wx::Bitmap->new($img);
    my $newbmp = Wx::Bitmap->new($x, $y);
    my $tmpdc = Wx::MemoryDC->new();
    $tmpdc->SelectObject($newbmp);
 
    if (defined $background)
    {
        my $bg;
        if (ref($background)=~/ARRAY/)
        {
            $bg = Wx::Colour->new(@$background);
        }
        else
        {
            $bg = $background;
        }
        my $br = Wx::Brush->new($bg, wxSOLID);
        $tmpdc->SetBrush($br);
        $tmpdc->SetBackground($br);
#        print "$caption\n";
    }
    $tmpdc->Clear();

    my $msk = Wx::Mask->new($bmp, Wx::Colour->new(255,255,255));
    $bmp->SetMask($msk);
    $tmpdc->DrawBitmap($bmp, int(($x - $bmp->GetWidth())/2), int(($y-$ch-$bmp->GetHeight())/2), 1);

    if ($caption)
    {
	$tmpdc->SetTextBackground(wxWHITE);
	$tmpdc->SetTextForeground(wxBLACK);
	$tmpdc->SetFont($cfont);
	$tmpdc->DrawText($caption, int(($x-$cw)/2),$y-$ch);
    }
    if (not -f $file)
    {
        my $pt = 72;
        my ($font, $w, $h);
        do
        {
            $font = Wx::Font->new(  $pt,              # font size
                                    wxSWISS,            # font family
                                    wxNORMAL,           # style
                                    wxNORMAL,           # weight
                                    0,                  
                                    'Comic Sans MS');   # face name
            ($w, $h, undef, undef) = $tmpdc->GetTextExtent('?', $font);
            $pt-=12;
        } until (($w<$x) && ($h<($y-$ch)));
        $tmpdc->SetTextForeground(wxWHITE);
        $tmpdc->SetTextBackground(wxBLACK);
        $tmpdc->SetFont($font);
        $tmpdc->DrawText('?', int(($x-$w)/2), int(($y-$ch-$h)/2));
    }
    return $newbmp;
}

1;

__END__

=pod

=head1 NAME

AAC::Pvoice::Panel - The base where a pVoice application consists of

=head1 SYNOPSIS

  use AAC::Pvoice::Bitmap;
  my $bitmap = AAC::Pvoice::Bitmap->new('image.jpg',        #image
                                        100,                #maxX
					100,                #maxY
					'This is my image', #caption
					wxWHITE,            #background
					1);                 #blowup?

=head1 DESCRIPTION

This module is a simpler interface to the Wx::Bitmap to do things with
images that I tend to do with almost every image I use in pVoice applications.

It's a subclass of Wx::Bitmap, so you can call any method that a Wx::Bitmap
can handle on the resulting AAC::Pvoice::Bitmap.

=head1 USAGE

=head2 new(image, maxX, maxY, caption, background, blowup)

This constructor returns a bitmap (useable as a normal Wx::Bitmap), that
has a size of maxX x maxY, the image drawn into it as large as possible.
If blowup has a true value, it will enlarge the image to try and match
the maxX and maxY. Any space not filled by the image will be the
specified background colour. A caption can be specified to draw under the
image.

If the image doesn't exist, it will draw a large questionmark and warn
the user.

=over 4

=item image

This is the path to the image you want to have.

=item maxX, maxY

These are the maximum X and Y size of the resulting image. If the original
image is larger, it will be resized (maintaining the aspect ratio) to
match these values as closely as possible. If the 'blowup' parameter is
set to a true value, it will also enlarge images that are smaller than
maxX and maxY to get the largest possible image within these maximum values.

=item caption

This is an optional caption below the image. The caption's font is Comic Sans MS
and will have a pointsize that will make the caption fit within the maxX
of the image. The resulting height of the caption is subtracted from the
maxY

=item background

This is the background of the image, specified as either a constant
(i.e. wxWHITE) or as an arrayref of RGB colours (like [128,150,201] ).

=item blowup

This boolean parameter determines whether or not images that are smaller
than maxX and maxY should be blown up to be as large as possible within
the given maxX and maxY.

=back

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

perl(1), Wx

=cut
