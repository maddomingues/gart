use strict;

package ARtaxonomy;


my(@children, $father);
# @children - set of specific itens that are generalized
# $father - name that generalize the specifics itens in @children


#---------------------------------------------------------------------------
# Constructor Method
#---------------------------------------------------------------------------
# Make a new father = father(child,[child])
# Require: father name (one string) and the children (one string array)
#---------------------------------------------------------------------------
sub new{
    my $class = shift;
    my $self = {
        children => [], 
        father => "", 
    };
    bless($self, $class);
    $self->init(@_);
    return $self;
}


#---------------------------------------------------------------------------
# sub init - Set each father with the children
# Require: father name (one string) and the children (one string array)
#---------------------------------------------------------------------------
sub init{
    my $class =  shift;
    $class->{father} = shift;
    @{$class->{children}} = split(/,/, $_[0]);
}


#---------------------------------------------------------------------------
# sub getFatherItem - return the father name
#---------------------------------------------------------------------------
sub getFatherItem{
    my $class = shift;
    return $class->{father};
}


#---------------------------------------------------------------------------
# sub getChildrenItens - return the specific itens set
#---------------------------------------------------------------------------
sub getChildrenItens{
    my $class = shift;
    return @{$class->{children}};
}


#---------------------------------------------------------------------------
# sub getNumberChildrenItens - return the specific itens number
#---------------------------------------------------------------------------
sub getNumberChildrenItens{
    my $class = shift;
    return scalar(@{$class->{children}});
}


#---------------------------------------------------------------------------
# sub getOneChild - return an child item of the children set
# Require: the index of specific itens array where is the specific item
#---------------------------------------------------------------------------
sub getOneChild{
    my $class = shift;
    my $index = shift;
    return ${$class->{children}}[$index];
}


1; #return of the class
