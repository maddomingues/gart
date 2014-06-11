use strict;

use ARrule;
use ARtaxonomy;

#use Exception qw(:debug);
#Exception->debugLevel(DEBUG_STACK);

package ARigart;


my($stem, $databaseFile, $side, $ID, $report, $sortTaxonomy, $nRulesNotGen, $err);
# $stem - nome of rule sets
# $side - side that will be generalized
# $ID - counter of the rule ID


#---------------------------------------------------------------------------
# Constructor Method - Used in the RulEE-GAR Enviromment
#---------------------------------------------------------------------------
# Set the values to $stem, $side and database
# Require: stem, side of the generalization and database name
#---------------------------------------------------------------------------
sub newWeb{
    my $class = shift;
    my $self = {
        stem => shift,
        side => shift,
        databaseFile => shift,
        report => -1, # dont make report
        sortTaxonomy => 0, # dont sort
        nRulesNotGen => 0,
        ID => 1,
    };

    bless($self, $class);
    $self->{side} = "\U$self->{side}\E"; #upcase the string side

    return $self;
}


#---------------------------------------------------------------------------
# Constructor Method - Used in command line programs
#---------------------------------------------------------------------------
# Set the values to $stem and $side
# Require: stem and side of the generalization
#---------------------------------------------------------------------------
sub newCommandLine{
    my $class = shift;
    my $self = {
        stem => shift,
        side => shift,
        report => shift,
        sortTaxonomy => shift,
        nRulesNotGen => 0,
        databaseFile => "",
        ID => 1,
    };

    bless($self, $class);
    $self->{databaseFile} = $self->{stem};
    $self->{side} = "\U$self->{side}\E"; #upcase the string side

    return $self;
}


