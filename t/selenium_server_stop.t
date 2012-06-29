use strict;
use warnings;

use Test::More tests => 15;

my $pid;

# Stop the selenium server first
ok(open(SPID, "<testing.selenium.pid"), "Opening testing.selenium.pid");
ok(($pid = <SPID>), "Reading testing.selenium.pid");
ok(close(SPID), "Closing testing.selenium.pid");
ok(kill(9, $pid), "Killing process $pid");
ok(unlink("testing.selenium.pid"), "Removing testing.selenium.pid");

# Stop the VNC service second
ok(open(VNCPID, "<testing.vnc.pid"), "Opening testing.vnc.pid");
ok(($pid = <VNCPID>), "Reading testing.vnc.pid");
ok(close(VNCPID), "Closing testing.vnc.pid");
ok(kill(9, $pid), "Killing process $pid");
ok(unlink("testing.vnc.pid"), "Removing testing.vnc.pid");

# Stop the Xvfb server third
ok(open(XPID, "<testing.x.pid"), "Opening testing.x.pid");
ok(($pid = <XPID>), "Reading testing.x.pid");
ok(close(XPID),  "Closing testing.x.pid");
ok(kill(9, $pid), "Killing process $pid");
ok(unlink("testing.x.pid"), "Removing testing.x.pid");
