package OneTeam::Builder::Bundle;
use Exporter;

sub import {
    my @pkgs = map {"OneTeam::Builder::$_"} "Utils", "Filter",
        map { "Filter::$_"} qw(DialogSizeProcessor LocaleProcessor PathConverter
            Preprocessor Saver CommentsStripper Saver::XPI);

    eval("package ".scalar(caller()).";".(join "", map "use $_;", @pkgs));
    die $@ if $@;
}

1;
