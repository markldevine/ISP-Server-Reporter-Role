unit role ISP::Server::Reporter:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use ISP::dsmadmc;
use Our::Grid;
use Our::Utilities;

has DateTime    $.first-iteration;

has Str:D       $.isp-server                        is required;
has Str:D       $.isp-admin                         is required;
has Int:D       $.interval                          = 58;
has Int:D       $.count                             = 1;
has Bool        $.cache;
has Bool        $.clear;
has Our::Grid   $.grid;
has             $.title                             is required;
has             @.command                           is required;
has             @.sort-columns;
has Bool        $.tui;
has Bool        $.csv;
has Bool        $.gui;
has Bool        $.html;
has Bool        $.json;
has Bool        $.text;
has Bool        $.tui;
has Bool        $.xml;

has Int         $.seconds-offset-UTC;

submethod TWEAK {
    $!grid     .= new;
    self.process-headings;
}
method process-headings (Str:D $) { ... }
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
    my $dsmadmc     = ISP::dsmadmc.new(:$!isp-server, :$!isp-admin, :$!cache);
    $!seconds-offset-UTC = $dsmadmc.seconds-offset-UTC;
    $!first-iteration = DateTime(now);
    repeat {
        my @records = $dsmadmc.execute(self.command);
        return Nil  unless @records.elems;
        my $time    = ' [' ~ DateTime(now).local.hh-mm-ss;
        $time      ~= ' every ' ~ $!interval if $counter > 1 || $infinity;
        if $infinity {
            $time  ~= ouc-infinity.value;
        }
        elsif $counter > 1 {
            $time  ~= ouc-superscript-x ~ integer-to-superscript($counter - 1);
        }
        $time      ~= ' seconds' if $counter > 1 || $infinity;
        $time      ~= ']';
        $!grid.title(self.title ~ ' ' ~ $time);
        self.process-rows(@records);
        run '/usr/bin/clear'    if self.clear;
        $!grid.sort-by-columns(:@!sort-columns) if @!sort-columns.elems;
        {
            when    $!csv   { $grid.csv-print   }
            when    $!gui   { $grid.GUI         }
            when    $!html  { $grid.html-print  }
            when    $!json  { $grid.json-print  }
            when    $!text  { $grid.TEXT-print  }
            when    $!tui   { $grid.TUI         }
            when    $!xml   { $grid.xml-print   }
            default         { $grid.ANSI-print  }
        }
        $!grid     .= new;
        self.process-headings;
        --$counter              unless $infinity;
        sleep self.interval     if self.interval && $counter;
    } until $counter < 1;
}

=finish
