use strict;
use warnings;
use Test::WWW::Selenium;
use Test::More "no_plan";

my $conf_file = "../config/selenium_test.conf";

# read the test configuration file
my $config = do "$conf_file"
    or die "can't read configuration '$conf_file': $!$@";

my $sel = Test::WWW::Selenium->new(
    host        => $config->{host},
    browser     => $config->{browser},
    browser_url => $config->{browser_url}
);

$sel->open_ok("/$config->{bugzilla_installation}/");
$sel->type_ok("Bugzilla_login", $config->{admin_user_login}, "Enter admin login name");
$sel->type_ok("Bugzilla_password", $config->{admin_user_passwd}, "Enter admin password");
$sel->click_ok("log_in", undef, "Submit credentials");
$sel->wait_for_page_to_load(30000);
$sel->click_ok("link=Administration", undef, "Go to the Admin page");
$sel->wait_for_page_to_load(30000);
$sel->title_like(qr/^Administer your installation/, "Display admin.cgi");
$sel->click_ok("link=Sanity Check", undef, "Go to Sanity Check (no parameter)");
$sel->wait_for_page_to_load(30000);
$sel->title_is("Sanity Check", "Display sanitycheck.cgi");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?rebuildvotecache=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with rebuildvotecache=1");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?createmissinggroupcontrolmapentries=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with createmissinggroupcontrolmapentries=1");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?repair_creation_date=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with repair_creation_date=1");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?repair_bugs_fulltext=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with repair_bugs_fulltext=1");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?rescanallBugMail=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with rescanallBugMail=1");
$sel->is_text_present_ok("found with possibly unsent mail", undef, "Look for unsent bugmail");
# sanitycheck.cgi always stops after looking for unsent bugmail. So we cannot rely on
# "Sanity check completed." to determine if an error has been thrown or not.
ok(!$sel->is_text_present("Software error"), "No error thrown");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?remove_invalid_bug_references=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with remove_invalid_bug_references=1");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?remove_invalid_attach_references=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with remove_invalid_attach_references=1");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?rebuildkeywordcache=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with rebuildkeywordcache=1");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?remove_old_whine_targets=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with remove_old_whine_targets=1");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");
$sel->open_ok("/$config->{bugzilla_installation}/sanitycheck.cgi?repair_bugs_fulltext=1");
$sel->title_is("Sanity Check", "Call sanitycheck.cgi with repair_bugs_fulltext=1");
$sel->is_text_present_ok("Sanity check completed.", undef, "Page displayed correctly");