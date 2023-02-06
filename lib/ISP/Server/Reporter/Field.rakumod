unit class ISP::Server::Reporter::Field:api<1>:auth<Mark Devine (mark@markdevine.com)>;

has Str $.name;
has Str $.alignment where * ~~ any('l', 'c', 'r');
