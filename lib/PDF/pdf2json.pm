package PDF::pdf2json;
# ABSTRACT: helper module to retrieve data from pdf2json

use strict;
use warnings;

use File::Temp;
use Path::Class;
use Alien::pdf2json;
use JSON::MaybeXS;

our $alien = Alien::pdf2json->new;

=method pdf2json($pdf_file_name, %param)

    my $pdf2json_data = PDF::pdf2json->pdf2json( "file.pdf", page => 1 );

Parameters you can pass in:

=over 4

=item page: integer of single page to process (1-based)

If this parameter is not specified, all pages will be returned.

=item quiet: boolean to switch the quiet flag for pdf2json (-q)

Default is true.

=back

=cut
sub pdf2json {
	my ($self, $pdf, %param) = @_;
	$param{quiet} //= 1;

	my $temp_fh = File::Temp->new ( UNLINK => 0 );
	my @args = ();
	if( exists $param{page} ) {
		die "page number must be integer" unless $param{page} =~ /^\d+$/;
		push @args, ( '-f', $param{page} );
		push @args, ( '-l', $param{page} );
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

	$data;
}

1;
__END__

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
  #             "fontspec" : "0",
  #             "family" : "Times",
  #             "size" : "12",
  #             "color" : "#000000"
  #          }
  #       ],
  #       "text" : [
  #          {
  #             "top" : 192,
  #             "left" : 223,
  #             "width" : 24,
  #             "height" : 13,
  #             "font" : 0,
  #             "data" : "test"
  #          },
  #          {
  #             "top" : 1044,
  #             "left" : 455,
  #             "width" : 7,
  #             "height" : 13,
  #             "font" : 0,
  #             "data" : "1"
  #          }
  #       ]
  #    },
  #    # ... more data for each page of the PDF
  # ]

=head1 SEE ALSO

=over 4

=item * L<Alien::pdf2json>

=back

=cut
