use     Reporter;
use     Prettier::Table;
unit    role Reporter::Prettier::Table does Reporter;

submethod TWEAK {
    put self.raku;
}
