unit role ISP::Server::Reporter:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use ISP::Server::Reporter::Field;
use ISP::dsmadmc;
use Prettier::Table;

has Str:D   $.isp-server                        is required;
has Str:D   $.isp-admin                         is required;
has Int:D   $.interval                          = 58;
has Int:D   $.count                             = 1;
has Bool    $.grid;
has Bool    $.clear;

has         $.table;
has         $.title                             is required;
has         @.command                           is required;
has         @.fields                            is required;
has         %.align;

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
    my @field-names;
    my %align;
    for @!fields -> $field {
        @field-names.push:      $field.name;
        %!align{$field.name}    = $field.alignment;
    }
    repeat {
        my @records = $dsmadmc.execute(self.command);
        return Nil  unless @records.elems;
        $!table = Prettier::Table.new: :title(self.title ~ ' [' ~ DateTime(now).local.hh-mm-ss ~ ']'), :@field-names, :%!align;
        $!table.hrules(Prettier::Table::Constrains::ALL) if self.grid;
        self.process-rows(@records);
        run '/usr/bin/clear'    if self.clear;
        $!table.put;
        --$counter              unless $infinity;
        sleep self.interval     if self.interval && $counter;
    } until $counter < 1;
}

=finish
