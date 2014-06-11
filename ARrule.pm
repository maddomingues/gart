use strict;

package ARrule;

#use Exception qw(:debug);
#Exception->debugLevel(DEBUG_STACK);


my(@s_gen, @pos_all_gen, @set_spec_rules_id, @gen_items, $side, $ruleID, $s_not_gen, $tc, $qty_itens_gen, $item_gen, $pos_item_gen, $err);
# @s_gen - rule side that will be generalized
# @pos_all_gen - store the position of all generalized itens
# @set_spec_rules_id - store the rule ID of specific rules used in the generalization
# $side - store the side that will be generalized
# $ruleID - rule ID
# $s_not_gen - rule side that will not be generalized
# $tc - contigency table of association rule
# $qty_itens_gen - quantity of itens generalized
# $item_gen - store the last generalized item
# $pos_item_gen - store the position of last generalized item


#---------------------------------------------------------------------------
# Constructor Method
#---------------------------------------------------------------------------
# Make a data structure for store a association rule
# Require: side that will be generalized ("left" or "right"), left and right 
# side of association rule (two strings with itens separeted for ";"), contigency table of 
# association rule (string)
#---------------------------------------------------------------------------
sub new{
    my $class = shift;
    my $self = {
        side => "",
        ruleID => "",
        set_spec_rules_id => [],
        s_gen => [],
        gen_items => [], 
        s_not_gen => "", 
        tc => "", 
        qty_itens_gen => 0, 
        item_gen => "", 
        pos_all_gen => [],
        pos_item_gen => -1
    };
    bless($self, $class);
    $self->init(@_); #initialize the data structure that will store the association rule

    return $self;
}


