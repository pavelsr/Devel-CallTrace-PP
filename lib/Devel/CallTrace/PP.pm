package Devel::CallTrace::PP;

# ABSTRACT: Main module for dctpp CLI tool

use File::Slurp;
use Data::Dumper;
use Devel::CallTrace::Utils qw/:ALL/;
use List::Util qw/uniq/;
use Math::Round qw(round);

# ' FakeLocale::AUTOLOAD (/opt/perl5.26.1/..'
sub extract_call {
	my ( $val ) = @_;
	if ( $val =~ /\s+((\w|:)+)/ ) {
		return $1;
	}
	return;
}

sub handler {
	my ( $self, $filename, $opts ) = @_;
	# $params is Getopt::Long::Descriptive::Opts
	
	my $stat = {};

	my @lines = read_file($filename);
	$_ =~ s/\n// for (@lines);
	
	$stat->{'lines_initially'} = scalar @lines;
	
	# filter anonymous calls
	@lines = grep { $_ !~ /CODE/  } @lines;
	
	my @uniq_calls = map { extract_call($_) } @lines;
	
	# my @uniq_mod_paths = uniq map { substr_file_line($_) } @lines;
	# warn Dumper \@uniq_mod_paths; 
	
	if ($opts->hide_constants) {
		@lines = grep { substr_method(extract_call($_)) !~ /[A-Z0-9_]+/ } @lines;
	}
	
	if ( $opts->hide_cpan || $opts->hide_core ) {
		@lines = grep { substr_file_line($_) !~ /perl/ } @lines;
	}
	
	
	#### FILTER MODULES
	
	my @modules = map { substr_module_name(extract_call($_)) } @lines;	
	@modules = uniq @modules;
	$stat->{'uniq_modules_all'} = [ @modules ];
	
	# warn "Modules 1 : ".Dumper scalar @modules;
	
	if ( $opts->hide_cpan) {
		# TO-DO: add cpan progress check
		@modules = grep { !is_cpan_published($_)  } @modules;
	}
	
	if ( $opts->hide_core) {
		@modules = grep { !is_core($_) } @modules;
	}
	
	# warn "Modules 2 : ".Dumper scalar @modules;
	# warn "Modules 2 : ".Dumper \@modules;
	
	$stat->{'uniq_modules_filtered'} = [ @modules ];
	@lines = grep { isin(substr_module_name(extract_call($_)), \@modules) } @lines;
		
	if ( $opts->rle ) {
		@lines = rle(@lines);
	}
	
	$stat->{'lines_in_result'} = scalar @lines;
	$stat->{'lines_filtered'} = $stat->{'lines_initially'} - $stat->{'lines_in_result'};
	$stat->{'uniq_calls_all'} = [ uniq @uniq_calls ];	# all non anonumous
	$stat->{'uniq_calls_filtered'} = [ uniq @lines ];
	
	if ( $opts->just_uniq_calls ) {
		print "$_\n" for (@{$stat->{'uniq_calls_all'}});
		print "# Total unique calls : ".scalar @{$stat->{'uniq_calls_all'}}."\n";
		# exit;
	}
	
	print "$_\n" for ( @lines );
	
	if ( $opts->verbose ) {
		print "### DEBUG\n";
		print "Trace has ".$stat->{'lines_initially'}." lines initially\n";
		my $percentage = round 100 * $stat->{'lines_filtered'} / $stat->{'lines_initially'};
		print $stat->{'lines_filtered'}." lines was filtered - ".$percentage."%\n";
		print scalar @lines." lines left \n";
		
		print '### @INC :'."\n";
		print "$_\n" for @INC;
	}
}

1;
