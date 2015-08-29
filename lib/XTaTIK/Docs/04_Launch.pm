package XTaTIK::Docs::04_Launch;

# VERSION

1;
__END__

=encoding utf8

=head1 NAME

XTaTIK::Docs::04_Launch - Launching your first XTaTIK website

=head1 WARNING

=for pod_spiffy start warning section

The launching method described below is currently experimental.
It might remain function, with easier alternatives provided, or it might
be removed completely.

=for pod_spiffy end warning section

=head1 ENVIRONMENTAL VARIABLES

XTaTIK uses several environmental variables to figure out what
Silos to use to launch an instance of a website. They're as follows:

=head2 XTATIK_SITE_ROOT

    XTATIK_SITE_ROOT="/var/www/MySite/silo"

This variable specifies the path where your Site Silo is.

=head2 XTATIK_COMPANY

    XTATIK_COMPANY="/var/www/xtatik-company-silo"

This variable specifies the path where your Company Silo is. Since this
variable will be shared among your site launches, you may wish put it
into your `.bashrc` or similar file, for it to be always set.

=head1 RUNNING XTaTIK IN DEVELOPMENT MODE

# TODO: find out/develop how this would work properly

To run the core XTaTIK system, without any Company or Site Silos, simply
run:

    XTaTIK_morbo

The development server will now serve on its default port.

If you'd like to see what your Company Silo looks like, simply have
C<XTATIK_COMPANY> variable set when you launch XTaTIK:

    XTATIK_COMPANY="/var/www/xtatik-company-silo" XTaTIK_morbo

Lastly, to launch a site, specify both Company Silo (if you've used one)
and Site Silo:

    XTATIK_SITE_ROOT="/var/www/MySite/silo" \
    XTATIK_COMPANY="/var/www/xtatik-company-silo" XTaTIK_morbo

=head1 RUNNING XTaTIK IN PRODUCTION MODE

XTaTIK is a L<Mojolicious> application and there are several ways
to run it in production mode. Please consult # TODO: Add link
and select a way you want to run XTaTIK as.

=cut