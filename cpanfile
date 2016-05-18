requires 'DDP';
requires 'DateTime';
requires 'DateTime::Format::HTTP';
requires 'Digest::HMAC_SHA1';
requires 'HTTP::Request';
requires 'JSON::MaybeXS';
requires 'LWP::UserAgent';
requires 'Moo';
requires 'String::CamelSnakeKebab';
requires 'feature';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
    requires 'perl', '5.008_001';
};

on test => sub {
    requires 'Test::More', '0.98';
};
