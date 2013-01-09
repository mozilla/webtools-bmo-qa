use strict;
use warnings;
use lib qw(lib);

use Test::More "no_plan";

use QA::Util;

my ($sel, $config) = get_selenium();

log_in($sel, $config, 'admin');
set_parameters($sel, { "Bug Fields" => {"useclassification-off" => undef} });

# mktgevent and swag are dependent so we create the mktgevent bug first so 
# we can provide the bug id to swag

# mktgevent

_check_product('Marketing');
_check_component('Marketing', 'Event Requests');
_check_component('Marketing', 'Swag Requests');
_check_component('Marketing', 'Trademark Permissions');
_check_group('mozilla-corporation-confidential');

# FIXME figure out how to use format= with file_bug_in_product

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=Marketing&format=mktgevent");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Event Request Form", "Open custom bug entry form - mktgevent");
$sel->type_ok("firstname", "Bugzilla", "Enter first name");
$sel->type_ok("lastname", "Administrator", "Enter last name");
$sel->type_ok("email", $config->{'admin_user_login'}, "Enter email address");
$sel->type_ok("eventname", "Event Name", "Enter event name");
$sel->type_ok("website", $config->{'browser_url'}, "Enter web site");
$sel->type_ok("goals", "Goals for the event", "Enter goals");
$sel->type_ok("date", "2032/01/01", "Enter date");
$sel->type_ok("successmeasure", "Success Measure", "Enter measure of success");
$sel->click_ok("doing", "value=Other", "Select what doing");
$sel->type_ok("doing-other-what", "What will you be doing at the event", "Enter other what doing");
$sel->select_ok("attendees", "value=1-99", "Select number of attendees");
$sel->select_ok("audience", "value=Contributors", "Select targeted audience");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $mktgevent_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

# swag

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=Marketing&format=swag");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Swag Request Form", "Open custom bug entry form - swag");
$sel->type_ok("firstname", "Bugzilla", "Enter first name");
$sel->type_ok("lastname", "Administrator", "Enter last name");
$sel->type_ok("dependson", $mktgevent_bug_id, "Enter event request bug id");
$sel->type_ok("email", $config->{'admin_user_login'}, "Enter email address");
$sel->type_ok("cc", $config->{'unprivileged_user_login'}, "Enter cc address");
$sel->type_ok("additional", "Specific swag needed", "Enter specific swag needed");
$sel->type_ok("shiptofirstname", "Bugzilla", "Enter ship to first name");
$sel->type_ok("shiptolastname", "Administrator", "Enter ship to last name");
$sel->type_ok("shiptoaddress", "100 Some Street", "Enter ship to address");
$sel->type_ok("shiptoaddress2", "Suite 200", "Enter ship to address 2");
$sel->type_ok("shiptocity", "Mountain View", "Enter ship to city");
$sel->type_ok("shiptostate", "California", "Enter ship to state");
$sel->type_ok("shiptocountry", "USA", "Enter ship to country");
$sel->type_ok("shiptopcode", "94041", "Enter ship to postal code");
$sel->type_ok("shiptophone", "1-800-555-1212", "Enter ship to phone");
$sel->type_ok("shiptoidrut", "What is this?", "Enter ship to personal id/rut");
$sel->type_ok("comment", "--- Bug created by Selenium ---", "Enter bug description");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $swag_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

# trademark 

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=Marketing&format=trademark");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Trademark Usage Requests", "Open custom bug entry form - trademark");
$sel->type_ok("short_desc", "Bug created by Selenium", "Enter bug summary");
$sel->type_ok("comment", "--- Bug created by Selenium ---", "Enter bug description");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $trademark_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

# itrequest

_check_product('mozilla.org', 'other');
_check_component('mozilla.org', 'Server Operations');
_check_component('mozilla.org', 'Server Operations: Desktop Issues');

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=mozilla.org&format=itrequest");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Mozilla Corporation/Foundation IT Requests", "Open custom bug entry form - itrequest");
$sel->select_ok("bug_severity", "value=blocker", "Select request urgency");
$sel->click_ok("componentso", "Select request type");
$sel->type_ok("cc", $config->{'unprivileged_user_login'}, "Enter cc address");
$sel->type_ok("short_desc", "Bug created by Selenium", "Enter request summary");
$sel->type_ok("comment", "--- Bug created by Selenium ---", "Enter request description");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $itrequest_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

