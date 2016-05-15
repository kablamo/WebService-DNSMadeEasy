#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use WebService::DNSMadeEasy;

SKIP: {

	skip "Environment variables WWW_DNSMADEEASY_TEST_APIKEY and WWW_DNSMADEEASY_TEST_SECRET", 1
		unless $ENV{WWW_DNSMADEEASY_TEST_APIKEY} &&
               $ENV{WWW_DNSMADEEASY_TEST_SECRET};
	
	my $dme = WebService::DNSMadeEasy->new({
		api_key => $ENV{WWW_DNSMADEEASY_TEST_APIKEY},
		secret  => $ENV{WWW_DNSMADEEASY_TEST_SECRET},
		sandbox => 1,
	});

	isa_ok($dme,'WebService::DNSMadeEasy');

	my @domains = $dme->all_domains;
	
}

done_testing;