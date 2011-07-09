package smartmatch;
BEGIN {
  $smartmatch::VERSION = '0.01'; # TRIAL
}
use strict;
use warnings;
use 5.010;
# ABSTRACT: pluggable smart matching backends

use parent 'DynaLoader';
use B::Hooks::OP::Check;

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap(
    # we need to be careful not to touch $VERSION at compile time, otherwise
    # DynaLoader will assume it's set and check against it, which will cause
    # fail when being run in the checkout without dzil having set the actual
    # $VERSION
    exists $smartmatch::{VERSION}
        ? ${ $smartmatch::{VERSION} } : (),
);


sub import {
    my $package = shift;
    my ($cb) = @_;

    if (!ref($cb)) {
        my $engine = "smartmatch::engine::$cb";
        eval "require $engine; 1"
            or die "Couldn't load smartmatch engine $engine: $@";
        $cb = $engine->can('match') unless ref($cb);
    }

    register($cb);
}

sub unimport {
    unregister();
}


1;

__END__
=pod

=head1 NAME

smartmatch - pluggable smart matching backends

=head1 VERSION

version 0.01

=head1 SYNOPSIS

  1 ~~ 2; # false
  {
      use smartmatch sub { 1 };
      1 ~~ 2; # true

      no smartmatch;
      1 ~~ 2; # false

      use smartmatch 'custom';
      1 ~~ 2; # smartmatch::engine::custom::match(1, 2)
  }
  1 ~~ 2; # false

=head1 DESCRIPTION

NOTE: This module is still experimental, and the API may change at any point.
You have been warned!

This module allows you to override the behavior of the smart match operator
(C<~~>). C<use smartmatch $matcher> hooks into the compiler to replace the
smartmatch opcode with a call to a custom subroutine, specified either as a
coderef or as a string, which will have C<smartmatch::engine::> prepended to it
and used as the name of a package in which to find a subroutine named C<match>.
The subroutine will be called with two arguments, the values on the left and
right sides of the smart match operator, and should return the result.

This module is lexically scoped, and you can call C<no smartmatch> to restore
the core perl smart matching behavior.

=for Pod::Coverage import
unimport
register
unregister

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-smartmatch at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=smartmatch>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<perlsyn/"Smart matching in detail">

=item *

L<smartmatch::engine::core>

=back

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc smartmatch

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/smartmatch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/smartmatch>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=smartmatch>

=item * Search CPAN

L<http://search.cpan.org/dist/smartmatch>

=back

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