# brownbag 

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=mozilla.org&format=brownbag");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Mozilla Corporation Brownbag Requests", "Open custom bug entry form - brownbag");
$sel->type_ok("presenter", "Bugzilla Administrator", "Enter presenter");
$sel->type_ok("topic", "Automated testing of Bugzilla", "Enter topic");
$sel->type_ok("date", "01/01/2012", "Enter date");
$sel->select_ok("time_hour", "value=1", "Select hour");
$sel->select_ok("time_minute", "value=30", "Select minute");
$sel->select_ok("ampm", "value=PM", "Select am/pm");
$sel->select_ok("audience", "value=Employees Only", "Select audience");
$sel->check_ok("airmozilla", "Select need airmozilla");
$sel->check_ok("dialin", "Select need dial in");
$sel->check_ok("archive", "Select need to be archived");
$sel->check_ok("ithelp", "Select need it help");
$sel->type_ok("cc", $config->{'unprivileged_user_login'}, "Enter cc address");
$sel->type_ok("description", "--- Bug created by Selenium ---", "Enter request description");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $brownbag_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

# presentation

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=mozilla.org&format=presentation");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Mozilla Corporation Mountain View Presentation Request", "Open custom bug entry form - presentation");
$sel->type_ok("presenter", "Bugzilla Administrator", "Enter presenter");
$sel->type_ok("topic", "Automated testing of Bugzilla", "Enter topic");
$sel->type_ok("date", "01/01/2012", "Enter date");
$sel->select_ok("time_hour", "value=1", "Select hour");
$sel->select_ok("time_minute", "value=30", "Select minute");
$sel->select_ok("ampm", "value=PM", "Select am/pm");
$sel->select_ok("audience", "value=Employees Only", "Select audience");
$sel->check_ok("airmozilla", "Select need airmozilla");
$sel->check_ok("dialin", "Select need dial in");
$sel->check_ok("archive", "Select need to be archived");
$sel->check_ok("ithelp", "Select need it help");
$sel->type_ok("cc", $config->{'unprivileged_user_login'}, "Enter cc address");
$sel->type_ok("description", "--- Bug created by Selenium ---", "Enter request description");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $presentation_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

_check_component('mozilla.org', 'Discussion Forums');
_check_group('infra');

#mozlist

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=mozilla.org&format=mozlist");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Mozilla Discussion Forum / Mailing List Requests", "Open custom bug entry form - mozlist");
$sel->type_ok("listName", "test-list", "Enter name for mailing list");
$sel->click_ok("listType", "value=mozilla.org", "Select type of mailing list");
$sel->type_ok("listAdmin", $config->{'admin_user_login'}, "Enter list administator");
$sel->type_ok("cc", $config->{'unprivileged_user_login'}, "Enter cc address");
$sel->check_ok("name=groups", "value=infra", "Select private group");
$sel->type_ok("comment", "--- Bug created by Selenium ---", "Enter bug description");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $mozlist_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

_check_product('Mozilla PR');
_check_component('Mozilla PR', 'China - AMO');
_check_group('mozilla-confidential');

#mozpr

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=Mozilla PR&format=mozpr");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Create a PR Request", "Open custom bug entry form - mozpr");
$sel->select_ok("location", "value=China", "Select location");
$sel->select_ok("component", "value=China - AMO", "Select component");
$sel->select_ok("fakecomp", "value=AMO", "Select fake component");
$sel->type_ok("cc", $config->{'unprivileged_user_login'}, "Enter cc address");
$sel->type_ok("short_desc", "Bug created by Selenium", "Enter bug summary");
$sel->type_ok("comment", "--- Bug created by Selenium ---", "Enter bug description");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $mozpr_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

# legal

_check_product('Legal');
_check_component('Legal', 'Canonical');
_check_component('Legal', 'Copyright');

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=Legal&format=legal");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Mozilla Corporation Legal Requests", "Open custom bug entry form - legal");
$sel->select_ok("component", "value=Canonical", "Select request type");
$sel->select_ok("bug_severity", "value=blocker", "Select request urgency");
$sel->type_ok("firstresp", "First response", "Enter first response");
$sel->select_ok("firstrespwhen", "value=24 hours", "Select first response when");
$sel->type_ok("short_desc", "Bug created by Selenium", "Enter request summary");
$sel->type_ok("cc", $config->{'unprivileged_user_login'}, "Enter cc address");
$sel->type_ok("otherparty", "Other party", "Enter other party");
$sel->type_ok("busobj", "Business objective", "Enter business objective");
$sel->type_ok("comment", "--- Bug created by Selenium ---", "Enter request description");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $legal_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

