package AAC::Pvoice::Panel;
use strict;
use warnings;

our $VERSION     = sprintf("%d.%02d", q$Revision: 1.3 $=~/(\d+)\.(\d+)/);

use Wx qw(:everything);
use Wx::Perl::Carp;
use base qw(Wx::Panel);

#----------------------------------------------------------------------
sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->SetBackgroundColour(wxWHITE);
    $self->{tls} = Wx::FlexGridSizer->new(0,1);

    $self->{parent} = $_[0];
    $self->{position} = $_[2];
    $self->{size} = $_[3];
    $self->{totalrows} = 0;
    $self->{lastrow} = 0;
    $self->{currentpage} = 0;
    $self->{disabletextrow} = $_[5] || 0;
    my ($x, $y);
    # to get the right dimensions for the items, se maximize the
    # window, show it, get the dimensions, and hide it again
    if (ref($self->{parent}) =~ /Frame/)
    {
	$self->{parent}->Maximize(1) unless $self->{parent}->IsMaximized;
	$self->{parent}->Show(1);
	($x, $y) = ( $self->GetSize()->GetWidth(),
		     $self->GetSize()->GetHeight() );
	$self->{parent}->Show(0);
    }
    else
    {
	($x, $y) = @{$self->{size}};
    }
    $self->AddTitle('');
    $self->{parent}->{itemspacing} = 3;
    $self->xsize($x);
    $self->ysize($y - 60 - $self->{title}->GetSize()->GetHeight());
    $self->SetSizer($self->{tls});
    $self->SetAutoLayout(1);

    $self->{displaytextsave} = [];
    $self->{speechtextsave} = [];
    
    # Initialize the input stuff
    $self->{input} = AAC::Pvoice::Input->new($self);
    $self->{input}->Next(  sub{$self->Next});
    $self->{input}->Select(sub{$self->Select});
    
    return $self;
}


sub xsize
{
    my $self = shift;
    $self->{xsize} = shift || $self->{xsize};
    return $self->{xsize};
}

sub ysize
{
    my $self = shift;
    $self->{ysize} = shift || $self->{ysize};
    return $self->{ysize};
}


sub SelectColour
{
    return Wx::Colour->new(255,131,131);
}

sub BackgroundColour
{
    my ($self, $backgroundcolour) = @_;
    $self->SetBackgroundColour($backgroundcolour);
    $self->{backgroundcolour} = $backgroundcolour;
}

sub AddTitle
{
    my ($self, $title) = @_;
    # Create the TextControl
    my $font = Wx::Font->new(  18,                 # font size
                               wxDECORATIVE,       # font family
                               wxNORMAL,           # style
                               wxNORMAL,           # weight
                               0,                  
                               'Comic Sans MS',    # face name
                               wxFONTENCODING_SYSTEM);
    $self->{title} = Wx::StaticText->new(   $self,         
                                            -1,             
                                            $title,
                                            wxDefaultPosition,
                                            wxDefaultSize,
                                            wxALIGN_CENTRE);
    $self->{title}->SetFont($font);
    $self->{tls}->Add($self->{title},0, wxALL|wxALIGN_CENTRE, 0);
}

sub Append
{
    my $self = shift;
    my $row = shift;
    my $unselectable = shift;
    $self->{tls}->Add($row,                 # what to add
                      0,                    # unused
                      wxALL|wxALIGN_CENTRE, # style
                      0);                   # padding
    $self->{totalrows}++ if not $unselectable;
    $self->{lastrow}++;
    push @{$self->{rows}}, $row if not $unselectable;
    push @{$self->{unselectablerows}}, $row if $unselectable;
}

sub Clear
{
    my $self = shift;
    $self->{tls}->Remove($_) for (0..$self->{lastrow});
    $_->Destroy for @{$self->{rows}};
    $_->Destroy for @{$self->{unselectablerows}};
    $self->{text}->Destroy if exists $self->{text};
    $self->{title}->Destroy if exists $self->{title};
    $self->{rows} = [];
    $self->{unselectablerows} = [];    
    $self->SUPER::Clear();
    $self->{totalrows} = 0;
    $self->{lastrow} = 0;
    $self->Refresh;
}

