package Devel::CallTrace::Utils;

use MetaCPAN::Client;
use Module::CoreList;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
	substr_method
	substr_module_name
	is_cpan_published
	is_core
	isin
);
our %EXPORT_TAGS = ( 'ALL' => [ @EXPORT_OK ] );

my $mcpan = MetaCPAN::Client->new( version => 'v1' );

sub get_sources {
	my ( $val ) = @_;
	if ( $val =~ /\s+((\w|:)+)/ ) {
		return $1;
	}
	return;
}

# sub guess_lib_source { }


sub substr_method {
	my ( $str ) = @_;
	(split ( '::', $str ))[-1];
}

sub substr_module_name {
    my ($sub) = @_;
    my @x = split( '::', $sub );
    return $x[0] if ( scalar @x == 1 );
    pop @x;
    return join( '::', @x );
}

sub is_cpan_published {
    my ($pkg, $severity) = @_;
    return 0 if !defined $pkg;
	$severity = 2 if !defined $severity;
    
	if ( $severity == 0 ) {
		eval {
			return $mcpan->module($pkg)->distribution;
		} or do {
			return 0;
		}
	}
	
	elsif ( $severity == 1 ) {
	    my $expected_distro = $pkg;
	    $expected_distro =~ s/::/-/g;
		eval {
			return $mcpan->distribution($expected_distro)->name;
		} or do {
			return 0;
		}
	}
	
	elsif ( $severity == 2 ) {
	    my $expected_distro = $pkg;
	    $expected_distro =~ s/::/-/g;
			
		my $success = eval {
			$mcpan->distribution($expected_distro)->name;
		};
		return $success if $success;
		
		$success = eval {
			$mcpan->module($pkg)->distribution;
		};
		
		if ( $success ) {
			# exceptions
			return $success if ( $success eq 'Moo' );
			return $success if ( $success eq 'Moose' );
			
			# $pkg can be Sub::Defer and $success is Sub-Quote
			my $root_namespace = (split( '-', $success))[0];
			return $success if ( $pkg =~ qr/$root_namespace/ );
		}
		
		return 0;
	}
    
	else {
		die "Wrong or non implemented severity value";
	}
}

sub is_core {
    my ($pkg) = @_;
    return 0 if !defined $pkg;
    return Module::CoreList::is_core(@_);
}

sub isin($$) {
    my ( $val, $array_ref ) = @_;

    return 0 unless $array_ref && defined $val;
    for my $v (@$array_ref) {
        return 1 if $v eq $val;
    }

    return 0;
}