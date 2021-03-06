package CXGN::Trial::ParseUpload::Plugin::TrialExcelFormat;

use Moose::Role;
use Spreadsheet::ParseExcel;
use CXGN::Stock::StockLookup;

sub _validate_with_plugin {
  my $self = shift;
  my $filename = $self->get_filename();
  my $schema = $self->get_chado_schema();
  my @errors;
  my %supported_trial_types;
  my $parser   = Spreadsheet::ParseExcel->new();
  my $excel_obj;
  my $worksheet;
  my %seen_plot_names;

  #currently supported trial types
  $supported_trial_types{'biparental'} = 1; #both parents required
  $supported_trial_types{'self'} = 1; #only female parent required
  $supported_trial_types{'open'} = 1; #only female parent required

  #try to open the excel file and report any errors
  $excel_obj = $parser->parse($filename);
  if ( !$excel_obj ) {
    push @errors,  $parser->error();
    $self->_set_parse_errors(\@errors);
    return;
  }

  $worksheet = ( $excel_obj->worksheets() )[0]; #support only one worksheet
  my ( $row_min, $row_max ) = $worksheet->row_range();
  my ( $col_min, $col_max ) = $worksheet->col_range();
  if (($col_max - $col_min)  < 2 || ($row_max - $row_min) < 1 ) { #must have header and at least one row of plot data
    push @errors, "Spreadsheet is missing header or contains no rows";
    $self->_set_parse_errors(\@errors);
    return;
  }

  #get column headers
  my $plot_name_head;
  my $accession_name_head;
  my $plot_number_head;
  my $block_number_head;
  my $is_a_control_head;

  if ($worksheet->get_cell(0,0)) {
    $plot_name_head  = $worksheet->get_cell(0,0)->value();
  }
  if ($worksheet->get_cell(0,1)) {
    $accession_name_head  = $worksheet->get_cell(0,1)->value();
  }
  if ($worksheet->get_cell(0,2)) {
    $plot_number_head  = $worksheet->get_cell(0,2)->value();
  }
  if ($worksheet->get_cell(0,3)) {
    $block_number_head  = $worksheet->get_cell(0,3)->value();
  }
  if ($worksheet->get_cell(0,4)) {
    $is_a_control_head  = $worksheet->get_cell(0,4)->value();
  }

  if (!$plot_name_head || $plot_name_head ne 'plot_name' ) {
    push @errors, "Cell A1: plot_name is missing from the header";
  }
  if (!$accession_name_head || $accession_name_head ne 'accession_name') {
    push @errors, "Cell B1: accession_name is missing from the header";
  }
  if (!$plot_number_head || $plot_number_head ne 'plot_number') {
    push @errors, "Cell C1: plot_number is missing from the header";
  }
  if (!$block_number_head || $block_number_head ne 'block_number') {
    push @errors, "Cell D1: block_number is missing from the header";
  }
  if ($is_a_control_head && $is_a_control_head ne 'is_a_control') {
    push @errors, "Cell D1: Column D should contain the header \"is_a_control\"";
  }

  for my $row ( 1 .. $row_max ) {
    my $row_name = $row+1;
    my $plot_name;
    my $accession_name;
    my $plot_number;
    my $block_number;
    my $is_a_control;

    if ($worksheet->get_cell($row,0)) {
      $plot_name = $worksheet->get_cell($row,0)->value();
    }
    if ($worksheet->get_cell($row,1)) {
      $accession_name = $worksheet->get_cell($row,1)->value();
    }
    if ($worksheet->get_cell($row,2)) {
      $plot_number =  $worksheet->get_cell($row,2)->value();
    }
    if ($worksheet->get_cell($row,3)) {
      $block_number =  $worksheet->get_cell($row,3)->value();
    }
    if ($worksheet->get_cell($row,4)) {
      $is_a_control =  $worksheet->get_cell($row,4)->value();
    }

    #skip blank lines
    if (!$plot_name && !$accession_name && !$plot_number && !$block_number) {
      next;
    }

    #plot_name must not be blank
    if (!$plot_name || $plot_name eq '') {
      push @errors, "Cell A$row_name: plot name missing";
    } else {
      #plot must not already exist in the database
      if ($self->_get_stock($plot_name)) {
	push @errors, "Cell A$row_name: plot name already exists: $plot_name";
      }
      #file must not contain duplicate plot names
      if ($seen_plot_names{$plot_name}) {
	push @errors, "Cell A$row_name: duplicate plot name at cell A".$seen_plot_names{$plot_name}.": $plot_name";
      }
      $seen_plot_names{$plot_name}=$row_name;
    }

    #accession name must not be blank
    if (!$accession_name || $accession_name eq '') {
      push @errors, "Cell B$row_name: accession name missing";
    } else {
      #accession name must exist in the database
      if (!$self->_get_accession($accession_name)) {
	push @errors, "Cell B$row_name: accession name does not exist: $accession_name";
      }
    }

    #plot number must not be blank
    if (!$plot_number || $plot_number eq '') {
      push @errors, "Cell C$row_name: plot number missing";
    }
    #plot number must be a positive integer
    if (!($plot_number =~ /^\d+?$/)) {
      push @errors, "Cell C$row_name: plot number is not a positive integer: $plot_number";
    }
    #block number must not be blank
    if (!$block_number || $block_number eq '') {
      push @errors, "Cell D$row_name: block number missing";
    }
    #block number must be a positive integer
    if (!($block_number =~ /^\d+?$/)) {
      push @errors, "Cell D$row_name: block number is not a positive integer: $block_number";
    }
    if ($is_a_control) {
      #is_a_control must be either yes, no 1, 0, or blank
      if (!($is_a_control eq "yes" || $is_a_control eq "no" || $is_a_control eq "1" ||$is_a_control eq "0" || $is_a_control eq '')) {
	push @errors, "Cell E$row_name: is_a_control is not either yes, no 1, 0, or blank: $is_a_control";
      }
    }
  }

  #store any errors found in the parsed file to parse_errors accessor
  if (scalar(@errors) >= 1) {
    $self->_set_parse_errors(\@errors);
    return;
  }

  return 1; #returns true if validation is passed

}


