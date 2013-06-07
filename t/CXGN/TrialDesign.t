use strict;
use warnings;

use Test::More tests=>61;

BEGIN {use_ok('CXGN::TrialDesign');}

BEGIN {require_ok('Moose');}
BEGIN {require_ok('MooseX::FollowPBP');}
BEGIN {require_ok('Moose::Util::TypeConstraints');}
BEGIN {require_ok('Try::Tiny');}
BEGIN {require_ok('R::YapRI::Base');}
BEGIN {require_ok('R::YapRI::Data::Matrix');}

my @stock_names = ("A","B","C","D","E","F","G","H");
my @control_names = ("C1","C2","C3");
my $number_of_blocks = 8;
my $number_of_reps = 4;
my $block_size = 20;
my $maximum_block_size = 30;
my $plot_name_prefix = "pre_";
my $plot_name_suffix = "_suf";
my $plot_start_number = 101;
my $plot_number_increment = 10;
my $randomization_method = "Super-Duper";
my $design_type = "RCBD";
my %design;

ok(my $trial_design = CXGN::TrialDesign->new(), "Create TrialDesign object");
ok($trial_design->set_stock_list(\@stock_names), "Set stock names for trial design");
is_deeply($trial_design->get_stock_list(),\@stock_names, "Get stock names for trial design");
ok($trial_design->set_control_list(\@control_names), "Set control names for trial design");
is_deeply($trial_design->get_control_list(),\@control_names, "Get control names for trial design");
ok($trial_design->set_number_of_blocks($number_of_blocks), "Set number of blocks for trial design");
is_deeply($trial_design->get_number_of_blocks(),$number_of_blocks, "Get number of blocks for trial design");
ok($trial_design->set_number_of_reps($number_of_reps), "Set number of reps for trial design");
is_deeply($trial_design->get_number_of_reps(),$number_of_reps, "Get number of reps for trial design");
ok($trial_design->set_block_size($block_size), "Set block size for trial design");
is_deeply($trial_design->get_block_size(),$block_size, "Get block size for trial design");
ok($trial_design->set_maximum_block_size($maximum_block_size), "Set maximum block size for trial design");
is_deeply($trial_design->get_maximum_block_size(),$maximum_block_size, "Get maximum block size for trial design");
ok($trial_design->set_plot_name_prefix($plot_name_prefix), "Set plot name prefix for trial design");
is_deeply($trial_design->get_plot_name_prefix(),$plot_name_prefix, "Get plot name prefix for trial design");
ok($trial_design->set_plot_name_suffix($plot_name_suffix), "Set plot name suffix for trial design");
is_deeply($trial_design->get_plot_name_suffix(),$plot_name_suffix, "Get plot name suffix for trial design");
ok($trial_design->set_plot_start_number($plot_start_number), "Set plot start number for trial design");
is_deeply($trial_design->get_plot_start_number(),$plot_start_number, "Get plot start number for trial design");
ok($trial_design->set_plot_number_increment($plot_number_increment), "Set plot number increment for trial design");
is_deeply($trial_design->get_plot_number_increment(),$plot_number_increment, "Get plot number increment for trial design");
ok($trial_design->set_randomization_method($randomization_method), "Set randomization method for trial design");
is_deeply($trial_design->get_randomization_method(),$randomization_method, "Get randomization method for trial design");
ok($trial_design->set_design_type($design_type), "Set design type for trial design");
is_deeply($trial_design->get_design_type(),$design_type, "Get design type for trial design");
ok($trial_design->calculate_design(), "Calculate trial design");
ok(%design = %{$trial_design->get_design()}, "Get trial design");
ok(scalar(keys %design) == scalar(@stock_names) * $number_of_blocks,"Result of RCBD design has a number of plots equal to the number of stocks times the number of blocks");
ok($design{$plot_start_number}->{stock_name} eq $stock_names[0],"First plot has correct stock name");
ok($design{$plot_start_number}->{block_number} == 1, "First plot is in block 1");
ok($design{$plot_start_number+$plot_number_increment}->{stock_name} eq $stock_names[1], "Second plot has correct stock name");
ok($design{$plot_start_number}->{plot_name} eq $plot_name_prefix.$plot_start_number.$plot_name_suffix,"Plot names contain prefix and suffix");
ok($trial_design->set_plot_start_number(1), "Change plot start number for trial design to 1");
ok($trial_design->set_plot_number_increment(1), "Change plot number increment for trial design to 1");
ok($trial_design->calculate_design(), "Calculate design with plot start number and increment set to 1");
ok(%design = %{$trial_design->get_design()}, "Get trial design with plot start number and increment set to 1");
ok($design{1}->{stock_name} eq $stock_names[0],"First plot has correct stock name when plot number and increment are 1");
ok($design{2}->{stock_name} eq $stock_names[1],"Second plot has correct stock name when plot number and increment are 1");
ok($design{3}->{stock_name} eq $stock_names[2],"Third plot has correct stock name when plot number and increment are 1");
ok($trial_design->set_plot_start_number(-2), "Change plot start number for trial design to -2");
ok($trial_design->calculate_design(), "Calculate trial design with a negative plot start number");
ok(%design = %{$trial_design->get_design()}, "Get trial design with a negative plot start number");
ok($design{-2}->{stock_name} eq $stock_names[0],"First plot has correct stock name with a negative plot start number");
ok($design{-1}->{stock_name} eq $stock_names[1],"Second plot has correct stock name with a negative plot start number");
ok($design{0}->{stock_name} eq $stock_names[2],"Third plot has correct stock name with a negative plot start number");
ok($design{1}->{stock_name} eq $stock_names[3],"Fourth plot has correct stock name with a negative plot start number");
ok($trial_design->set_plot_start_number(2), "Change plot start number for trial design to 2");
ok($trial_design->set_plot_number_increment(-1), "Change plot number increment for trial design to -1");
ok($trial_design->calculate_design(), "Calculate trial design with a negative plot number increment");
ok(%design = %{$trial_design->get_design()}, "Get trial design with a negative plot number increment");
ok($design{2}->{stock_name} eq $stock_names[0],"First plot has correct stock name with a negative plot number increment");
ok($design{1}->{stock_name} eq $stock_names[1],"Second plot has correct stock name with a negative plot number increment");
ok($design{0}->{stock_name} eq $stock_names[2],"Third plot has correct stock name with a negative plot number increment");
ok($design{-1}->{stock_name} eq $stock_names[3],"Fourth plot has correct stock name with a negative plot number increment");