#!/usr/bin/env raku

use lib '/home/mdevine/github.com/ISP-Server-Reporter-Role/lib';
use ISP::Server::Reporter;

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

class Reporter does ISP::Server::Reporter {

    has $.detailed;
    has $.client-name;

    method process-rows (@sessions) {
        my Str      $session-number;                                        ##                Sess Number: 29,057
        my Str      $communication-method;                                  ##               Comm. Method: SSL
        my Str      $session-state;                                         ##                 Sess State: RecvW
        my Str      $wait-time;                                             ##                  Wait Time: 0 S
        my Str      $bytes-sent;                                            ##                 Bytes Sent: 18.8 K
        my Str      $bytes-received;                                        ##                Bytes Recvd: 11.1 G
        my Str      $session-type;                                          ##                  Sess Type: Node
        my Str      $platform;                                              ##                   Platform: Linux x86-64
        my Str      $client-name;                                           ##                Client Name: SAMPLE_NODE
        my Str      $media-access-status;                                   #         Media Access Status: 
        my Str      $user-name;                                             #                   User Name:
        my DateTime $date-time-first-data-sent;                             #   Date/Time First Data Sent: 02/03/23   10:52:07
        my Str      $proxy-by-storage-agent;                                #      Proxy By Storage Agent:
        my Str      $actions;                                               #                     Actions: BkIns FSUpd
        my Str      $failover-mode;                                         #               Failover Mode: No

        my $row;
        for @sessions -> $session {
            $client-name                    = Nil;  $client-name            = $session{'Client Name'}.Str               if $session{'Client Name'};
            if self.client-name {
                next unless self.client-name.fc eq $client-name.fc;
            }
            $session-number                 = Nil;  $session-number         = $session{'Sess Number'}.Str               if $session{'Sess Number'};
            $communication-method           = Nil;  $communication-method   = $session{'Comm. Method'}.Str              if $session{'Comm. Method'};
            $session-state                  = Nil;  $session-state          = $session{'Sess State'}.Str                if $session{'Sess State'};
            $wait-time                      = Nil;  $wait-time              = $session{'Wait Time'}.Str                 if $session{'Wait Time'};
            $bytes-sent                     = Nil;  $bytes-sent             = $session{'Bytes Sent'}.Str                if $session{'Bytes Sent'};
            $bytes-received                 = Nil;  $bytes-received         = $session{'Bytes Recvd'}.Str               if $session{'Bytes Recvd'};
            $session-type                   = Nil;  $session-type           = $session{'Sess Type'}.Str                 if $session{'Sess Type'};
            $platform                       = Nil;  $platform               = $session{'Platform'}.Str                  if $session{'Platform'};
            $media-access-status            = Nil;  $media-access-status    = $session{'Media Access Status'}.Str       if $session{'Media Access Status'};
            $user-name                      = Nil;  $user-name              = $session{'User Name'}.Str                 if $session{'User Name'};
            $date-time-first-data-sent      = Nil;
            if $session{'Date/Time First Data Sent'} && $session{'Date/Time First Data Sent'} ~~ /<date-time-regex>/ {
                $date-time-first-data-sent  = DateTime.new(
                                                            :month($<date-time-regex><month>),
                                                            :day($<date-time-regex><day-of-month>),
                                                            :year($<date-time-regex><year> < 100 ?? +$<date-time-regex><year> + 2000 !! +$<date-time-regex><year>),
                                                            :hour($<date-time-regex><hour>),
                                                            :minute($<date-time-regex><minute>),
                                                            :second($<date-time-regex><second>),
                                                          );
            }
            $proxy-by-storage-agent         = Nil;  $proxy-by-storage-agent = $session{'Proxy By Storage Agent'}.Str    if $session{'Proxy By Storage Agent'};
            $actions                        = Nil;  $actions                = $session{'Actions'}.Str                   if $session{'Actions'};
            $failover-mode                  = Nil;  $failover-mode          = $session{'Failover Mode'}.Str             if $session{'Failover Mode'};
            $row                            = Array.new;
            $row.push:                      $session-number;
            $row.push:                      $communication-method;
            $row.push:                      $session-state;
            $row.push:                      $wait-time;
            $row.push:                      $bytes-sent;
            $row.push:                      $bytes-received;
            $row.push:                      $session-type;
            $row.push:                      $platform;
            $row.push:                      $client-name;
            $row.push:                      $media-access-status            if self.detailed;
            $row.push:                      $user-name                      if self.detailed;
            $row.push:                      $date-time-first-data-sent.Str  if self.detailed;
            $row.push:                      $proxy-by-storage-agent         if self.detailed;
            $row.push:                      $actions                        if self.detailed;
            $row.push:                      $failover-mode                  if self.detailed;
            self.table.add-row:             $row;
        }
    }
}

sub MAIN (
    Str:D   :$isp-server!,                          #= ISP server name
    Str:D   :$isp-admin!,                           #= ISP server name
    Int:D   :$interval      where * >= 5    = 58,   #= Refresh every --interval seconds (minimum 5s)
    Int:D   :$count                         = 1,    #= Number of refreshes (0 is infinity)
    Bool    :$grid,                                 #= Full table grid
    Bool    :$clear,                                #= Clear the screen with each iteration
    Bool    :$detailed,                             #= FORMAT=DETAILED
    Str     :$client-name,                          #= ISP CLIENT/NODE name
) {
    my @command     = ['QUERY', 'SESSION'];
    @command.push:  'FORMAT=DETAILED'   if $detailed;
    my @fields;
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Sess Number'),                  :alignment('r'));
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Comm. Method'),                 :alignment('c'));
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Sess State'),                   :alignment('c'));
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Wait Time'),                    :alignment('r'));
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Bytes Sent'),                   :alignment('r'));
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Bytes Recvd'),                  :alignment('r'));
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Sess Type'),                    :alignment('c'));
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Platform'),                     :alignment('c'));
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Client Name'),                  :alignment('l'));
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Media Access Status'),          :alignment('c'))    if $detailed;
    @fields.push:   ISP::Server::Reporter::Field.new(:name('User Name'),                    :alignment('c'))    if $detailed;
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Date/Time First Data Sent'),    :alignment('c'))    if $detailed;
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Proxy By Storage Agent'),       :alignment('c'))    if $detailed;
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Actions'),                      :alignment('c'))    if $detailed;
    @fields.push:   ISP::Server::Reporter::Field.new(:name('Failover Mode'),                :alignment('c'))    if $detailed;
    my $reporter    = Reporter.new(
                                    :$isp-server,
                                    :$isp-admin,
                                    :$count,
                                    :$grid,
                                    :$clear,
                                    :$interval,
                                    :title('IBM Spectrum Protect: ' ~ $isp-server ~ ' Sessions'),
                                    :@command,
                                    :@fields,
                                    :$detailed,
                                    :$client-name,
                                  );
    $reporter.loop;
}

=finish
