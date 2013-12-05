
use strict;

package CXGN::Bulk::Converter;

use base 'CXGN::Bulk';
use File::Slurp;

our %solyc_conversion_hash;

sub process_parameters { 
    my $self = shift;
    $self->{output_fields} = [ 'Input', 'Output' ];
    
    my @ids = split /\s+/, $self->{ids};

    $self->{ids} = \@ids;
    
    return 1;
}

sub process_ids { 
    my $self = shift;
    
    if (!defined(%solyc_conversion_hash)) { 
	$self->get_hash();
    }
	
    my ($dump_fh, $notfound_fh) = $self->create_dumpfile();
    my @not_found = ();
    foreach my $id (@{$self->{ids}}) { 
	if (exists($solyc_conversion_hash{uc($id)})) { 
	    print $dump_fh "$id\t$solyc_conversion_hash{uc($id)}\n";
	}
	else { 
	    print $notfound_fh "$id\t(not found)\n";
	}
    }
}

sub get_hash { 
    my $self = shift;
    
    my @conversion = ();
    foreach my $file (@{$self->{solyc_converter_files}}) { 
	my @lines = read_file($file);
	@conversion = (@conversion, @lines);
    }
    
    foreach my $entry (@conversion) { 
	my @fields = split /\t/, $entry;
	$solyc_conversion_hash{uc($fields[0])} = $fields[1];
    }

    

}

1;