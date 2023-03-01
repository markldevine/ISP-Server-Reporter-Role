unit role ISP::Server::Reporter:api<1>:auth<Mark Devine (mark@markdevine.com)>;

use ISP::Server::Reporter::Field;
use ISP::dsmadmc;
use Prettier::Table;

my @SUB-DIGITS;
@SUB-DIGITS[0]    = "\x[2080]";
@SUB-DIGITS[1]    = "\x[2081]";
@SUB-DIGITS[2]    = "\x[2082]";
@SUB-DIGITS[3]    = "\x[2083]";
@SUB-DIGITS[4]    = "\x[2084]";
@SUB-DIGITS[5]    = "\x[2085]";
@SUB-DIGITS[6]    = "\x[2086]";
@SUB-DIGITS[7]    = "\x[2087]";
@SUB-DIGITS[8]    = "\x[2088]";
@SUB-DIGITS[9]    = "\x[2089]";

my @SUPER-DIGITS;
@SUPER-DIGITS[0]    = "\x[2070]";
@SUPER-DIGITS[1]    = "\x[00B9]";
@SUPER-DIGITS[2]    = "\x[00B2]";
@SUPER-DIGITS[3]    = "\x[00B3]";
@SUPER-DIGITS[4]    = "\x[2074]";
@SUPER-DIGITS[5]    = "\x[2075]";
@SUPER-DIGITS[6]    = "\x[2076]";
@SUPER-DIGITS[7]    = "\x[2077]";
@SUPER-DIGITS[8]    = "\x[2078]";
@SUPER-DIGITS[9]    = "\x[2079]";

sub int-to-superscript (Int:D $i) {
    my $accumulator = '';
    for $i.Int.comb -> $c {
        $accumulator ~= @SUPER-DIGITS[$c.Int];
    }
    return $accumulator;
}

sub int-to-subscript (Int:D $i) {
    my $accumulator = '';
    for $i.Int.comb -> $c {
        $accumulator ~= @SUB-DIGITS[$c.Int];
    }
    return $accumulator;
}

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
has Str     $.sort-by;

has Int     $.seconds-offset-UTC;

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
    my @field-names;
    my %align;
    for @!fields -> $field {
        @field-names.push:      $field.name;
        %!align{$field.name}    = $field.alignment;
    }
    $!sort-by       = @!fields[0].name unless $!sort-by;
    repeat {
        my @records = $dsmadmc.execute(self.command);
        return Nil  unless @records.elems;
        my $time    = ' [' ~ DateTime(now).local.hh-mm-ss;
        $time      ~= ' every ' ~ $!interval if $counter > 1 || $infinity;
        if $infinity {
            $time  ~= "\x[221E]";
        }
        elsif $counter > 1 {
            $time  ~= "\x[02E3]" ~ int-to-superscript($counter - 1);
        }
        $time      ~= ' seconds' if $counter > 1 || $infinity;
        $time      ~= ']';
        $!table = Prettier::Table.new: :title(self.title ~ ' ' ~ $time), :@field-names, :%!align, :$!sort-by;
        $!table.hrules(Prettier::Table::Constrains::ALL) if self.grid;
        self.process-rows(@records);
        run '/usr/bin/clear'    if self.clear;
        $!table.put;
        --$counter              unless $infinity;
        sleep self.interval     if self.interval && $counter;
    } until $counter < 1;
}

=finish