sub Finalize
{
    my $self = shift;
    
    # Create the TextControl
    my $font = Wx::Font->new(  24,             # font size
                               wxSWISS,            # font family
                               wxNORMAL,           # style
                               wxNORMAL,           # weight
                               0,
                               'Comic Sans MS',   # face name
                               wxFONTENCODING_SYSTEM);
    $font->SetUnderlined(1);
    $self->{ta} = Wx::TextAttr->new( Wx::Colour->new(0,0,0),      # textcol
                                     Wx::Colour->new(255,255,255),# backgr.
                                     $font);                      # font
    my $rowsizer = Wx::FlexGridSizer->new(1,0);
    $self->{text} = Wx::TextCtrl->new( $self,            # parent
                                       -1,               # id
                                       '',               # text
                                       wxDefaultPosition,# position
                                       [$self->{xsize},60], # size
                                       wxTE_RICH|
                                       wxTE_MULTILINE);  # style
    # set the text-attributes
    $self->{text}->SetDefaultStyle($self->{ta});
    $rowsizer->Add($self->{text},          # what to add
                   0,                      # unused
                   wxALL|wxALIGN_CENTRE,   # style
                   0);                     # padding
    $self->{tls}->Add($rowsizer, 0, wxALL|wxALIGN_CENTRE, 0);
    $self->{textrowsizer} = $rowsizer;

    $self->{text}->Show(0) if $self->{disabletextrow};
    $self->{tls}->AddGrowableCol(0);
    $self->{tls}->AddGrowableRow($_) for (0..$self->{totalrows});

    # Select the first row
    $self->{selectedrow} = 0;
    $self->{selecteditem} = 0;
    $self->{rows}->[$self->{selectedrow}]->SetBackgroundColour(SelectColour()) unless $self->{parent}->{editmode};
    $self->{rowselection} = 1;

    $self->{text}->SetValue($self->RetrieveText);
    $self->{text}->SetStyle(0, length($self->{text}->GetValue), $self->{ta});

    $self->{tls}->Fit($self);
    $self->{tls}->Layout();
    $self->Refresh();
}

sub Next
{
    my $self = shift;
	return if $self->{parent}->{editmode};
    if ($self->{rowselection})
    {
        $self->{rows}->[$self->{selectedrow}]->SetBackgroundColour($self->{backgroundcolour});
        if ($self->{selectedrow} < ($self->{totalrows}-1))
        {
            $self->{selectedrow}++;
        }
        else
        {
            $self->{selectedrow} = 0;
        }
        $self->{rows}->[$self->{selectedrow}]->SetBackgroundColour(SelectColour());
    }
    else
    {
        $self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]->SetBackgroundColour($self->{backgroundcolour});
        if ($self->{selecteditem} < ($self->{rows}->[$self->{selectedrow}]->{totalitems}-1))
        {
            $self->{selecteditem}++;
        }
        else
        {
            $self->{selecteditem} = 0;
        }
        $self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]->SetBackgroundColour(SelectColour());
    }
    $self->Refresh();
}

sub Select
{
    my $self = shift;
    return if $self->{parent}->{editmode};
    if (($self->{rowselection}) &&  (@{$self->{rows}->[$self->{selectedrow}]->{items}} == 1))
    {
	$self->{rowselection} = 0;
	$self->{selecteditem} = 0;
    }
    if ($self->{rowselection})
    {
        $self->{rows}->[$self->{selectedrow}]->SetBackgroundColour($self->{backgroundcolour});
        $self->{rowselection} = 0;
        $self->{selecteditem} = 0;
        $self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]->SetBackgroundColour(SelectColour());
    }
    else
    {
        $self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]->SetBackgroundColour($self->{backgroundcolour});
        &{$self->{rows}->[$self->{selectedrow}]->{actions}->[$self->{selecteditem}]};
        $self->{rows}->[$self->{selectedrow}]->SetBackgroundColour(SelectColour());
        $self->{rowselection} = 1;
    }
    $self->Refresh();
}

sub ToRowSelection
{
    my $self = shift;
	return if $self->{parent}->{editmode};
    $self->{rows}->[$self->{selectedrow}]->{items}->[$self->{selecteditem}]->SetBackgroundColour($self->{backgroundcolour});
    $self->{rows}->[$self->{selectedrow}]->SetBackgroundColour(SelectColour());
    $self->{rowselection} = 1;
    $self->Refresh();

}

