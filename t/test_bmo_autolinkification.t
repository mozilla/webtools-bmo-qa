use strict;
use warnings;
use lib qw(lib);

use Test::More "no_plan";

use QA::Util;

my ($sel, $config) = get_selenium();

log_in($sel, $config, 'unprivileged');
file_bug_in_product($sel, 'TestProduct');
my $bug_summary = "linkification test bug";
$sel->type_ok("short_desc", $bug_summary);
# $sel->type_ok("comment", "crash report: bp-63f096f7-253b-4ee2-ae3d-8bb782090824\ncve: CVE-2010-2884\nsvn: r12345");
$sel->type_ok("comment", "linkification test");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/\d+ \S $bug_summary/, "Bug created");
my $bug_id = $sel->get_value("//input[\@name='id' and \@type='hidden']");

$sel->type_ok("comment", "bp-63f096f7-253b-4ee2-ae3d-8bb782090824");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/\d+ \S $bug_summary/, "crash report added");
$sel->click_ok("link=bug $bug_id");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->attribute_is('link=bp-63f096f7-253b-4ee2-ae3d-8bb782090824@href', 'https://crash-stats.mozilla.com/report/index/63f096f7-253b-4ee2-ae3d-8bb782090824'); 

$sel->type_ok("comment", "CVE-2010-2884");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/\d+ \S $bug_summary/, "cve added");
$sel->click_ok("link=bug $bug_id");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->attribute_is('link=CVE-2010-2884@href', 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2010-2884'); 

$sel->type_ok("comment", "r12345");
$sel->click_ok("commit");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/\d+ \S $bug_summary/, "svn revision added");
$sel->click_ok("link=bug $bug_id");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->attribute_is('link=r12345@href', 'https://viewvc.svn.mozilla.org/vc?view=rev&revision=12345'); 

logout($sel);

