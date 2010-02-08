# -*- Mode: perl; indent-tabs-mode: nil -*-

package QA::Util;

use strict;
use Data::Dumper;
use HTTP::Cookies;
use Test::More;
use Test::WWW::Selenium;
use WWW::Selenium::Util qw(server_is_running);
use XMLRPC::Lite;

use base qw(Exporter);
@QA::Util::EXPORT = qw(
    trim
    url_quote
    random_string

    log_in
    logout
    file_bug_in_product
    go_to_admin
    edit_product
    add_product
    open_advanced_search_page
    set_parameters

    get_selenium
    get_xmlrpc_client

    xmlrpc_log_in
    xmlrpc_call_success
    xmlrpc_call_fail
    xmlrpc_get_product_ids
    xmlrpc_run_tests

    WAIT_TIME
    CHROME_MODE
);

# How long we wait for pages to load.
use constant WAIT_TIME => 60000;
use constant CONF_FILE =>  "../config/selenium_test.conf";
use constant CHROME_MODE => 1;

#####################
# Utility Functions #
#####################

sub random_string {
    my $size = shift || 30; # default to 30 chars if nothing specified
    return join("", map{ ('0'..'9','a'..'z','A'..'Z')[rand 62] } (1..$size));
}

# Remove consecutive as well as leading and trailing whitespaces.
sub trim {
    my ($str) = @_;
    if ($str) {
      $str =~ s/[\r\n\t\s]+/ /g;
      $str =~ s/^\s+//g;
      $str =~ s/\s+$//g;
    }
    return $str;
}