sub DisplayAddText
{
    my $self = shift;
    push @{$self->{displaytextsave}}, $_[0];
    $self->{text}->AppendText($_[0])
}

sub SpeechAddText
{
    my $self = shift;
    push @{$self->{speechtextsave}}, $_[0];
}

sub RetrieveText
{
    my $self = shift;
    return join('', @{$self->{displaytextsave}});
}

sub ClearText
{
    my $self = shift;
    $self->{displaytextsave}=[];
    $self->{speechtextsave}=[];
    $self->{text}->SetValue('')
}

sub BackspaceText
{
    my $self = shift;
    pop @{$self->{displaytextsave}};
    pop @{$self->{speechtextsave}};
    $self->{text}->SetValue($self->RetrieveText);
	$self->{text}->SetStyle(0, length($self->{text}->GetValue), $self->{ta});
}

sub SpeechRetrieveText
{
    my $self = shift;
    return join('', @{$self->{speechtextsave}});
}
    
1;

__END__

=pod

=head1 NAME

AAC::Pvoice::Panel - The base where a pVoice application consists of

=head1 SYNOPSIS

  use AAC::Pvoice::Panel;



=head1 DESCRIPTION



=head1 USAGE

=head2 new(parent, id, size, position, style, disabletextrow)

This is the constructor for a new AAC::Pvoice::Panel. The first 5 parameters are
equal to the parameters for a normal Wx::Panel, see the wxPerl documentation
for those parameters.

The last parameter, disabletextrow, is a boolean (1 or 0), which determines
if the text-input field at the bottom of the screen should be hidden or
not. Normally this inputfield will be shown (for an application like pVoice
this is normal, because that will contain the text the user is writing),
but for an application like pMusic this row is not nessecary, so it can be
disabled.

=head2 xsize

This returns the x-size of the panel in pixels.

=head2 ysize

This returns the y-size of the panel in pixels.

=head2 SelectColour

This returns the colour that indicates a selected row or selected item. 

=head2 BackgroundColour(colour)

This sets the normal backgroundcolour. It
takes a Wx::Colour (or a predefined colour constant) as a parameter.

=head2 AddTitle(title)

This method sets the title of the page and draws it on the AAC::Pvoice::Panel.
It uses the Comic Sans MS font at a size of 18pt.

=head2 Append(row, unselectable)

This method adds a row (AAC::Pvoice::Row or any subclass of Wx::Window) to
the panel. If this row shouldn't be selectable by the user, you should set
unselectable to 1. Omitting this parameter, or setting it to 0 makes the
row selectable.

=head2 Clear

This method clears the panel completely and destroys all objects on it.

=head2 Finalize

This method 'finalizes' the panel by creating the textinput row (if appliccable)
and setting up the selection of the first row. You always need to call
this method before being able to let the user interact with the pVoice panel.

=head2 Next

This method normally won't be called directly. It will highlight the 'next'
row (when we're in 'rowselection') or the next item inside a row (when
we're in 'columnselection')

=head2 Select

This method normally won't be called directly either. It will either 'select'
the row that is highlighted and thus go into columnselection, or, when we're
in columnselection, invoke the callback associated with that item and
go into rowselection again.

=head2 ToRowSelection

This method will remove the highlighting of an item (if nessecary) and highlight
the entire current row again and set rowselection back on.

=head2 DisplayAddText(text_

In pVoice-like applications there's a difference between 'displaytext' (which is
the text that the user actually is writing and which should be displayed on the
textrow) and the speech (phonetical) text (which is not displayed, but -if nessecary-
differs from the text as we would write it, so a speechsynthesizer sounds
better.

This method adds text to the displaytext. It is saved internally and displayed
on the textrow

=head2 SpeechAddText(text)

This method add text to the speechtext. It is saved internally and not displayed
on the textrow. See DisplayAddText for more information.

=head2 RetrieveText

This method returns the text that is added to the Displaytext since the
last 'ClearText'.

=head2 SpeechRetrieveText

This method returns the text that is added to the Speechtext since the
last 'ClearText'.

=head2 ClearText

This method clears both the displaytext and the speechtext. It also updates
the textrow to show nothing.

=head2 BackspaceText

This method removes the last text added to the speech *and* displaytext.
Make sure that both speechtext and displaytext have the same amount of
text added, because it just pops off the last item from both lists and
updates the textrow.

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