sub _parse_with_plugin {
  my $self = shift;
  my $filename = $self->get_filename();
  my $schema = $self->get_chado_schema();
  my $parser   = Spreadsheet::ParseExcel->new();
  my $excel_obj;
  my $worksheet;
  my %design;

  $excel_obj = $parser->parse($filename);
  if ( !$excel_obj ) {
    return;
  }

  $worksheet = ( $excel_obj->worksheets() )[0];
  my ( $row_min, $row_max ) = $worksheet->row_range();
  my ( $col_min, $col_max ) = $worksheet->col_range();

  for my $row ( 1 .. $row_max ) {
    my $plot_name;
    my $accession_name;
    my $plot_number;
    my $block_number;
    my $is_a_control;

    if ($worksheet->get_cell($row,0)) {
      $plot_name = $worksheet->get_cell($row,0)->value();
    }
    if ($worksheet->get_cell($row,1)) {
      $accession_name = $worksheet->get_cell($row,1)->value();
    }
    if ($worksheet->get_cell($row,2)) {
      $plot_number =  $worksheet->get_cell($row,2)->value();
    }
    if ($worksheet->get_cell($row,3)) {
      $block_number =  $worksheet->get_cell($row,3)->value();
    }
    if ($worksheet->get_cell($row,4)) {
      $is_a_control =  $worksheet->get_cell($row,4)->value();
    }

    #skip blank lines
    if (!$plot_name && !$accession_name && !$plot_number && !$block_number) {
      next;
    }

    my $key = $row;
    $design{$key}->{plot_name} = $plot_name;
    $design{$key}->{stock_name} = $accession_name;
    $design{$key}->{plot_number} = $plot_number;
    $design{$key}->{block_number} = $block_number;
    if ($is_a_control) {
      $design{$key}->{is_a_control} = 1;
    } else {
      $design{$key}->{is_a_control} = 0;
    }
  }

  $self->_set_parsed_data(\%design);

  return 1;

}


sub _get_accession {
  my $self = shift;
  my $accession_name = shift;
  my $chado_schema = $self->get_chado_schema();
  my $stock_lookup = CXGN::Stock::StockLookup->new(schema => $chado_schema);
  my $stock;
  my $accession_cvterm = $chado_schema->resultset("Cv::Cvterm")
    ->create_with({
 		   name   => 'accession',
 		   cv     => 'stock type',
 		   db     => 'null',
 		   dbxref => 'accession',
 		  });
  $stock_lookup->set_stock_name($accession_name);
  $stock = $stock_lookup->get_stock();

  if (!$stock) {
    return;
  }

  if ($stock->type_id() != $accession_cvterm->cvterm_id()) {
    return;
   }

  return $stock;

}


sub _get_stock {
  my $self = shift;
  my $stock_name = shift;
  my $chado_schema = $self->get_chado_schema();
  my $stock_lookup = CXGN::Stock::StockLookup->new(schema => $chado_schema);
  my $stock;

  $stock_lookup->set_stock_name($stock_name);
  $stock = $stock_lookup->get_stock();

  if (!$stock) {
    return;
  }

  return $stock;
}


1;

