#########################################
# Test for xmlrpc call to User.Create() #
#########################################

use strict;
use warnings;
use lib qw(lib);
use QA::Util;
use Test::More tests => 28;
my ($rpc, $config) = get_xmlrpc_client();

use constant NEW_PASSWORD => 'password';
use constant NEW_FULLNAME => 'WebService Created User';

use constant PASSWORD_TOO_SHORT => 'a';
use constant PASSWORD_TOO_LONG  => random_string(500);

# These are the characters that are actually invalid per RFC.
use constant INVALID_EMAIL => '()[]\;:,<>@webservice.test';

sub new_login {
    return 'created_' . random_string() . '@webservice.test';
}

my @tests = (
    # Permissions checks
    { args  => { email    => new_login(), full_name => NEW_FULLNAME,
                 password => NEW_PASSWORD },
      error => "you are not authorized",
      test  => 'Logged-out user cannot call User.create',
    },
    { user  => 'unprivileged',
      args  => { email    => new_login(), full_name => NEW_FULLNAME,
                 password => NEW_PASSWORD },
      error => "you are not authorized",
      test  => 'Unprivileged user cannot call User.create',
    },

    # Login name checks.
    { user  => 'admin',
      args  => { full_name => NEW_FULLNAME, password => NEW_PASSWORD },
      error => "argument was not set",
      test  => 'Leaving out email argument fails',
    },
    { user  => 'admin',
      args  => { email    => '', full_name => NEW_FULLNAME,
                 password => NEW_PASSWORD },
      error => "argument was not set",
      test  => "Passing an empty email argument fails",
    },
    { user  => 'admin',
      args  => { email    => INVALID_EMAIL, full_name => NEW_FULLNAME,
                 password => NEW_PASSWORD },
      error =>  "didn't pass our syntax checking",
      test  => 'Invalid email address fails',
    },
    { user  => 'admin',
      args  => { email     => $config->{unprivileged_user_login},
                 full_name => NEW_FULLNAME, password => NEW_PASSWORD },
      error =>  "There is already an account",
      test  => 'Trying to use an existing login name fails',
    },

    { user  => 'admin',
      args  => { email    => new_login(), full_name => NEW_FULLNAME,
                 password => PASSWORD_TOO_SHORT },
      error => 'password must be at least',
      test  => 'Password Too Short fails',
    },
    { user  => 'admin',
      args  => { email    => new_login(), full_name => NEW_FULLNAME,
                 password => PASSWORD_TOO_LONG },
      error => 'password must be no more than',
      test  => 'Password Too Long fails',
    },

    { user => 'admin',
      args => { email    => new_login(), full_name => NEW_FULLNAME,
                password => NEW_PASSWORD },
      test => 'Creating a user with all arguments and correct privileges',
    },
    { user => 'admin',
      args => { email => new_login(), password => NEW_PASSWORD },
      test => 'Leaving out fullname works',
    },
    { user => 'admin',
      args => { email => new_login(), full_name => NEW_FULLNAME },
      test => 'Leaving out password works',
    },
);

my $former_user = '';
foreach my $t (@tests) {
    # Only logout/login if the user has changed since the last test
    # (this saves us LOTS of needless logins).
    my $user = $t->{user} || '';
    if ($former_user ne $user) {
        xmlrpc_call_success($rpc, 'User.logout') if $former_user;
        xmlrpc_log_in($rpc, $config, $user) if $user;
        $former_user = $user;
    }

    if ($t->{error}) {
        xmlrpc_call_fail($rpc, 'User.create', $t->{args}, $t->{error}, 
                         $t->{test});
    }
    else {
        my $call = xmlrpc_call_success($rpc, 'User.create', $t->{args}, 
                                       $t->{test});
        ok($call->result->{id}, "Got a non-zero user id");
    }
}

xmlrpc_call_success($rpc, 'User.logout') if $former_user;
