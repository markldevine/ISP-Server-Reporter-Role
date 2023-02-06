unit role ISP::Server::Reporter:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use Hash::Ordered;
use ISP::dsmadmc;
use Prettier::Table;

my regex date-time-regex    {
                                ^
                                $<month>        = (\d\d)
                                '/'
                                $<day-of-month> = (\d\d)
                                '/'
                                $<year>         = (\d+)
                                \s+
                                $<hour>         = (\d\d)
                                ':'
                                $<minute>       = (\d\d)
                                ':'
                                $<second>       = (\d\d)
                                $
                            }

has Str:D   $.isp-server        is required;
has Str:D   $.isp-admin         is required;
has Int:D   $.interval                          = 58;
has Int:D   $.count                             = 1;
has Bool    $.grid;
has Bool    $.clear;

has         $.title             is required;
has         @.command           is required;
has         %.fields            does Hash::Ordered;

method load-fields (Str:D @fields) {
    for @fields -> $field {
        %!fields{$field} = 0;
    }
    die unless %!fields.elems;
}

method align-fields () { ... }

method process-rows () { ... }

method loop () {
    my $delay       = self.interval;
    my $counter     = self.count;
    my $infinity    = False;
    if $counter == 0 {
        $infinity   = True;
        $counter++;
    }
    $delay          = 5                 if 0 < $delay < 5;
    my $dsmadmc     = ISP::dsmadmc.new(:$!isp-server, :$!isp-admin);
    my $table;
    repeat {
        my @records = $dsmadmc.execute(self.command);
        return Nil  unless @records.elems;

        $table = Prettier::Table.new:
            title => 'IBM Spectrum Protect: ' ~ $!isp-server ~ ' Sessions [' ~ DateTime(now).local.hh-mm-ss ~ ']',
            field-names => self.fields.keys,
            align       => self.fields.kv,
        ;
        $table.hrules(Prettier::Table::Constrains::ALL) if self.grid;
        self.process-rows(@records);
        run '/usr/bin/clear'                if self.clear;
        put $table;
        --$counter                          unless $infinity;
        sleep self.interval                 if self.interval && $counter;
    } until $counter < 1;
}

=finish
