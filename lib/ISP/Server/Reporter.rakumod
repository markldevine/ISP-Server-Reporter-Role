unit role ISP::Server::Reporter:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use ISP::Server::Reporter::Field;
use ISP::dsmadmc;
use Our::Grid;
use Our::Utilities;
#use Prettier::Table;

has DateTime    $.first-iteration;

has Str:D       $.isp-server                        is required;
has Str:D       $.isp-admin                         is required;
has Int:D       $.interval                          = 58;
has Int:D       $.count                             = 1;
has Bool        $.clear;

has Our::Grid   $.grid;
has             $.title                             is required;
has             @.command                           is required;
has             @.fields                            is required;
has             %.align;
has Str         $.sort-by;

has Int         $.seconds-offset-UTC;

method process-rows (Str:D $) { ... }

method loop () {
    my $delay       = self.interval;
    my $counter     = self.count;
    my $infinity    = False;
    if $counter == 0 {
        $infinity   = True;
        $counter++;
    }
    $delay          = 5         if $delay < 5;
    my $dsmadmc     = ISP::dsmadmc.new(:$!isp-server, :$!isp-admin);
    $!seconds-offset-UTC = $dsmadmc.seconds-offset-UTC;
    $!first-iteration = DateTime(now);
    repeat {
        my @records = $dsmadmc.execute(self.command);
        return Nil  unless @records.elems;
        my $time    = ' [' ~ DateTime(now).local.hh-mm-ss;
        $time      ~= ' every ' ~ $!interval if $counter > 1 || $infinity;
        if $infinity {
            $time  ~= "\x[221E]";
        }
        elsif $counter > 1 {
            $time  ~= "\x[02E3]" ~ integer-to-superscript($counter - 1);
        }
        $time      ~= ' seconds' if $counter > 1 || $infinity;
        $time      ~= ']';
        $!grid .= new: :title(self.title ~ ' ' ~ $time);
        self.process-rows(@records);
        run '/usr/bin/clear'    if self.clear;
        $!grid.ANSI-print;
        --$counter              unless $infinity;
        sleep self.interval     if self.interval && $counter;
    } until $counter < 1;
}

=finish
