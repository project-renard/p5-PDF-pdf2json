package PDF::pdf2json;
# ABSTRACT: helper module to retrieve data from pdf2json
$PDF::pdf2json::VERSION = '0.001';
use strict;
use warnings;

use File::Temp;
use Path::Class;
use Alien::pdf2json;
use JSON::MaybeXS;

our $alien = Alien::pdf2json->new;

sub pdf2json {
	my ($self, $pdf, %param) = @_;
	$param{quiet} //= 1;

	my $temp_fh = File::Temp->new ( UNLINK => 0 );
	my @args = ();
	if( exists $param{page} ) {
		die "page number must be integer" unless $param{page} =~ /^\d+$/;
		push @args, ( '-f', $param{page} + 1 ); # add 1 because page param is 0-based, but pdf2json is 1-based
		push @args, ( '-l', $param{page} + 1 );
	}
	if( exists $param{quiet} ) {
		push @args, '-q' if !!$param{quiet};
	}
	my $cmd = [
		$alien->pdf2json_path,
		'-enc', 'UTF-8',
		@args,
		$pdf,
		$temp_fh->filename,
	];
	my $ret = system( @$cmd  );
	die "pdf2json failed" if $ret;

	# read data from temp file
	my $json_data = file( $temp_fh->filename )->slurp();

	my $data = decode_json( $json_data );

	$_->{number}-- for @$data; # convert to 0-based index

	$data;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDF::pdf2json - helper module to retrieve data from pdf2json

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $data = PDF::pdf2json->pdf2json( '/path/to/file.pdf' );
  # [
  #    {
  #       "number" : 1,
  #       "pages" : 3,
  #       "width" : 918,
  #       "height" : 1188,
  #       "fonts" : [
  #          {
  #             "color" : "#000000",
  #             "fontspec" : "0",
  #             "family" : "Times",
  #             "size" : "12"
  #          }
  #       ],
  #       "text" : [
  #          {
  #             "width" : 24,
  #             "left" : 223,
  #             "top" : 192,
  #             "data" : "test",
  #             "font" : 0,
  #             "height" : 13
  #          },
  #          {
  #             "width" : 7,
  #             "left" : 455,
  #             "top" : 1044,
  #             "data" : "1",
  #             "font" : 0,
  #             "height" : 13
  #          }
  #       ]
  #    }, # ... more data for each page of the PDF

=head1 METHODS

=head2 pdf2json($pdf_file_name, %param)

    my $pdf2json_data = PDF::pdf2json->pdf2json( "file.pdf", page => 1 );

Parameters you can pass in:

=over 4

=item page: integer of single page to process (0-based)

If this parameter is not specified, all pages will be returned.

=item quiet: boolean to switch the quiet flag for pdf2json (-q)

Default is true.

=back

NOTE: this function modifies the pdf2json output so that all page numbers are on a 0-based index

=head1 SEE ALSO

=over 4

=item * L<Alien::pdf2json>

=back

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
