use strict;
use warnings;

use Test::More tests => 12;

# Start the Xvfb server first
my ($pid, $display) = xserver_start();
ok($pid && $display, "X Server started with PID $pid on display :$display");
ok(open(XPID, ">testing.x.pid"), "Opening testing.x.pid");
ok((print XPID $pid), "Writing testing.x.pid");
ok(close(XPID),  "Closing testing.x.pid");

# Start the VNC service second
ok($pid = vnc_start($display), "VNC desktop started with PID $pid");
ok(open(VNCPID, ">testing.vnc.pid"), "Opening testing.vnc.pid");
ok((print VNCPID $pid), "Writing testing.vnc.pid");
ok(close(VNCPID),  "Closing testing.vnc.pid");

# Start the selenium server third
ok($pid = selenium_start($display), "Selenium RC server started with PID $pid");
ok(open(SPID, ">testing.selenium.pid"), "Opening testing.selenium.pid");
ok((print SPID $pid), "Writing testing.selenium.pid");
ok(close(SPID),  "Closing testing.selenium.pid");

sleep(10);

# Subroutines

sub xserver_start {
    my $pid;
    foreach my $display (1..3) {
        my @x_cmd = qw(Xvfb -ac -screen 0 1600x1200x24 -fbdir /tmp);
        push(@x_cmd, ":$display");
        $pid = fork();
        if (!$pid) {
            open(STDOUT, ">/dev/null");
            open(STDERR, ">/dev/null");
            exec(@x_cmd) || die "unable to execute: $!";
        }
        else {
            return ($pid, $display);
        }
    }
    return 0;
}

sub vnc_start {
    my $display = shift;
    my @vnc_cmd = qw(x11vnc -viewonly -forever -nopw -quiet -display);
    push(@vnc_cmd, ":$display");
    my $pid = fork();
    if (!$pid) {
        open(STDOUT, ">/dev/null");
        open(STDERR, ">/dev/null");
        exec(@vnc_cmd) || die "unabled to execute: $!";
    }
    return $pid;
}

sub selenium_start {
    my $display = shift;
    my @selenium_cmd = qw(java -jar ../config/selenium-server-standalone.jar
                               -firefoxProfileTemplate ../config/firefox
                               -log ../config/selenium.log);
    unshift(@selenium_cmd, "env", "DISPLAY=:$display");
    my $pid = fork();
    if (!$pid) {
        open(STDOUT, ">/dev/null");
        open(STDERR, ">/dev/null");
        exec(@selenium_cmd) || die "unable to execute: $!";
    }
    return $pid;
}
