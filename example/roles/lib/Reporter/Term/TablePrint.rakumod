use     Reporter;
use     Term::TablePrint;
unit    role Reporter::Term::TablePrint does Reporter;

submethod TWEAK {
    put self.raku;
}
