package XTaTIK::Docs::Installation;
1;
__END__

=encoding utf8

=head1 NAME

XTaTIK::Docs - Index of documentation for XTaTIK eCommerce system

=head1 NOTE ON OPERATING SYSTEM

All instructions below are for Debian 8.1 (Jessie) Linux.
If you'd like to provide installation instructions for other operating
systems, please submit a
L<pull request|https://github.com/XTaTIK/XTaTIK/pulls>.

=head1 NOTE ON PERL VERSION

XTaTIK supports the current and previous major releases of Perl.
Please use L<Perlbrew|http://perlbrew.pl/> to obtain the latest
versions of Perl.

=head1 SOFTWARE NOT FOUND ON CPAN

Some of the software required to run XTaTIK or compile one of the modules
it uses is not available on CPAN.

=head2 PostgreSQL and Development C Libraries

You need to install PostgreSQL database, development files for it
(needed by L<Mojo::Pg>), and development files for C<libdb>
(needed by L<Search::Indexer>).

I<Note: choose the apropriate version for the C<postgresql-server-dev-9.4>
package (run C<aptitude search postgresql-server>)>.

    sudo apt-get install libdb-dev postgresql postgresql-server-dev-9.4;

=head2 GEOIP DATABASE

Currently, XTaTIK only supports the Free version of
L<IP2Location.com|https://www.ip2location.com/>'s database
(paid-for version is untested, but will likely work too).

You will need to create a B<free> account to download the
B<free> database files.
Download IPv4 B<DB3.LITE> C<.bin> file (or just B<DB3>, if you're using
a paid-for version) of the
L<Lite database|http://lite.ip2location.com/databases> to some local
directory; we'll refer to it shortly.

=head1 XTaTIK CORE




Simply install package L<XTaTIK> from CPAN. Using L<cpanm>, it's as
simple as:

    cpanm XTaTIK



=cut