#!/usr/bin/perl
# stats_server.pl — tiny internal stats server for the mtproto-proxy container.
# Listens on the Railway private network only (no public domain is attached
# to this port). Serves the proxy's active-connection count and traffic
# counters, read from /proc/net/tcp and /proc/net/dev.
#
#   GET /stats   -> {"inbound":N,"rx":R,"tx":T}
#   GET /health  -> {"ok":true}
#
# Uses only Perl core modules (IO::Socket::INET), so it runs on the
# official proxy image (Debian 8, no python) with nothing to install.
use strict;
use warnings;
use IO::Socket::INET;

my $PORT = $ENV{STATS_PORT} || 8080;

my $server = IO::Socket::INET->new(
    LocalAddr => '0.0.0.0',
    LocalPort => $PORT,
    Proto     => 'tcp',
    Listen    => 5,
    ReuseAddr => 1,
) or die "stats_server: cannot listen on $PORT: $!\n";

print "stats_server listening on 0.0.0.0:$PORT\n";

while (my $client = $server->accept()) {
    $client->autoflush(1);
    my $request = <$client>;
    # Consume request headers up to the blank line.
    while (my $line = <$client>) {
        last if $line =~ /^\r?\n$/;
    }
    my $path = '/';
    if (defined $request && $request =~ /^GET\s+(\S+)/) {
        $path = $1;
    }
    my ($code, $body);
    if ($path eq '/stats') {
        $body = stats_json();
        $code = 200;
    } elsif ($path eq '/health') {
        $body = '{"ok":true}';
        $code = 200;
    } else {
        $body = '{"error":"not found"}';
        $code = 404;
    }
    my $resp = "HTTP/1.1 $code OK\r\n"
        . "Content-Type: application/json\r\n"
        . "Content-Length: " . length($body) . "\r\n"
        . "Connection: close\r\n\r\n" . $body;
    print $client $resp;
    close $client;
}

sub stats_json {
    my $inbound = 0;
    if (open my $fh, '<', '/proc/net/tcp') {
        while (<$fh>) {
            my @f = split;
            next unless @f >= 4 && $f[0] =~ /^\d+:$/;
            if ($f[1] =~ /:01BB$/i && $f[3] eq '01') {
                $inbound++;
            }
        }
        close $fh;
    }
    my ($rx, $tx) = (0, 0);
    if (open my $fh, '<', '/proc/net/dev') {
        while (<$fh>) {
            next unless /:/;
            my ($name, $rest) = split /:/, $_, 2;
            $name =~ s/^\s+|\s+$//g;
            next if $name eq '' || $name eq 'lo' || $name eq 'Inter';
            my @n = split ' ', $rest;
            next unless @n >= 9;
            $rx += $n[0];
            $tx += $n[8];
        }
        close $fh;
    }
    return "{\"inbound\":$inbound,\"rx\":$rx,\"tx\":$tx}";
}
