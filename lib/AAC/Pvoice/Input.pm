package AAC::Pvoice::Input;
use strict;
use warnings;

use Wx qw(:everything);
use Wx::Perl::Carp;
use Win32::API;
use Wx::Event qw(   EVT_LEFT_UP
                    EVT_RIGHT_UP
                    EVT_TIMER);
our $VERSION     = sprintf("%d.%02d", q$Revision: 1.2 $=~/(\d+)\.(\d+)/);

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self, $class;
    $self->{panel} = shift;

    # We get the configuration from the Windows registry
    # If it's not initialized, we provide some defaults
    $self->{panel}->{config} = Wx::ConfigBase::Get || croak "Can't get Config";

    $self->{panel}->{Device} = $self->{panel}->{config}->Read('Device',    'icon');
                               # icon   = mouse left/right buttons
                               # adremo = electric wheelchair adremo

    $self->{panel}->{ADREMO_PARPORT_MASK} = 0xff;  # to mask off the
                                                   # bits 0-3
    $self->{panel}->{PARPORT_ADDRESS}     = 0x378; # lpt1
    $self->{panel}->{Interval} = $self->{panel}->{config}->ReadInt('Interval', 10);
    # The event for the adremo device
    $self->{panel}->{timer} = Wx::Timer->new($self->{panel},my $tid = Wx::NewId());
    $self->{panel}->{timer}->Start($self->{panel}->{Interval}, 0); # 0 is continuous
    EVT_TIMER($self->{panel}, $tid, \&MonitorPort);

    return $self;
}

sub Next
{
    my $self = shift;
    my $sub = shift;
    $self->{next} = $sub;
    EVT_RIGHT_UP($self->{panel}, sub{return if $self->{panel}->{config}->Read('Device') ne 'icon'; &$sub});
}

sub Select
{
    my $self = shift;
    my $sub = shift;
    $self->{select} = $sub;
    EVT_LEFT_UP($self->{panel},sub {return if $self->{panel}->{config}->Read('Device') ne 'icon'; &$sub});
}

#----------------------------------------------------------------------
# This sub is used to monitor the parallel port for the adremo device
sub MonitorPort
{
    # BEWARE: $self is the AAC::Pvoice::Panel object the timer
    # belongs to!
    my ($self, $event) = @_;
    # do nothing if the device is not adremo or
    # if we're already running
    return if $self->{config}->Read('Device') eq 'icon';
    return if $self->{monitorrun};
    $self->{monitorrun} = 1;
    $self->{getportval} = Win32::API->new(  "inpout32", # dll
                                            "Inp32",    # function
                                            ["I"],      # Parameterlist
                                            "I")        # returnvalue
                            if not exists $self->{getportval};
    my $curvalue = ($self->{getportval}
                         ->Call($self->{PARPORT_ADDRESS}+1) &
                         # parportaddress is base address, one byte
                         # higher we find the statusbyte
                                $self->{ADREMO_PARPORT_MASK});
                         # we mask off the lower four bits
    if (not defined $curvalue)
    {
        $self->{monitorrun} = 0;
        return
    }
    $self->{lastvalue} = 0 if not exists $self->{lastvalue};
    if ($curvalue != $self->{lastvalue})
    {
        if ($curvalue == 0x38)
        {
            # 0x38 means a headmove to the right
            $self->{input}->{next}->()   if $self->{input}->{next};
        }
        if ($curvalue == 0xf8)
        {
            # 0xf8 means a headmove to the left
            $self->{input}->{select}->() if $self->{input}->{select};
        }
    }
    $self->{lastvalue} = $curvalue if $curvalue;
    $self->{monitorrun} = 0;
}

sub Quit
{
    my $self = shift;
    # stop the timer for the port monitor
    $self->{panel}->{timer}->Stop();
}

1;

__END__

=head1 NAME

AAC::Pvoice::Input - A class that handles the input that controls a pVoice-like application

=head1 SYNOPSIS

  # this module will normally not be called directly. It's called from
  # AAC::Pvoice::Panel by default


=head1 DESCRIPTION

=head2 new(panel)

This constructor takes the panel (AAC::Pvoice::Panel typically) on which
the events and timer will be called as a parameter.
If the configuration (read using Wx::ConfigBase::Get) has a key called
'Device' (which can be set to 'icon' or 'adremo') is set to 'adremo', it
will start polling the parallel port every x milliseconds, where x is the
value of the key 'Interval'. This setting is only useful if you connect
an "Adremo" electrical wheelchair to the parallel port of your PC. 

=Next(sub)

This method takes a coderef as parameter. This coderef will be invoked when
the 'Next' event happens.

If the Device (see 'new') is set to 'icon', and a right mousebutton is
clicked, a 'Next' event is generated.
If the Device is set to 'adremo' and the headsupport of the wheelchair
is moved to the right, that will also generate a 'Next' event.

=Select(sub)

This method takes a coderef as parameter. This coderef will be invoked when
the 'Select' event happens.

If the Device (see 'new') is set to 'icon', and a left mousebutton is
clicked, a 'Select' event is generated.
If the Device is set to 'adremo' and the headsupport of the wheelchair
is moved to the left, that will also generate a 'Select' event.

=Quit

This method will stop the timer that monitors the parallel port.

=head1 USAGE


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