# This originally came from CGI.pm, by Lincoln D. Stein
sub url_quote {
    my ($toencode) = (@_);
    $toencode =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

###################
# Setup Functions #
###################

sub get_config {
    # read the test configuration file
    my $conf_file = CONF_FILE;
    my $config = do($conf_file)
        or die "can't read configuration '$conf_file': $!$@";
}

sub get_selenium {
    my $chrome_mode = shift;
    my $config = get_config();

    if (!server_is_running) {
        die "Selenium Server isn't running!";
    }

    my $sel = Test::WWW::Selenium->new(
        host        => $config->{host},
        port        => $config->{port},
        browser     => $chrome_mode ? $config->{experimental_browser_launcher} : $config->{browser},
        browser_url => $config->{browser_url}
    );

    return ($sel, $config);
}

sub get_xmlrpc_client {
    my $config = get_config();
    my $xmlrpc_url = $config->{browser_url} . "/"
                    . $config->{bugzilla_installation} . "/xmlrpc.cgi";


    # A temporary cookie jar that isn't saved after the script closes.
    my $cookie_jar = new HTTP::Cookies();
    my $rpc        = new XMLRPC::Lite(proxy => $xmlrpc_url);
    $rpc->transport->cookie_jar($cookie_jar);
    return ($rpc, $config);
}

###############################
# Helpers for XML-RPC scripts #
###############################

sub xmlrpc_log_in {
    my ($rpc, $config, $user) = @_;
    my $username = $config->{"${user}_user_login"};
    my $password = $config->{"${user}_user_passwd"};

    my $call = xmlrpc_call_success($rpc, 'User.login', 
                                { login => $username, password => $password });
    cmp_ok($call->result->{id}, 'gt', 0,  "Logged in as $user");

    # Save the cookies in the cookie file
    $rpc->transport->cookie_jar->extract_cookies(
        $rpc->transport->http_response);
    $rpc->transport->cookie_jar->save;
}

sub xmlrpc_call_success {
    my ($rpc, $method, $args, $test_name) = @_;
    my $call = $rpc->call($method, $args);
    $test_name ||= "$method returned successfully";
    ok(!defined $call->fault, $test_name) or diag($call->faultstring);
    return $call;
}

sub xmlrpc_call_fail {
    my ($rpc, $method, $args, $faultstring, $test_name) = @_;
    my $call = $rpc->call($method, $args);
    $test_name ||= "$method failed (as intended)";
    ok(defined $call->fault, $test_name)
        or diag("Returned: " . Dumper($call->result));
    if (defined $faultstring) {
        cmp_ok(trim($call->faultstring), '=~', $faultstring, 
               "Got correct fault for $method");
    }
    return $call;
}

sub xmlrpc_get_product_ids {
    my ($rpc, $config) = @_;
    xmlrpc_log_in($rpc, $config, 'QA_Selenium_TEST');

    my $accessible = xmlrpc_call_success($rpc, 
                                         'Product.get_accessible_products');
    my $prod_call = xmlrpc_call_success($rpc, 'Product.get', 
                                        $accessible->result);
    my %products;
    foreach my $prod (@{ $prod_call->result->{products} }) {
        $products{$prod->{name}} = $prod->{id};
    }

    xmlrpc_call_success($rpc, 'User.logout');

    return \%products;
}

sub xmlrpc_run_tests {
    my %params = @_;
    # Required params
    my $rpc    = $params{rpc};
    my $config = $params{config};
    my $tests  = $params{tests};
    my $method = $params{method};

    # Optional params
    my $post_success = $params{post_success};

    my $former_user = '';
    foreach my $t (@$tests) {
        # Only logout/login if the user has changed since the last test
        # (this saves us LOTS of needless logins).
        my $user = $t->{user} || '';
        if ($former_user ne $user) {
            xmlrpc_call_success($rpc, 'User.logout') if $former_user;
            xmlrpc_log_in($rpc, $config, $user) if $user;
            $former_user = $user;
        }

        if ($t->{error}) {
            xmlrpc_call_fail($rpc, $method, $t->{args}, $t->{error},
                             $t->{test});
        }
        else {
            my $call = xmlrpc_call_success($rpc, $method, $t->{args},
                                           $t->{test});
            if ($call->result && $post_success) {
                $post_success->($call, $t);
            }
        }
    }

    xmlrpc_call_success($rpc, 'User.logout') if $former_user;
}

################################
# Helpers for Selenium Scripts #
################################

# Go to the home/login page and log in.
sub log_in {
    my ($sel, $config, $user) = @_;

    $sel->open_ok("/$config->{bugzilla_installation}/", undef, "Go to the login page");
    $sel->type_ok("Bugzilla_login_top", $config->{"${user}_user_login"}, "Enter $user login name");
    $sel->type_ok("Bugzilla_password_top", $config->{"${user}_user_passwd"}, "Enter $user password");
    $sel->click_ok("log_in_top", undef, "Submit credentials");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Bugzilla Main Page", "User is logged in");
}

# Log out. Will fail if you are not logged in.
sub logout {
    my $sel = shift;

    $sel->click_ok("link=Log out", undef, "Logout");
    $sel->wait_for_page_to_load_ok(WAIT_TIME);
    $sel->title_is("Logged Out");
}

# Display the bug form to enter a bug in the given product.
sub file_bug_in_product {
    my ($sel, $product, $classification) = @_;

    $classification ||= "Unclassified";
    $sel->click_ok("link=New", undef, "Go create a new bug");
    $sel->wait_for_page_to_load(WAIT_TIME);
    my $title = $sel->get_title();
    if ($title eq "Select Classification") {
        ok(1, "More than one enterable classification available. Display them in a list");
        $sel->click_ok("link=$classification", undef, "Choose $classification");
        $sel->wait_for_page_to_load(WAIT_TIME);
        $title = $sel->get_title();
    }
    if ($title eq "Enter Bug") {
        ok(1, "Display the list of enterable products");
        $sel->click_ok("link=$product", undef, "Choose $product");
        $sel->wait_for_page_to_load(WAIT_TIME);
    }
    else {
        ok(1, "Only one product available in $classification. Skipping the 'Choose product' page.")
    }
    $sel->title_is("Enter Bug: $product", "Display form to enter bug data");
}

# Go to admin.cgi.
sub go_to_admin {
    my $sel = shift;

    $sel->click_ok("link=Administration", undef, "Go to the Admin page");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_like(qr/^Administer your installation/, "Display admin.cgi");
}

# Go to editproducts.cgi and display the given product.
sub edit_product {
    my ($sel, $product, $classification) = @_;

    $classification ||= "Unclassified";
    go_to_admin($sel);
    $sel->click_ok("link=Products", undef, "Go to the Products page");
    $sel->wait_for_page_to_load(WAIT_TIME);
    my $title = $sel->get_title();
    if ($title eq "Select Classification") {
        ok(1, "More than one enterable classification available. Display them in a list");
        $sel->click_ok("link=$classification", undef, "Choose $classification");
        $sel->wait_for_page_to_load(WAIT_TIME);
    }
    else {
        $sel->title_is("Select product", "Display the list of enterable products");
    }
    $sel->click_ok("link=$product", undef, "Choose $product");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Edit Product '$product'", "Display properties of $product");
}

sub add_product {
    my ($sel, $classification) = @_;

    $classification ||= "Unclassified";
    go_to_admin($sel);
    $sel->click_ok("link=Products", undef, "Go to the Products page");
    $sel->wait_for_page_to_load(WAIT_TIME);
    my $title = $sel->get_title();
    if ($title eq "Select Classification") {
        ok(1, "More than one enterable classification available. Display them in a list");
        $sel->click_ok("//a[contains(\@href, 'editproducts.cgi?action=add&amp;classification=$classification')]",
                       undef, "Add product to $classification");
    }
    else {
        $sel->title_is("Select product", "Display the list of enterable products");
        $sel->click_ok("link=Add", undef, "Add a new product");
    }
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Add Product", "Display the new product form");
}

sub open_advanced_search_page {
    my $sel = shift;

    $sel->click_ok("link=Search");
    $sel->wait_for_page_to_load(WAIT_TIME);
    my $title = $sel->get_title();
    if ($title eq "Simple Search") {
        ok(1, "Display the simple search form");
        $sel->click_ok("link=Advanced Search");
        $sel->wait_for_page_to_load(WAIT_TIME);
    }
    $sel->title_is("Search for bugs", "Display the Advanced search form");
}

# $params is a hashref of the form:
# {section1 => { param1 => {type => '(text|select)', value => 'foo'},
#                param2 => {type => '(text|select)', value => 'bar'},
#                param3 => undef },
#  section2 => { param4 => ...},
# }
# section1, section2, ... is the name of the section
# param1, param2, ... is the name of the parameter (which must belong to the given section)
# type => 'text' is for text fields
# type => 'select' is for drop-down select fields
# undef is for radio buttons (in which case the parameter must be the ID of the radio button)
# value => 'foo' is the value of the parameter (either text or label)
sub set_parameters {
    my ($sel, $params) = @_;

    go_to_admin($sel);
    $sel->click_ok("link=Parameters", undef, "Go to the Config Parameters page");
    $sel->wait_for_page_to_load(WAIT_TIME);
    $sel->title_is("Configuration: Required Settings");
    my $last_section = "Required Settings";

    foreach my $section (keys %$params) {
        if ($section ne $last_section) {
            $sel->click_ok("link=$section");
            $sel->wait_for_page_to_load_ok(WAIT_TIME);
            $sel->title_is("Configuration: $section");
            $last_section = $section;
        }
        my $param_list = $params->{$section};
        foreach my $param (keys %$param_list) {
            my $data = $param_list->{$param};
            if (defined $data) {
                my $type = $data->{type};
                my $value = $data->{value};

                if ($type eq 'text') {
                    $sel->type_ok($param, $value);
                }
                elsif ($type eq 'select') {
                    $sel->select_ok($param, "label=$value");
                }
                else {
                    ok(0, "Unknown parameter type: $type");
                }
            }
            else {
                # If the value is undefined, then the param name is
                # the ID of the radio button.
                $sel->click_ok($param);
            }
        }
        $sel->click_ok('//input[@type="submit" and @value="Save Changes"]', undef, "Save Changes");
        $sel->wait_for_page_to_load_ok(WAIT_TIME);
        $sel->title_is("Parameters Updated");
    }
}

1;

__END__
