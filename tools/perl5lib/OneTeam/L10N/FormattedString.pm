# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1/GPL 2.0/LGPL 2.1
#
# The contents of this file are subject to the Mozilla Public License Version
# 1.1 (the "License"); you may not use this file except in compliance with
# the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS" basis,
# WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
# for the specific language governing rights and limitations under the
# License.
#
# The Original Code is OneWeb.
#
# The Initial Developer of the Original Code is
# ProcessOne.
# Portions created by the Initial Developer are Copyright (C) 2009
# the Initial Developer. All Rights Reserved.
#
# Contributor(s):
#
# Alternatively, the contents of this file may be used under the terms of
# either the GNU General Public License Version 2 or later (the "GPL"), or
# the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# in which case the provisions of the GPL or the LGPL are applicable instead
# of those above. If you wish to allow use of your version of this file only
# under the terms of either the GPL or the LGPL, and not to allow others to
# use your version of this file under the terms of the MPL, indicate your
# decision by deleting the provisions above and replace them with the notice
# and other provisions required by the GPL or the LGPL. If you do not delete
# the provisions above, a recipient may use your version of this file under
# the terms of any one of the MPL, the GPL or the LGPL.
#
# ***** END LICENSE BLOCK *****

package OneTeam::L10N::FormattedString;
use Moose;
use OneTeam::Utils;

has 'str' => (is => 'ro', isa => 'Str', required => 1);
has 'locations' => (is => 'rw', isa => 'ArrayRef', default => sub { [] });
has 'plural_forms' => (is => 'ro', isa => 'Str', default => sub { "n == 1 ? 0 : 1" });

has '_str_parse_tree' => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $str = $self->str;

        return $self->_parse_str(\$str);
    }
);

sub resolve {
    my ($self, @args) = @_;

    return $self->plural_forms
        if $self->str =~ /^\$\$plural_forms\$\$:/;

    return $self->_resolve($self->_str_parse_tree, @args);
}

sub _resolve {
    my ($self, $str, @args) = @_;

    if (not ref $str) {
        $str =~ s/^\$\$\w+\$\$:\s*//;
        return $str;
    }

    return join "", map {$self->_resolve($_, @args)||""} @$str
        if ref $str eq "ARRAY";

    my $val = $args[$str->{id}];
    my @params = map { $self->_resolve($_, @args) } @{$str->{params}};
    $params[0] = defined $params[0] ? $params[0] : "";

    if ($params[0] eq 'number') {
        my $pad = "";
        my $padc = defined $params[2] && length($params[2]) ? $params[2] : " ";
        my $len = $params[1] || 0;

        $val = sprintf "%.*f", $params[3], $val if defined $params[3];

        $len -= length($val);
        $pad .= substr($padc, 0, $len) while length($pad) < $len;

        return $pad.$val;
    } elsif ($params[0] eq 'string') {
        my $pad = "";
        my $padc = defined $params[2] && length($params[2]) ? $params[2] : " ";
        my $len = ($params[1] || 0) - length($val);
        my $dir = $params[3] || "right";

        $pad .= substr($pad, 0, $len) while length($pad) < $len;

        return $val.$pad if $dir eq "right";

        return $pad.$val;
    } elsif ($params[0] eq 'bool') {
        return $val ? $params[1] : $params[2];
    } elsif ($_ eq "choice") {
        for (my $i = 2; $i < @params; $i++) {
            return $params[$i-1] if $params[$i] < $val;
        }
        return $params[-1];
    } elsif ($_ eq "plurals") {
        if (not $self->{_plural_expr}) {
            my $p = $self->plural_forms;
            $p =~ s/\bn\b/\$n/g;
            $self->{_plural_expr} = eval "sub {my \$n=shift;$p}";
        }
        return $params[$self->{_plural_expr}->($val)+1];
    }
    return $val;
}

sub _parse_deref {
    my ($self, $str) = @_;
    my $ret = {};
    my $start_pos = pos($$str);

    $$str =~ m/\G\s*/g;

    die "Value reference in localizable string with invalid id", pos($$str)
        if not $$str =~ m/\G(\d+)/gc;

    $ret->{id} = $1;

    while ($$str =~ m/\G\s*([,}])/gc) {
        return $ret if $1 eq "}";

        $$str =~ m/\G\s*([^,{}'"\\]*)/gc;
        if (length($1)) {
            my $arg = $1;
            $arg =~ s/\s*$//;
            push @{$ret->{params}}, $arg;
        } elsif ($$str =~ m/\G[,}]/gc) {
            pos($$str) = pos($$str)-1;
            push @{$ret->{params}}, "";
        } elsif ($$str =~ m/\G(['"])/gc) {
            push @{$ret->{params}}, $self->_parse_str($str, $1, pos($$str)-1);
        } else {
            die "Invalid character in localizable string dereference parameter", pos($$str);
        }
    }
    die "Can't locate closing \"}\"", pos($$str);
}

sub _parse_str {
    my ($self, $str, $limit_char, $limit_char_pos) = @_;
    my @expr;

    my $escape_re = qr/
        \\ (?:
            u [0-9a-fA-F]{4} |
            x [0-9a-fA-F]{2} |
            [0-7]{1,3} |
            .)
    /x;

    my $extract_derefs_re = $limit_char ?
        ($limit_char eq "'" ?
            qr/\G((?:[^\\{']|$escape_re)*)([{']?)/ :
            qr/\G((?:[^\\{"]|$escape_re)*)([{"]?)/) :
        qr/\G((?:[^\\{]|$escape_re)*)(\{?)/;

    while ($$str =~ m/$extract_derefs_re/g) {
        my ($arg, $ch) = ($1, $2);

        push @expr, unescape_js($arg) if length $arg;

        if ($ch ne "{") {
            last if not $limit_char or $ch eq $limit_char;
            die "Can't locate closing \"$limit_char\"", $limit_char_pos;
        }
        push @expr, $self->_parse_deref($str);
    }

    return @expr > 1 ? [@expr] : defined $expr[0] ? $expr[0] : "";
}

1;
