#!/usr/bin/perl


#------------------------------------------------------------------
# This script call the algorithm IGART - Interactive Generalization of Association Rules using Taxonomy
#
# pre-condition
#
# pos-condition
#
# 28-11-2003 modifications by Marcos A. Domingues
#
# arguments
#       0 - <rule base name>
#       1 - <side of generalization - left or right>
#
# optionally
#       2 - -onlyreport (make reports)
#       3 - -sort (sort the taxonomies file)
#
#------------------------------------------------------------------


use strict;
use ARigart; 

if ($#ARGV < 1){
    die "usage: ./generalize.pl <rule_base> <side of generalization (left or right)> [-onlyreport] [-sort] \n";
}

my $ruleBaseName = $ARGV[0];
my $side = $ARGV[1];
my $all_info = 1;
my $sort = 0;

my $obj;

foreach (@ARGV){
    if (/-onlyreport/){
        $all_info = 0;
    }
    if (/-sort/){
        $sort = 1
    }
}

#call algorithm
$obj = ARigart->newCommandLine($ruleBaseName,$side,$all_info,$sort); #"file_teste/tmp","left"
#$obj->groupAssocRules;
$obj->alg_igart;
