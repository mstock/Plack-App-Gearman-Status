requires "Carp" => "0";
requires "MRO::Compat" => "0";
requires "Net::Telnet::Gearman" => "0";
requires "Plack::Component" => "0";
requires "Plack::Util::Accessor" => "0";
requires "Text::MicroTemplate" => "0";
requires "Try::Tiny" => "0";
requires "parent" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'build' => sub {
  requires "Module::Build" => "0.3601";
};

on 'test' => sub {
  requires "File::Find" => "0";
  requires "File::Temp" => "0";
  requires "IO::Socket::INET" => "0";
  requires "Test::Class" => "0";
  requires "Test::Exception" => "0";
  requires "Test::More" => "0.88";
  requires "Test::TCP" => "0";
};

on 'configure' => sub {
  requires "Module::Build" => "0.3601";
};

on 'develop' => sub {
  requires "Test::CPAN::Changes" => "0.19";
  requires "version" => "0.9901";
};
