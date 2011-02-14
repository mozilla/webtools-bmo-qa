########################################
# Test for xmlrpc call to Bug.search() #
########################################

use strict;
use warnings;
use lib qw(lib);
use QA::Util;
use QA::Tests qw(PRIVATE_BUG_USER);
use DateTime;
use Test::More;

my ($config, @clients) = get_rpc_clients();
plan tests => $config->{test_extensions} ? 321 : 311;

my ($public_bug, $private_bug) = $clients[0]->bz_create_test_bugs('private');

my @tests;
foreach my $field (keys %$public_bug) {
    next if ($field eq 'cc' or $field eq 'description');
    my $test = { args => { $field => $public_bug->{$field} },
                 test => "Search by $field" };
    if ( grep($_ eq $field, qw(alias whiteboard summary)) ) {
        $test->{exactly} = 1; $test->{bugs} = 1;
    }
    push(@tests, $test);
}


push(@tests, (
    { args  => { offset => 1 },
      test  => "Offset without limit fails",
      error => 'requires a limit argument',
    },

    { args => { alias => $private_bug->{alias} },
      test => 'Logged-out cannot find a private_bug by alias',
      bugs => 0,
    },

    { args => { creation_time => '19700101T00:00:00' },
      test => 'Get all bugs by creation time',
    },
    { args => { creation_time => '20380101T00:00:00' },
      test => 'Get no bugs, by creation time',
      bugs => 0,
    },
    { args => { last_change_time => '19700101T00:00:00' },
      test => 'Get all bugs by last_change_time',
    },
    { args => { last_change_time => '20380101T00:00:00' },
      test => 'Get no bugs by last_change_time',
      bugs => 0,
    },

    { args => { reporter => $config->{editbugs_user_login} },
      test => 'Search by reporter',
    },
    { args => { resolution => '' },
      test => 'Search for empty resolution',
    },
    { args => { resolution => 'NO_SUCH_RESOLUTION' },
      test => 'Search for invalid resolution',
      bugs => 0,
    },
    { args => { summary => substr($public_bug->{summary}, 0, 50) },
      test => 'Search by partial summary',
      bugs => 1, exactly => 1
    },
    { args => { summary => random_string() . ' ' . random_string() },
      test => 'Summary search that returns no results',
      bugs => 0,
    },
    { args => { summary => [split(/\s/, $public_bug->{summary})] },
      test => 'Summary search using multiple terms',
    },

    { args => { whiteboard => substr($public_bug->{whiteboard}, 0, 50) },
      test => 'Search by partial whiteboard',
      bugs => 1, exactly => 1,
    },
    { args => { whiteboard => random_string(100) },
      test => 'Whiteboard search that returns no results',
      bugs => 0,
    },
    { args => { whiteboard => [split(/\s/, $public_bug->{whiteboard})] },
      test => 'Whiteboard search using multiple terms',
      bugs => 1, exactly => 1,
    },

    { args => { product => $public_bug->{product}, 
                component => $public_bug->{component},
                last_change_time => '19700101T00:00:00' },
      test => 'Search by multiple arguments',
    },

    # Logged-in user who can see private bugs
    { user => PRIVATE_BUG_USER,
      args => { alias => [$public_bug->{alias}, $private_bug->{alias}] },
      test => 'Search using two aliases (including one private)',
      bugs => 2, exactly => 1,
    },
    { user => PRIVATE_BUG_USER,
      args => { product => [$public_bug->{product}, $private_bug->{product}], 
                limit => 1 },
      test => 'Limit 1',
      bugs => 1, exactly => 1,
    },
    { user => PRIVATE_BUG_USER,
      args => { product => [$public_bug->{product}, $private_bug->{product}],
                limit => 1, offset => 1 },
      test => 'Limit 1 Offset 1',
      bugs => 1, exactly => 1,
    },
));

push(@tests,
    { args => { votes => 1 },
      test => 'Search by votes',
      bugs => -1, # We don't care how many it returns, for now.
    }) if $config->{test_extensions};

sub post_success {
    my ($call, $t) = @_;
    my $bugs = $call->result->{bugs};
    my $expected_count = $t->{bugs};
    $expected_count = 1 if !defined $expected_count;
    if ($expected_count) {
        my $operator = $t->{exactly} ? '=' : '>=';
        cmp_ok(scalar @$bugs, $operator, $expected_count, 
               'The right number of bugs are returned');
        unless ($t->{user} and $t->{user} eq PRIVATE_BUG_USER) {
            ok(!grep($_->{alias} eq $private_bug->{alias}, @$bugs),
               'Result does not contain the private bug');
        }
    }
    else {
        is(scalar @$bugs, 0, 'No bugs returned');
    }
}

foreach my $rpc (@clients) {
    $rpc->bz_run_tests(tests => \@tests,
                       method => 'Bug.search', post_success => \&post_success);
}