# poweredby

_check_product('Websites', 'other');
_check_component('Websites', 'www.mozilla.org');
_check_group('marketing-private');

$sel->open_ok("/$config->{bugzilla_installation}/enter_bug.cgi?product=Websites&format=poweredby");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_is("Powered by Mozilla Logo Requests", "Open custom bug entry form - poweredby");
$sel->type_ok("short_desc", "Bug created by Selenium", "Enter bug summary");
$sel->type_ok("comment", "--- Bug created by Selenium ---", "Enter bug description");
$sel->click_ok("commit", undef, "Submit bug data to post_bug.cgi");
$sel->wait_for_page_to_load_ok(WAIT_TIME);
$sel->title_like(qr/Bug \d+ Submitted/, "Bug created");
my $poweredby_bug_id = $sel->get_value('//input[@name="id" and @type="hidden"]');

set_parameters($sel, { "Bug Fields" => {"useclassification-on" => undef} });
logout($sel);

sub _check_product {
    my ($product, $version) = @_;

    go_to_admin($sel);
    $sel->click_ok("link=Products");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Select product");

    my $product_description = "$product Description";

    my $text = trim($sel->get_text("bugzilla-body"));
    if ($text =~ /$product_description/) {
        # Product exists already
        return 1;
    }

    $sel->click_ok("link=Add");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Add Product");
    $sel->type_ok("product", $product);
    $sel->type_ok("description", $product_description);
    $sel->type_ok("version", $version) if $version;
    $sel->click_ok("//input[\@value='Add']");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $text = trim($sel->get_text("message"));
    ok($text =~ /You will need to add at least one component before anyone can enter bugs against this product/, 
       "Display a reminder about missing components");

    return 1;
}

sub _check_component {
    my ($product, $component) = @_;

    go_to_admin($sel);
    $sel->click_ok("link=components");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Edit components for which product?");
    
    $sel->click_ok("link=$product");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Select component of product '$product'");
    
    my $component_description = "$component Description";

    my $text = trim($sel->get_text("bugzilla-body"));
    if ($text =~ /$component_description/) {
        # Component exists already
        return 1;
    }

    # Add the watch user for component watching
    my $watch_user = lc $component . "@" . lc $product . ".bugs";
    $watch_user =~ s/\s+/\-/g;

    go_to_admin($sel);
    $sel->click_ok("link=Users");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is('Search users');
    $sel->click_ok('link=add a new user');
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is('Add user');
    $sel->type_ok('login', $watch_user);
    $sel->type_ok('password', 'selenium', 'Enter password');
    $sel->click_ok('add');
    $sel->wait_for_page_to_load_ok(WAIT_TIME);

    go_to_admin($sel);
    $sel->click_ok("link=components");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Edit components for which product?");
    $sel->click_ok("link=$product");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Select component of product '$product'");
    $sel->click_ok("link=Add");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Add component to the $product product");
    $sel->type_ok("component", $component);
    $sel->type_ok("description", $component_description);
    $sel->type_ok("initialowner", $config->{'admin_user_login'});
    $sel->type_ok("watch_user", $watch_user);
    $sel->click_ok("create");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Component Created");
    $text = trim($sel->get_text("message"));
    ok($text eq "The component $component has been created.", "Component successfully created");

    return 1;
}

sub _check_group {
    my ($group) = @_;

    go_to_admin($sel);
    $sel->click_ok("link=Groups");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Edit Groups");

    my $group_description = "$group Description";

    my $text = trim($sel->get_text("bugzilla-body"));
    if ($text =~ /$group_description/) {
        # Group exists already
        return 1;
    }
    
    $sel->title_is("Edit Groups");
    $sel->click_ok("link=Add Group");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Add group");
    $sel->type_ok("name", $group);
    $sel->type_ok("desc", $group_description);
    $sel->check_ok("isactive");
    $sel->check_ok("insertnew");
    $sel->click_ok("create");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("New Group Created");
    my $group_id = $sel->get_value("group_id");

    return 1;
}
