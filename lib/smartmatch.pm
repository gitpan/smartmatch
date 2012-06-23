package smartmatch;
BEGIN {
  $smartmatch::AUTHORITY = 'cpan:DOY';
}
{
  $smartmatch::VERSION = '0.04'; # TRIAL
}
use strict;
use warnings;
use 5.010;
# ABSTRACT: pluggable smart matching backends

use parent 'DynaLoader';
use B::Hooks::OP::Check;
use Module::Runtime 'use_package_optimistically';
use Package::Stash;

sub dl_load_flags { 0x01 }

__PACKAGE__->bootstrap(
    # we need to be careful not to touch $VERSION at compile time, otherwise
    # DynaLoader will assume it's set and check against it, which will cause
    # fail when being run in the checkout without dzil having set the actual
    # $VERSION
    exists $smartmatch::{VERSION}
        ? ${ $smartmatch::{VERSION} } : (),
);


my $anon = 1;

sub import {
    my $package = shift;
    my ($engine) = @_;

    if (ref($engine)) {
        my $cb = $engine;
        $engine = '__ANON__::' . $anon++;
        my $anon_stash = Package::Stash->new("smartmatch::engine::$engine");
        $anon_stash->add_symbol('&match' => $cb);
    }
    else {
        my $package = "smartmatch::engine::$engine";
        use_package_optimistically($package);
        die "$package does not implement a 'match' function"
            unless $package->can('match');
    }

    $^H{'smartmatch/engine'} = $engine;
}

sub unimport {
    delete $^H{'smartmatch/engine'};
}


1;

__END__
=pod

=head1 NAME

smartmatch - pluggable smart matching backends

=head1 VERSION

version 0.04

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

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-smartmatch at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=smartmatch>.

=head1 SEE ALSO

L<perlsyn/"Smart matching in detail">

L<smartmatch::engine::core>

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

=for Pod::Coverage import
unimport
register
unregister

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

