use strict;
use warnings;
use lib qw(lib);

use Test::More "no_plan";

use QA::Util;

my ($sel, $config) = get_selenium();

log_in($sel, $config, 'unprivileged');
file_bug_in_product($sel, 'TestProduct');
$sel->type_ok("short_desc", "linkification test bug");
# $sel->type_ok("comment", "crash report: bp-63f096f7-253b-4ee2-ae3d-8bb782090824\ncve: CVE-2010-2884\nsvn: r12345");
$sel->type_ok("comment", "linkification test");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $bug_id = $sel->get_value("//input[\@name='id' and \@type='hidden']");

$sel->type_ok("comment", "bp-63f096f7-253b-4ee2-ae3d-8bb782090824");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ processed/, "crash report added");
$sel->click_ok("link=bug $bug_id");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->attribute_is('link=bp-63f096f7-253b-4ee2-ae3d-8bb782090824@href', 'https://crash-stats.mozilla.com/report/index/63f096f7-253b-4ee2-ae3d-8bb782090824'); 

$sel->type_ok("comment", "CVE-2010-2884");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ processed/, "cve added");
$sel->click_ok("link=bug $bug_id");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->attribute_is('link=CVE-2010-2884@href', 'http://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-2884'); 

$sel->type_ok("comment", "r12345");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ processed/, "svn revision added");
$sel->click_ok("link=bug $bug_id");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->attribute_is('link=r12345@href', 'http://viewvc.svn.mozilla.org/vc?view=rev&revision=12345'); 

logout($sel);