#---------------------------------------------------------------------------
# The algorithm IGART - Interactive Generalization of Association Rules using Taxonomy
#---------------------------------------------------------------------------
sub alg_igart{
    my $class = shift;
    my $fileName = $class->{stem} . ".apr.dcar"; #rule filename in the standard format
    my $fileDataName = $class->{databaseFile} . ".apr.data"; #file name of database                    
    my $fileGenName = $class->{stem} . ".tax"; #generalizations filename
                                                                          
    my(@std_ar_prev, @set_of_rules, @set_of_rules_temp, @set_of_rules_gen, @set_of_taxonomies, @set_of_data, @temp, $aRule, $one_taxonomy, $i, $j);


    # make the taxonomy set for generalize the association rules
    open(ARQ_GENERALIZED,"< $fileGenName") || die "Cold not open file of generalized itens.";
    foreach(<ARQ_GENERALIZED>){
        $_ =~ s/\)//;
        @temp = split(/\(/, $_);
        chop($temp[1]);
        $one_taxonomy = ARtaxonomy->new($temp[0], $temp[1]);
        push(@set_of_taxonomies, $one_taxonomy);
    }
    close(ARQ_GENERALIZED); # close taxonomies file

    # sort taxonomies file
    if ($class->{sortTaxonomy} == 1){
        $class->sortTaxonomies(\@set_of_taxonomies);
    }


    # open rules file for generalization
    open(ARQ_ENTRADA,"< $fileName") || die "Cold not open file of rules.";
    foreach(<ARQ_ENTRADA>){
        $class->{nRulesNotGen} = $class->{nRulesNotGen} + 1; # count the number of rules didnt generalize
        chop($_);
        @temp = split(/,\[/, $_);
        @std_ar_prev = split(/,/, $temp[0]);
        push(@std_ar_prev, ("\[".$temp[1])); 
        $aRule = ARrule->new($class->{side}, $std_ar_prev[0], $std_ar_prev[1], $std_ar_prev[2], $std_ar_prev[3]);
        push(@set_of_rules, $aRule);
    }
    close(ARQ_ENTRADA); # close rules file
    
    if(scalar(@set_of_rules) > 0){
        push(@set_of_rules_temp, $set_of_rules[0]);
        splice(@set_of_rules,0,1);

        while(scalar(@set_of_rules) > 0){
           
            # group rules with same antecedent or consequent (depends of generalization side)
            if( ($set_of_rules_temp[0]->getSideNotGen) eq ($set_of_rules[0]->getSideNotGen) ){
                push(@set_of_rules_temp, $set_of_rules[0]);
                splice(@set_of_rules,0,1);
            }
            else{
            
                # algorithm that generalize a association rules set with same antecedent or consequent (depends of generalization side)
                $class->generalizeRules(\@set_of_rules_temp,\@set_of_taxonomies);
               
                # store the generalized rules
                for($i=0; $i < scalar(@set_of_rules_temp); $i++){
                    push(@set_of_rules_gen,$set_of_rules_temp[$i]);
                }
                
                # start a new rules set with same antecedent or consequent
                @set_of_rules_temp = ();
                
                push(@set_of_rules_temp, $set_of_rules[0]);
                splice(@set_of_rules,0,1);
            }
        }
        
        # algorithm that generalize a association rules set with same antecedent or consequent (depends of generalization side)
        # It's done to the last association rules set with same antecedent or consequent.
        $class->generalizeRules(\@set_of_rules_temp,\@set_of_taxonomies);
        
        # store the generalized rules
        for($i=0; $i < scalar(@set_of_rules_temp); $i++){
            push(@set_of_rules_gen,$set_of_rules_temp[$i]);
        }
        
        # start a new rules set with same antecedent or consequent
        @set_of_rules_temp = ();        
    }
    else{ # There are not rules to generalization
        #$err = Exception->new('EnvironmentError');
        #$err->exitcode(-2);
        #$err->raise("Error -2: There are not rules to generalization.\n");
        
        print "There are not rules to generalization.\n";
        exit(2);
    }
    
    # open data file for calc the TC
    open(DATAFILE,"< $fileDataName") || die "Cold not open file of data.";
    foreach(<DATAFILE>){
        chop($_);
        my @temp_data = split(/ /, $_);
        push(@set_of_data, [@temp_data]);
    }
    close(DATAFILE); # close data file
    
    # Calc the contigency table to generalized rules and set the it's rule ID
    for($j=0; $j < scalar(@set_of_rules_gen); $j++){
        $set_of_rules_gen[$j]->setRuleID($class->{ID}); #set the new rule ID after of the generalization
        $class->{ID} = $class->{ID} + 1; #increase the rule ID
        $set_of_rules_gen[$j]->calcTC(\@set_of_data, \@set_of_taxonomies);
    }

    # make the output reports
    $class->makeReports(\@set_of_rules_gen);
}


#---------------------------------------------------------------------------
# generalizeRules is the function that with a rule set (with same antecedent or consequent - 
# depends of generalization side) e with a generalization set generalize the rule set reduce the 
# rule volume.
# Require: an array that represent one rule set and one that represent generalization set
#---------------------------------------------------------------------------
sub generalizeRules{
    my $class = shift;
    my $rulesSet = $_[0]; #rules set to generalization
    my $taxonomiesSet = $_[1]; #taxonomy set used
    my $sizeTaxonomiesSet = scalar(@{$taxonomiesSet}); #size of generalization set
    my @ruleSetTemp = ();
    my($i, $j);
        
    # analize the rules for each generalization
    for($i=0; $i < $sizeTaxonomiesSet; $i++){
        
        #generalize a item of each rule
        for($j=0; $j < scalar(@{$rulesSet}); $j++){
            $rulesSet->[$j]->generalizeOneRule($taxonomiesSet->[$i]);
        } 

        #group equal rules and remove the repeted rules
        while(scalar(@{$rulesSet}) > 0){
            my @equalSets = ();
            my @itens2comp;
            @itens2comp = $rulesSet->[0]->getSideGen; 

            #store the indication the equal rules in an array (@equalSets)
            for($j=0; $j < scalar(@{$rulesSet}); $j++){
                if ($rulesSet->[$j]->compare(@itens2comp)){
                    push(@equalSets,$j);
                }
            }

            #check if the equivalent rules number is equal the specific itens number in a generalization
            if((($#equalSets + 1) == $taxonomiesSet->[$i]->getNumberChildrenItens) && ($rulesSet->[$equalSets[0]]->getPosItemGen != -1)){ #if is equal then generalize the rules
                $rulesSet->[0]->increaseQtyItensGen;
                $rulesSet->[0]->resetRule;

                for($j=$#equalSets; $j > 0; $j--){ 
                    #store ID of specific rules that gave origin the generalized rule
                    $rulesSet->[0]->setSpecRuleIDSet($rulesSet->[$equalSets[$j]]->getSpecRuleIDSet);
                    #remove the duplicate generalized association rules
                    splice(@{$rulesSet},$equalSets[$j],1);
                }
                push(@ruleSetTemp, $rulesSet->[0]);
                splice(@{$rulesSet},0,1);
            }
            else{ #else undo the generalization of rules
                for($j=$#equalSets; $j >= 0; $j--){
                    if(($rulesSet->[$equalSets[$j]]->getPosItemGen) != -1){
                        $rulesSet->[$equalSets[$j]]->undoGeneralization;
                    }
                    push(@ruleSetTemp, $rulesSet->[$equalSets[$j]]);
                    splice(@{$rulesSet},$equalSets[$j],1);
                }
            }
        }
        @{$rulesSet} = ();
        @{$rulesSet} = @ruleSetTemp;
        @ruleSetTemp = ();
    }
}


#---------------------------------------------------------------------------
# makeReports - Function that make two kind of output reports
#---------------------------------------------------------------------------
sub makeReports{
    my $class = shift;
    my $genRulesSet = $_[0]; #generalized rules set
    my $fileName; #store file names
    my ($i, @temp, @aRule, @rulesSet);
    my $nRulesGen = 0;
    
    # report with two files
    if ($class->{report} == 1){
        
        # make report file
        $fileName = $class->{stem} . ".gar.report";
        open(ARQ_SAIDA,"> $fileName") || die "Cold not create file of report.";
        print ARQ_SAIDA "Association Rules Generalization using IGART Algorithm\t\tCopyright (c) Marcos Aurélio Domingues\n";
        print ARQ_SAIDA "Date: ".gmtime(time())."\n\n\n";
        print ARQ_SAIDA "ALGORITHM INPUT FILE:\n";
        print ARQ_SAIDA "DataBase: ". $class->{databaseFile} .".apr.data\n";
        print ARQ_SAIDA "Taxonomies Set: ". $class->{stem} .".tax\n";
        print ARQ_SAIDA "Rules Set: ". $class->{stem} .".apr.dcar\n\n";
        print ARQ_SAIDA "ALGORITHM OUTPUT FILE:\n";
        print ARQ_SAIDA "Generalized Rules: ". $class->{stem} .".gar.dcar\n";
        print ARQ_SAIDA "Report File: ". $class->{stem} .".gar.report\n\n";
        print ARQ_SAIDA "\# Rules Set: ". $class->{nRulesNotGen} ."\n";
        print ARQ_SAIDA "\# Generalized Rules: " . scalar(@{$genRulesSet}) . "\n\n";        
        
        print ARQ_SAIDA "Generalized Rule ID <=> Source Rule IDs\n";
        
        for($i=0; $i < scalar(@{$genRulesSet}); $i++){
            print ARQ_SAIDA "\[" . $genRulesSet->[$i]->getRuleID . "\] <=> \[" . join(";", $genRulesSet->[$i]->getSpecRuleIDSet) . "\]\n";
        }
        close(ARQ_SAIDA);

        # make rules file
        $fileName = $class->{stem} . ".gar.dcar";
        open(ARQ_SAIDA,"> $fileName") || die "Cold not create file of rules.";
        
        if($class->{side} eq "RIGHT"){ #check if the generalization side is the right side
            for($i=0; $i < scalar(@{$genRulesSet}); $i++){
                print ARQ_SAIDA "\[" . $genRulesSet->[$i]->getRuleID . "\]," . $genRulesSet->[$i]->getSideNotGen . "," . join(" & ", $genRulesSet->[$i]->getSideGen) . "," . $genRulesSet->[$i]->getTC . "\n";
            }
        }
        else{ #check if the generalization side is the left side
            for($i=0; $i < scalar(@{$genRulesSet}); $i++){
                print ARQ_SAIDA "\[" . $genRulesSet->[$i]->getRuleID . "\]," . join(" & ", $genRulesSet->[$i]->getSideGen) . "," . $genRulesSet->[$i]->getSideNotGen . "," . $genRulesSet->[$i]->getTC . "\n";
            }
        }

        close(ARQ_SAIDA);

    }
    elsif($class->{report} == 0){ # report with one file
    
        # make report file
        $fileName = $class->{stem} . ".gar.dcar.report";
        open(ARQ_SAIDA,"> $fileName") || die "Cold not create file of report.";
        print ARQ_SAIDA "Association Rules Generalization using IGART Algorithm\t\tCopyright (c) Marcos Aurélio Domingues\n";
        print ARQ_SAIDA "Date: ".gmtime(time())."\n\n\n";
        print ARQ_SAIDA "ALGORITHM INPUT FILE:\n";
        print ARQ_SAIDA "DataBase: ". $class->{databaseFile} .".apr.data\n";
        print ARQ_SAIDA "Taxonomies Set: ". $class->{stem} .".tax\n";
        print ARQ_SAIDA "Rules Set: ". $class->{stem} .".apr.dcar\n\n";
        print ARQ_SAIDA "ALGORITHM OUTPUT FILE:\n";
        print ARQ_SAIDA "Report File: ". $class->{stem} .".gar.dcar.report\n\n";
        print ARQ_SAIDA "\# Rules Set: ". $class->{nRulesNotGen} ."\n";
        print ARQ_SAIDA "\# Generalized Rules: " . scalar(@{$genRulesSet}) . "\n\n";        
        
        print ARQ_SAIDA "[Generalized Rule ID], LHS, RHS, [Contigency Table (LHSRHS,LHSnotRHS,notLHSnotRHS,notLHSRHS,N)], [Source Rule IDs]\n\n";
        
        if($class->{side} eq "RIGHT"){ #check if the generalization side is the right side
            for($i=0; $i < scalar(@{$genRulesSet}); $i++){
                print ARQ_SAIDA "\[" . $genRulesSet->[$i]->getRuleID . "\]," . $genRulesSet->[$i]->getSideNotGen . "," . join(" & ", $genRulesSet->[$i]->getSideGen) . "," . $genRulesSet->[$i]->getTC . ",\[" . join(";", $genRulesSet->[$i]->getSpecRuleIDSet) . "\]\n";
            }
        }
        else{ #check if the generalization side is the left side
            for($i=0; $i < scalar(@{$genRulesSet}); $i++){
                print ARQ_SAIDA "\[" . $genRulesSet->[$i]->getRuleID . "\]," . join(" & ", $genRulesSet->[$i]->getSideGen) . "," . $genRulesSet->[$i]->getSideNotGen . "," . $genRulesSet->[$i]->getTC . ",\[" . join(";", $genRulesSet->[$i]->getSpecRuleIDSet) . "\]\n";
            }
        }
        
        close(ARQ_SAIDA);
        
    }
    elsif($class->{report} == -1){ # generalized rules file used in the RulEE-GAR Enviromment

        # insert the generalized rules in the file of generalized rules
        $fileName = $class->{stem} . ".gar"; #file name of rulebase
        open(ARQ_SAIDA,"> $fileName") || die "Cold not create file of generalized rules.";

        # Store generalized rules in the file
        if($class->{side} eq "RIGHT"){ #check if the generalization side is the right side
            for($i=0; $i < scalar(@{$genRulesSet}); $i++){
                print ARQ_SAIDA "\[" . $genRulesSet->[$i]->getRuleID . "\]," . $genRulesSet->[$i]->getSideNotGen . "," . join(" & ", $genRulesSet->[$i]->getSideGen) . "," . $genRulesSet->[$i]->getTC . ",\[" . join(";", $genRulesSet->[$i]->getSpecRuleIDSet) . "\]\n";
            }
        }
        else{ #check if the generalization side is the left side
            for($i=0; $i < scalar(@{$genRulesSet}); $i++){
                print ARQ_SAIDA "\[" . $genRulesSet->[$i]->getRuleID . "\]," . join(" & ", $genRulesSet->[$i]->getSideGen) . "," . $genRulesSet->[$i]->getSideNotGen . "," . $genRulesSet->[$i]->getTC . ",\[" . join(";", $genRulesSet->[$i]->getSpecRuleIDSet) . "\]\n";
            }
        }
        close(ARQ_SAIDA); # close file of generalized rules
    }
}


#---------------------------------------------------------------------------
# Convert format association rules file of rulEE to format standard of association rules
# Require: Input File Name and Output File Name
#---------------------------------------------------------------------------
sub FormatAssocRules{
    my $class = shift;
    my $inFileName = shift;
    my $outFileName = shift;
    
    open(ARQ_ENTRADA,"< $inFileName") || die "Cold not open file of rules.";
    open(ARQ_SAIDA,"> $outFileName") || die "Cold not create new file of rules.";

    while(<ARQ_ENTRADA>){
        s/ //g;
        my @temp = split(/,/, $_);
        $temp[0] = "[". sprintf("R%04d",$temp[0]) ."]";
        $temp[1] =~ s/"//g;
        $temp[1] =~ s/&/ & /g;
        $temp[2] =~ s/"//g;
        $temp[2] =~ s/&/ & /g;
        chop($temp[7]);

        print ARQ_SAIDA "$temp[0],$temp[1],$temp[2],\[$temp[3],$temp[4],$temp[5],$temp[6],$temp[7]]\n";
    }
    close(ARQ_ENTRADA);
    close(ARQ_SAIDA);
}


#---------------------------------------------------------------------------
# Function that sort the rules to the generalization process of the 
# association rules. This function sort of the rules set by LHS or RHS.
#---------------------------------------------------------------------------
sub groupAssocRules{
    my $class = shift;
    my $fileName = $class->{stem} . ".apr.dcar"; #rule file name in the standard format
    my ($j, $compSide, @temp, @aRule, @rulesSet);
    
    # read rules in the file don't sorted
    open(ARQ_ENTRADA,"< $fileName") || die "Cold not open file of rules.";
    foreach(<ARQ_ENTRADA>){
        @temp = split(/,\[/, $_);
        @aRule = split(/,/, $temp[0]);
        push(@aRule, ("\[".$temp[1]));
        push(@rulesSet, [@aRule]);
    }
    close(ARQ_ENTRADA);
    
    # check what side will be sorted
    if($class->{side} eq "LEFT"){ #generalize left side
        $compSide = 2; #sort by right side
    }
    elsif($class->{side} eq "RIGHT"){ #generalize right side
        $compSide = 1; #sort by left side
    }
 
    open(ARQ_SAIDA,"> $fileName") || die "Cold not create sort file of rules.";
    
    #sort the rules by antecedent or consequent
    while(scalar(@rulesSet) > 0){
        for($j=1; $j < scalar(@rulesSet); $j++){
            if($rulesSet[0][$compSide] eq $rulesSet[$j][$compSide]){
                print ARQ_SAIDA "$rulesSet[$j][0],$rulesSet[$j][1],$rulesSet[$j][2],$rulesSet[$j][3]";
                splice(@rulesSet,$j,1);
                $j--;
            }
        }
        print ARQ_SAIDA "$rulesSet[0][0],$rulesSet[0][1],$rulesSet[0][2],$rulesSet[0][3]";
        splice(@rulesSet,0,1);
    }
    
    close(ARQ_SAIDA);
}


#---------------------------------------------------------------------------
# sortTaxonomies - Function that put the taxonomies with more children in the
# start of file.
#---------------------------------------------------------------------------
sub sortTaxonomies{
    my $class = shift;
    my $taxonomiesSet = $_[0]; #taxonomy set
    my $sizeTaxonomiesSet = scalar(@{$taxonomiesSet}); #size of generalization set
    my($i, $j);
        
    # analize the rules for each generalization
    for($i=0; $i < $sizeTaxonomiesSet - 1; $i++){
        for($j=0; $j < ($sizeTaxonomiesSet - 1 - $i); $j++){
            my $prev = $taxonomiesSet->[$j]->getNumberChildrenItens; 
            my $next = $taxonomiesSet->[$j+1]->getNumberChildrenItens; 

            if ($next > $prev){
                my $temp = $taxonomiesSet->[$j];
                $taxonomiesSet->[$j] = $taxonomiesSet->[$j+1];
                $taxonomiesSet->[$j+1] = $temp
            }
        }
    }
}


#---------------------------------------------------------------------------
# MakeTaxonomiesOfGeneralizedRules - Make taxonomies for generalize generalized rules
#---------------------------------------------------------------------------
sub MakeTaxonomiesOfGeneralizedRules{
    my $class = shift;
    my $oldTaxonomy = shift;
    my $outFileName = shift;
    
    my(@alloldtax,@oldtax,$oldTaxTemp,$fileResult,$originalTax,$temp,$count,$j);
    
    open(ARQ_SAIDA,"< $oldTaxonomy") || die "Cold not open file of old taxonomies.";
    
    while(<ARQ_SAIDA>){
        chop($_);
        $oldTaxTemp = $_;
        $oldTaxTemp =~ s/\)//g;
        @oldtax = split(/\(/, $oldTaxTemp);
        push(@alloldtax, [@oldtax]);
    }
    close(ARQ_SAIDA);

    $fileResult = "";
    open(ARQ_ENTRADA,"< $outFileName") || die "Cold not open file of old taxonomies.";
    while(<ARQ_ENTRADA>){
        chop($_);
        $originalTax = $_;
        $temp = $originalTax;
        $count = 0;
        for($j=0; $j < scalar(@alloldtax); $j++){
            if ($temp =~ s/([\(,])$alloldtax[$j][0]([,\)])/$1$alloldtax[$j][1]$2/g){
                $count = $count + 1;
            }
        }
        if ($count > 0){
            $fileResult = $fileResult ."$originalTax\n$temp\n";
        }
        else{
            $fileResult = $fileResult ."$originalTax\n";
        }
    }
    close(ARQ_ENTRADA);

    open(ARQ_SAIDA,"> $outFileName") || die "Cold not create file of taxonomies.";
    print ARQ_SAIDA "$fileResult";
    close(ARQ_SAIDA);    
}

1; # return of the class