#---------------------------------------------------------------------------
# sub init - Set a association rule
# Require: side that will be generalized ("left" or "right"), left and right 
# side of association rule (two strings with itens separeted for ";"), contigency table of 
# association rule (string)
#---------------------------------------------------------------------------
sub init{
    my $class =  shift;
    $class->{side} = shift; # set the side of the generalization
    $class->{ruleID} = shift; # ID of rule
    
    $class->{ruleID} =~ s/\[//g;
    $class->{ruleID} =~ s/\]//g; 
    
    push(@{$class->{set_spec_rules_id}},$class->{ruleID});

    my $i;
    my $lhs = $_[0]; # set lhs
    my $rhs = $_[1]; # set rhs
    $lhs =~ s/ //g; # remove space among rule itens
    $rhs =~ s/ //g; # remove space among rule itens

    # check what side will be generalized
    if($class->{side} eq "RIGHT"){ # generalize the right side

        $class->{s_not_gen} = $lhs; #set the side that will not be generalized with left side of rule
        $rhs =~ s/\(//g; #allow generalize rules sets generalized
        $rhs =~ s/\)//g; #allow generalize rules sets generalized
        @{$class->{s_gen}} = split(/&/, $rhs); #set the side that will be generalized with right side of rule
        
        for($i=0; ($i < $#{$class->{s_gen}} + 1); $i++){
            my @temp;
            push(@temp, ${$class->{s_gen}}[$i]);
            push(@{$class->{gen_items}}, [@temp]);
        }
        
        $class->{tc} = $_[2]; #set the contigency table

    }
    elsif($class->{side} eq "LEFT"){ # generalize the left side
        
        $class->{s_not_gen} = $rhs; #set the side that will not be generalized with right side of rule
        $lhs =~ s/\(//g; #allow generalize rules sets generalized
        $lhs =~ s/\)//g; #allow generalize rules sets generalized
        @{$class->{s_gen}} = split(/&/, $lhs); #set the side that will be generalized with left side of rule
        
        for($i=0; ($i < $#{$class->{s_gen}} + 1); $i++){
            my @temp;
            push(@temp, ${$class->{s_gen}}[$i]);
            push(@{$class->{gen_items}}, [@temp]);
        }
        
        $class->{tc} = $_[2]; #set the contigency table

    }
    else{
        #$err = Exception->new('EnvironmentError');
        #$err->exitcode(-1);
        #$err->raise("Error -1: The value $class->{side} is wrong.\n This value must be left or right.");

        print "The value $class->{side} is wrong.\n This value must be left or right.";
        exit(1);
    }        
}


#---------------------------------------------------------------------------
# sub generalizeOneRule - Generalize only an item of each association rule
# Require: generalization name and the specific itens set that will be generalized
# in each association rule
#---------------------------------------------------------------------------
sub generalizeOneRule{
    my $class = shift;
    my $oneTaxonomy = $_[0];
    my $fatherItem = $oneTaxonomy->getFatherItem; # father item
    my @childrenItens = $oneTaxonomy->getChildrenItens; # children itens that will be generalized
    my ($i, $j, $stopGen, $stopRule); #temporary variables
    $stopGen = 0; #check if yet not generalized an item of association rule

    for($i=0; ( ( $i < ($#childrenItens + 1) ) && ( $stopGen != 2 ) ); $i++){
        $stopRule = 0; 
        for($j=0; ( ( $j < ($#{$class->{s_gen}} + 1) ) && ( $stopRule != 1 ) ); $j++){
            if($childrenItens[$i] eq ${$class->{s_gen}}[$j]){ # check it there is itens for generalize
                if($stopGen == 0){ # do the generalization of an item
                    $stopGen = 1;
                    $stopRule = 1;
                    $class->{item_gen} = ${$class->{s_gen}}[$j];
                    $class->{pos_item_gen} = $j;
                    ${$class->{s_gen}}[$j] = "($fatherItem)";
                    ${$class->{gen_items}}[$j] = [@childrenItens];
                }
                else{ # undo the generalization of an item
                    $stopGen = 2;
                    $stopRule = 1; 
                    $class->undoGeneralization; #undo the last generalization                  
                }
            }
        }
    }
}


#---------------------------------------------------------------------------
# sub compare - Check if two association rules are equals
# Require: One itens array (one rule) for checking
#---------------------------------------------------------------------------
sub compare{
    my $class = shift;
    my @i2c = @_; # itens to comparation
    my ($answer, $i, $j);
        
    # Check if two association rules are equals 
    # "Verify if the indexs of last element of each array are equal"
    if($#i2c == $#{$class->{s_gen}}){
        $answer = 1;
        for($i=0; ($i < ($#i2c + 1)) && ($answer == 1); $i++){
            $answer = 0;
            for($j=0; ($j < ($#{$class->{s_gen}} + 1)) && ($answer == 0); $j++){
                if($i2c[$i] eq ${$class->{s_gen}}[$j]){
                    $answer = 1;
                }
            }
        }
    }
    else{
        $answer = 0;
    }

    return $answer;
}


#---------------------------------------------------------------------------
# sub calcTC - Calc the contigency table to generalized association rule and
# store in the Rulebase
# Require: "stem" with the Rulebase name where will be stored the generalized
#association rules
#---------------------------------------------------------------------------
sub calcTC{
    my $class = shift;
    my $dataSet = $_[0];
    my $taxonomySet = $_[1];
    my $sizeDataSet = scalar(@{$dataSet}); #size of data set
    my $sizeTaxonomySet = scalar(@{$taxonomySet}); #size of taxonomy set
    my (@not_gen_items, $i, $j, $k, $t);

    my $LHSRHS = 0; #record number of database where LHS and RHS are true
    my $notLHSRHS = 0; #record number of database where LHS is false and RHS is true
    my $LHSnotRHS = 0; #record number of database where LHS is true and RHS is false
    my $notLHSnotRHS = 0; #record number of database where LHS and RHS are false
    my $N = 0; #record number of database
    
    #check if the rule is one generalized association rule
    if($class->{qty_itens_gen} > 0){
    
        #make an array ("@not_gen_items") with itens of not generalized side of rule
        @not_gen_items = split(/&/, $class->{s_not_gen});
        
        if($class->{side} eq "RIGHT"){ #check if the generalization side is the right side
         
            #compare each rule with the database to make the contigency table of rule
            for($t=0; $t < $sizeDataSet; $t++){
                $N = $N + 1;
                my $answer_comp_gen = 1; #store if the generalized side of rule cover one database record
                my $answer_comp_not_gen = 1; #store if the not generalized side of rule cover one database record
 
                #check the cover of generelized side of rule
                for($i=0; ($i < ($#{$class->{gen_items}} + 1)) && ($answer_comp_gen == 1); $i++){
                    $answer_comp_gen = 0;
                    for($j=0; ($j < ($#{${$class->{gen_items}}[$i]} + 1)) && ($answer_comp_gen == 0); $j++){
                        for($k=0; ($k < ($#{$dataSet->[$t]} + 1)) && ($answer_comp_gen == 0); $k++){
                            if(${$class->{gen_items}}[$i][$j] eq $dataSet->[$t][$k]){
                                $answer_comp_gen = 1;  
                            }
                        }
                    }
                }
            
                #check the cover of not generelized side of rule
                for($i=0; ($i < ($#not_gen_items + 1)) && ($answer_comp_not_gen == 1); $i++){
                    $answer_comp_not_gen = 0;
                    for($j=0; ($j < ($#{$dataSet->[$t]} + 1)) && ($answer_comp_not_gen == 0); $j++){
                        if($not_gen_items[$i] eq $dataSet->[$t][$j]){
                            $answer_comp_not_gen = 1;
                        }
                    }
                }
            
                # Set up the values of contigency table
                if( ($answer_comp_gen == 1) && ($answer_comp_not_gen == 1) ){
                    $LHSRHS = $LHSRHS + 1;
                }
                elsif( ($answer_comp_gen == 1) && ($answer_comp_not_gen == 0) ){
                    $notLHSRHS = $notLHSRHS + 1;
                }
                elsif( ($answer_comp_gen == 0) && ($answer_comp_not_gen == 1) ){
                    $LHSnotRHS = $LHSnotRHS + 1;
                }
                else{
                    $notLHSnotRHS = $notLHSnotRHS + 1;
                }
            }
    
        }
        else{ #else the generalization side is the left side
        
            #compare each rule with the database to make the contigency table of rule
            for($t=0; $t < $sizeDataSet; $t++){
                $N = $N + 1;
                my $answer_comp_gen = 1; #store if the generalized side of rule cover one database record
                my $answer_comp_not_gen = 1; #store if the not generalized side of rule cover one database record
 
                #check the cover of generelized side of rule
                for($i=0; ($i < ($#{$class->{gen_items}} + 1)) && ($answer_comp_gen == 1); $i++){
                    $answer_comp_gen = 0;
                    for($j=0; ($j < ($#{${$class->{gen_items}}[$i]} + 1)) && ($answer_comp_gen == 0); $j++){
                        for($k=0; ($k < ($#{$dataSet->[$t]} + 1)) && ($answer_comp_gen == 0); $k++){
                            if(${$class->{gen_items}}[$i][$j] eq $dataSet->[$t][$k]){
                                 $answer_comp_gen = 1;  
                            }
                        }
                    }
                }
            
                #check the cover of not generelized side of rule
                for($i=0; ($i < ($#not_gen_items + 1)) && ($answer_comp_not_gen == 1); $i++){
                    $answer_comp_not_gen = 0;
                    for($j=0; ($j < ($#{$dataSet->[$t]} + 1)) && ($answer_comp_not_gen == 0); $j++){
                        if($not_gen_items[$i] eq $dataSet->[$t][$j]){
                            $answer_comp_not_gen = 1;
                        }
                    }
                }
            
                # Set up the values of contigency table
                if( ($answer_comp_gen == 1) && ($answer_comp_not_gen == 1) ){
                    $LHSRHS = $LHSRHS + 1;
                }
                elsif( ($answer_comp_gen == 1) && ($answer_comp_not_gen == 0) ){
                    $LHSnotRHS = $LHSnotRHS + 1;
                }
                elsif( ($answer_comp_gen == 0) && ($answer_comp_not_gen == 1) ){
                    $notLHSRHS = $notLHSRHS + 1;
                }
                else{
                    $notLHSnotRHS = $notLHSnotRHS + 1;
                }
            }
        }
                
        
        #make the new contigency table
        $LHSRHS = sprintf("%0.6f",($LHSRHS / $N));
        $LHSnotRHS = sprintf("%0.6f",($LHSnotRHS / $N));
        $notLHSRHS = sprintf("%0.6f",($notLHSRHS / $N));
        $notLHSnotRHS = sprintf("%0.6f",($notLHSnotRHS / $N));
        
        $class->{tc} = "\[$LHSRHS,$LHSnotRHS,$notLHSnotRHS,$notLHSRHS,$N\]";
        
        #sort the generalized itens
        @{$class->{s_gen}} = sort(@{$class->{s_gen}}); 
        
        $class->{s_not_gen} =~ s/&/ & /g; #format not generalized side of rule
    }
}


#---------------------------------------------------------------------------
# sub setRuleID - Set the rule ID
#---------------------------------------------------------------------------
sub setRuleID{
    my $class = shift;
    my $id = shift;
    $class->{ruleID} = sprintf("R%04d",$id);
}


#---------------------------------------------------------------------------
# sub getRuleID - Get the rule ID
#---------------------------------------------------------------------------
sub getRuleID{
    my $class = shift;
    return $class->{ruleID};
}


#---------------------------------------------------------------------------
# sub undoGeneralization - Undo the last generalization
#---------------------------------------------------------------------------
sub undoGeneralization{
    my $class = shift;
    ${$class->{s_gen}}[$class->{pos_item_gen}] = $class->{item_gen};
    my @temp;
    push(@temp,$class->{item_gen});
    ${$class->{gen_items}}[$class->{pos_item_gen}] = [@temp];
    $class->{item_gen} = "";
    $class->{pos_item_gen} = -1;
}


#---------------------------------------------------------------------------
# sub increaseQtyItensGen - Increase in 1 the account of generalized itens
#---------------------------------------------------------------------------
sub increaseQtyItensGen{
    my $class = shift;
    $class->{qty_itens_gen} = $class->{qty_itens_gen} + 1;
}


#---------------------------------------------------------------------------
# sub getPosItemGen - Return the position of last generalized item
#---------------------------------------------------------------------------
sub getPosItemGen{
    my $class = shift;
    return $class->{pos_item_gen};
}


#---------------------------------------------------------------------------
# sub resetRule - set the values of item_gen and pos_item_gen to "" and -1.
# Also insert the position of last generalization in the array "pos_all_gen" 
# that store the positions of all the generalized itens
#---------------------------------------------------------------------------
sub resetRule{
    my $class = shift;
    $class->{item_gen} = "";
    $class->{pos_item_gen} = -1;
}


#---------------------------------------------------------------------------
# sub getSideGen - Return the side of a rule that will be generalized
#---------------------------------------------------------------------------
sub getSideGen{
    my $class = shift;
    return @{$class->{s_gen}};
}


#---------------------------------------------------------------------------
# sub getSideNotGen - Return the side of a rule that will not be generalized
#---------------------------------------------------------------------------
sub getSideNotGen{
    my $class = shift;
    return $class->{s_not_gen};
}


#---------------------------------------------------------------------------
# sub getTC - Return the Contingency Table
#---------------------------------------------------------------------------
sub getTC{
    my $class = shift;
    return $class->{tc};
}


#---------------------------------------------------------------------------
# sub getSpecRuleIDSet - Return the rule ID
#---------------------------------------------------------------------------
sub getSpecRuleIDSet{
    my $class = shift;
    return @{$class->{set_spec_rules_id}};
}


#---------------------------------------------------------------------------
# sub setSpecRuleIDSet - Set the specific rules ID set of a generalized rule
#---------------------------------------------------------------------------
sub setSpecRuleIDSet{
    my $class = shift;
    my @RuleIDSet = @_;
    my $stop;
    my ($i, $j);

    #make the union of the two set (array)
    for($i=0; $i < ($#RuleIDSet + 1); $i++){
        $stop = 0;
        for($j=0; ($j < ($#{$class->{set_spec_rules_id}} + 1)) && ($stop == 0); $j++){
            if($RuleIDSet[$i] eq ${$class->{set_spec_rules_id}}[$j]){
                $stop = 1;
            }
        }
        if($stop == 0){
            push(@{$class->{set_spec_rules_id}},$RuleIDSet[$i]);
        }
    }
}


1; # return of the class
