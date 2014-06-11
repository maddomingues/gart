#-------------------------------------------------------------------------------------------------------------------------------
#Classe de transformação dos formatos Apriori, MineSet, Magnum Opus e Weka para os formatos Padrão e Padrão Estendido.
#
#Criado por Gilson Kenji Ywamoto - 2.sem/2003
#-------------------------------------------------------------------------------------------------------------------------------


package ToPadrao;


require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(Apriori_to_Padrao, Mineset_to_Padrao, Magnumopus_to_Padrao, Weka_to_Padrao);

sub new
{
	my $class = shift;
	my $self = {};
	bless $self, $class;
	return $self;
}


#-------------------------------------------------------------------------------------------------------------------------------
# Conversão do formato Apriori para o Padrão
#
#Parâmetros de Entrada:
#-->$nomearq: indica o nome do arquivo de entrada, com a extensão '.apr'
#-->$opcao:   0 se o usuário deseja que o formato de saída seja o Padrão.
#	      1 se o usuário deseja que o formato de saída seja o Padrão Estendido.
#-------------------------------------------------------------------------------------------------------------------------------

sub Apriori_to_Padrao
{
	my($self, $nomearq, $opcao) = @_;	

	my($input_file, $output_file, @linhas, $total_regras, $id_regra);
	my($regra, @itens, @lados, @medidas);
	my(@suporte_vet,@temp);
	my($suporte, $confianca, $conf_esp);
	my($n_RHS, $n_notRHS, $n_LHS, $n_notLHS, $n_LHS_RHS, $n_notLHS_RHS, $n_LHS_notRHS, $n_notLHS_notRHS);

	$input_file = $nomearq;

	if($opcao == 0) #PADRÃO
	{
		$output_file = $nomearq.'.dcar';
	}
	else #PADRÃO ESTENDIDO
	{	
		$output_file = $nomearq.'.dar';
	}

	open(IN, $input_file) || die "Could not open the input file $input_file\n";
	open(OUT, ">$output_file");

	@linhas = <IN>; #@LINHAS POSSUI O CONTEÚDO DO ARQUIVO DE ENTRADA
	close(IN);

	$total_regras = 0;

	$id_regra = 0; #indica qual regra está sendo trabalhada

	foreach $regra (@linhas)
	{
	
		@itens = split('  \(',$regra);

		@lados = split(' <- ',$itens[0]); #$LADOS[0] = RHS, $LADOS[1] = LHS	

		$lados[0] =~ s/ \<-//; #RETIRA ' <-' NOS CASOS ONDE NÃO HÁ RHS
		
		if ($lados[1] eq ""){
			$lados[1] = 'TRUE';}
			
	
    		$itens[1] =~ s/\)//; #RETIRA )

		$itens[1] =~ s/%//;

		@medidas = split(', ',$itens[1]);
		
		@suporte_vet = split('\/',$medidas[0]);
	
	
		#MEDIDAS[0] = SUPORTE, MEDIDAS[1] = CONFIANCA, MEDIDAS[2] = DIF. CONF.


		$suporte = $suporte_vet[0]/100;	#SUPORTE
		$confianca = $medidas[1]/100;	#CONFIANCA
		$conf_esp = $confianca - ($medidas[2]/100);  #CONFIANCA ESPERADA

		if ($total_regras == 0) #calcula o número total de exemplos
		{

			$total_regras = $suporte_vet[1]/$suporte;

			@temp = split('\.',$total_regras);
	
			$temp[1] = '0.'.$temp[1];

			if($temp[1]>0.5){#arredondando para cima (ex: 13.95 se tornará 14.95)
				$total_regras++;}
		}


		#valores entre 0 e 1
		$n_RHS = $conf_esp;  #N(RHS)
		$n_notRHS = 1 - $n_RHS;	#N(notRHS)
		$n_LHS = ($suporte/$confianca); #N(LHS)
		$n_notLHS = 1 - $n_LHS;	#N(notLHS)
	
		$n_LHS_RHS = $suporte; #N(LHS RHS)

		$n_notLHS_RHS = $n_RHS - $n_LHS_RHS; #N(notLHS RHS)
		$n_LHS_notRHS = $n_LHS - $n_LHS_RHS; #N(LHS notRHS)
	
		$n_notLHS_notRHS = $n_notRHS - $n_LHS_notRHS; #N(notLHS notRHS)

		$id_regra++;


                #formatando a saida de $id_regra
                if ($id_regra<10) {
                        print OUT "[R000$id_regra]"; }
                else {
                        if ($id_regra<100) {
                                print OUT "[R00$id_regra]"; }
                        else {
                                if ($id_regra<1000) {
                                        print OUT "[R0$id_regra]"; }
                                else{
                                        print OUT "[R$id_regra]"; }
                        }
                }



		if ($opcao == 0)#PADRÃO
		{
			$lados[1] =~ s/ / & /g;		

			print OUT ",$lados[1],$lados[0],";


			printf OUT "[%0.6f,%0.6f,%0.6f,%0.6f,%d]\n",$n_LHS_RHS,$n_LHS_notRHS,$n_notLHS_notRHS,$n_notLHS_RHS,$total_regras;
		}
		else #PADRÃO ESTENDIDO
		{

			

			$lados[1] =~ s/ /\n\t\t\tAND /g;


			print OUT "\tIF\t";
			
			print OUT "$lados[1]\n\t\t\tTHEN $lados[0]\n";

			printf OUT "\t\t\t[%0.6f,%0.6f,%0.6f,%0.6f,%d]\n\n",$n_LHS_RHS,$n_LHS_notRHS,$n_notLHS_notRHS,$n_notLHS_RHS,$total_regras;			
		}

	}
	close(OUT);
}

#-------------------------------------------------------------------------------------------------------------------------------
# Conversão do formato MineSet para o Padrão
#
#Parâmetros de Entrada:
#-->$nomearq:  	indica o nome do arquivo de entrada, com a extensão '.rules.out'
#-->$num_ex:   	indica o número de exemplos (opcional).
#-->$arq_dados: indica o nome do arquivo que possui os dados (opcional).
#-->$opcao:    	0 se o usuário deseja que o formato de saída seja o Padrão.
#	       	1 se o usuário deseja que o formato de saída seja o Padrão Estendido.
#-------------------------------------------------------------------------------------------------------------------------------

sub Mineset_to_Padrao
{
	my($self, $nomearq, $num_ex, $arq_dados , $opcao) = @_;	

	my(@dados, $dado, $data_file);
	my($input_file, $output_file, @linhas, $total_regras, $id_regra);
	my($regra, @itens, @lados, @medidas);
	my($suporte, $confianca, $conf_esp);
	my($LHS, $RHS);
	my(@VET_LHS, $vetor, $i, @VET_RHS, @vetor_itens);
	my($n_RHS, $n_notRHS, $n_LHS, $n_notLHS, $n_LHS_RHS, $n_notLHS_RHS, $n_LHS_notRHS, $n_notLHS_notRHS);


	#calculando o número de exemplos
	if ($num_ex > 0) #numero de exemplos passado com parametro
	{
		$total_regras = $num_ex;
	}
	elsif(open(DADOS, $arq_dados))  #nome do arquivo com os exemplos
	{
		@dados = <DADOS>;
		$total_regras = $#dados+1;
		close (DADOS);
	}
	else #tentará abrir o arquivo "arquivo.data" ou "arquivo-assoc.out"
	{
		$data_file = $nomearq;
		$data_file =~ s/\.rules//;
		
		if (open(DADOS, $data_file))#arquivo "arquivo.data"
		{
			@dados = <DADOS>;
			$total_regras = $#dados+1;
			close (DADOS);
		}
		else #arquivo "arquivo-assoc.out"
		{
		
			$data_file = $nomearq;
			$data_file =~ s/\.rules\.data/\-assoc\.out/;
			open(DADOS, $data_file) || die "could not open the file $data_file";
		
			@dados = <DADOS>;
			close (DADOS);
		
			foreach $dado (@dados)
			{
				if($dado =~ / records read/)
				{
					@vetor = split(" ",$dado);
					$total_regras = $vetor[0];	
				}
			}
		}
			
	}	


	$input_file = $nomearq;

	if ($opcao == 0) #PADRÃO
	{
		$output_file = $nomearq.'.dcar';
	}
	else #PADRÃO ESTENDIDO
	{
		$output_file = $nomearq.'.dar';
	}

	open(IN, $input_file) || die "Could not open the input file $input_file\n";
	open(OUT, ">$output_file");

	@linhas = <IN>; #@LINHAS POSSUI O CONTEÚDO DO ARQUIVO DE ENTRADA
	close(IN);

	$id_regra = 0; #indica qual regra está sendo trabalhada


	foreach $regra (@linhas)
	{

		@itens = split('\t',$regra);

		#$itens[2] =  suporte, $itens[3] = confianca, $itens[4] = confianca esperada, $itens[5] = lift
		#$itens[6] = LHS, $itens[7] = RHS

		$LHS = $itens[6];		
		$RHS = $itens[7];

		$RHS =~ s/\n//;


		#formatando o $LHS e o $RHS
		$i=-1;
		@VET_LHS = split(' and ',$LHS);
		

		foreach $vetor (@VET_LHS) #transformará os intervalos com "(" e "]" em ">" e "<="
		{
			$i++;
			if($vetor =~ / in /)
			{
				if($vetor =~ s/ in \(\.\.\. / \<= /g) 
				# "AAA in (... YYY]" se transformará em "AAA <= YYY"
				{
					$vetor =~ s/]//;
				}
				else #(XXX ...
				{
					if($vetor =~ s/ \.\.\.]//) 
					# "AAA in (XXX ...]" se transformará em "AAA > XXX"
					{
						$vetor =~ s/ in \(/ \> /;
					}
					else 
					# "AAA in (XXX ... YYY]" se transformará em "AAA > XXX and AAA <= YYY"
					{
						$vetor =~ s/in \(//;
						$vetor =~ s/]//;
						$vetor =~ s/\.\.\. //;
						@vetor_itens = split(' ',$vetor);
						$vetor = $vetor_itens[0].' > '.$vetor_itens[1].' and '.$vetor_itens[0].' <= '.$vetor_itens[2];
					}
				}
			}
			
			if($i<$#VET_LHS) 
			#insere '&' entre os dados de cada posicao de VET_LHS, mas não adiciona '&' à ultima posicao
			{
				$vetor = $vetor.' &';
			}
			
		}	


		$i=-1;
		@VET_RHS = split(' and ',$RHS); 
		foreach $vetor (@VET_RHS) #transformará os intervalos com "(" e "]" em ">" e "<="
		{
			$i++;
			if($vetor =~ / in /)
			{
				if($vetor =~ s/ in \(\.\.\. / \<= /g)
				# "AAA in (... YYY]" se transformará em "AAA <= YYY"
				{
					$vetor =~ s/]//;
				}
				else #(XXX ...
				{
					if($vetor =~ s/ \.\.\.]//)
					# "AAA in (XXX ...]" se transformará em "AAA > XXX"
					{
						$vetor =~ s/ in \(/ \> /;
					}
					else
					# "AAA in (XXX ... YYY]" se transformará em "AAA > XXX and AAA <= YYY"
					{
						$vetor =~ s/in \(//;
						$vetor =~ s/]//;
						$vetor =~ s/\.\.\. //;
						@vetor_itens = split(' ',$vetor);
						$vetor = $vetor_itens[0].' > '.$vetor_itens[1].' and '.$vetor_itens[0].' <= '.$vetor_itens[2];
					}
				}
			}
			if($i<$#VET_RHS)
			#insere '&' entre os dados de cada posicao de VET_RHS, mas não adiciona '&' à ultima posicao
			{
				$vetor = $vetor.' &';
			}
		}	

	
		$suporte = $itens[2]/100;	#SUPORTE
		$confianca = $itens[3]/100;	#CONFIANCA
		$conf_esp = $itens[4]/100;  #CONFIANCA ESPERADA

		#medidas entre 0 e 1
		$n_RHS = $conf_esp; #N(RHS)
		$n_notRHS = 1 - $n_RHS;	#N(notRHS)
		$n_LHS = ($suporte/$confianca); #N(LHS)
		$n_notLHS = 1 - $n_LHS;	#N(notLHS)
		$n_LHS_RHS = $suporte;  #N(LHS RHS)
		$n_notLHS_RHS = $n_RHS - $n_LHS_RHS; #N(notLHS RHS)
		$n_LHS_notRHS = $n_LHS - $n_LHS_RHS; #N(LHS notRHS)
		$n_notLHS_notRHS = $n_notRHS - $n_LHS_notRHS; #N(notLHS notRHS)

		$id_regra++;


               	#formatando a saida de $id_regra
               	if ($id_regra<10) {
                	print OUT "[R000$id_regra]"; }      
                else {
                   	if ($id_regra<100) {
                          	print OUT "[R00$id_regra]"; }      
                     	else {
                           	if ($id_regra<1000) {
                                	print OUT "[R0$id_regra]"; }      
                              	else{
                                      	print OUT "[R$id_regra]"; }      
                      	}
              	}


		if ($opcao == 0) #PADRÃO
		{

			if ($LHS =~ / in \(/) #se houve transformacao de '(' ou ']' em '>' ou '<='
			{
				for ($i=0; $i<=$#VET_LHS ; $i++)
				{
					$VET_LHS[$i] =~ s/ and / \& /g;
				}
				print OUT ",@VET_LHS,";
			}
			else
			{
				$LHS =~ s/ and / & /g;
				print OUT ",$LHS,";
			}

			if ($RHS =~ / in \(/) #se houve transformacao de '(' ou ']' em '>' ou '<='
			{
				for ($i=0; $i<=$#VET_RHS ; $i++)
				{
					$VET_RHS[$i] =~ s/ and / & /g;
				}
				print OUT "@VET_RHS,";
			}
			else
			{
				$RHS =~ s/ and / & /g;
				print OUT "$RHS,";
			}
			

			printf OUT "[%0.6f,%0.6f,%0.6f,%0.6f",$n_LHS_RHS,$n_LHS_notRHS,$n_notLHS_notRHS,$n_notLHS_RHS;
			print OUT ",$total_regras]\n";						

		}
		else #PADRÃO ESTENDIDO
		{
			
			$LHS =~ s/ and/\n\t\t\tAND/g;
			$RHS =~ s/ and/\n\t\t\tAND/g;
				
			
			print OUT "\tIF\t";

			if ($LHS =~ / in \(/) #se houve transformacao de '(' ou ']' em '>' ou '<='
			{
				for ($i=0; $i<$#VET_LHS ; $i++)
				{
					$VET_LHS[$i] =~ s/\&//g;
					$VET_LHS[$i] =~ s/ and / AND /g;
					print OUT "$VET_LHS[$i]\n\t\t\tAND ";
				}
				$VET_LHS[$i] =~ s/\&//g;
				$VET_LHS[$i] =~ s/ and / AND /g;
				print OUT "$VET_LHS[$i]\n\t\t\tTHEN ";
			}
			else
			{
				print OUT "$LHS\n\t\t\tTHEN ";
			}


			if ($RHS =~ / in \(/) #se houve transformacao de '(' ou ']' em '>' ou '<='
			{
				for ($i=0; $i<$#VET_RHS ; $i++)
				{
					$VET_RHS[$i] =~ s/\&//g;
					$VET_RHS[$i] =~ s/ and / AND /g;
					print OUT "$VET_RHS[$i]\n\t\t\tAND ";
				}
				$VET_RHS[$i] =~ s/\&//g;
				$VET_RHS[$i] =~ s/ and / AND /g;
				print OUT "$VET_RHS[$i]\n";
			}
			else
			{
				print OUT "$RHS\n";
			}



			printf OUT "\t\t\t[%0.6f,%0.6f,%0.6f,%0.6f",$n_LHS_RHS,$n_LHS_notRHS,$n_notLHS_notRHS,$n_notLHS_RHS;
			print OUT ",$total_regras]\n\n";						

		}
	}
	close(OUT);
}

#-------------------------------------------------------------------------------------------------------------------------------
# Conversão do formato Magnum Opus para o Padrão
#
#Parâmetros de Entrada:
#-->$nomearq:	indica o nome do arquivo de entrada, com a extensão '.mop'
#-->$opcao: 	0 se o usuário deseja que o formato de saída seja o Padrão.
#	      	1 se o usuário deseja que o formato de saída seja o Padrão Estendido.
#-------------------------------------------------------------------------------------------------------------------------------

sub Magnumopus_to_Padrao
{
	my($self, $nomearq, $opcao) = @_;	

	my($input_file, $output_file, @linhas, $total_regras, $id_regra);
	my($regra, @itens, @medidas);
	my($suporte, $confianca, $conf_esp);
	my($n_RHS, $n_notRHS, $n_LHS, $n_notLHS, $n_LHS_RHS, $n_notLHS_RHS, $n_LHS_notRHS, $n_notLHS_notRHS);
	my(@temp);

	$input_file = $nomearq;

	if($opcao == 0) #PADRÃO
	{
		$output_file = $nomearq.'.dcar';
	}
	else #PADRÃO ESTENDIDO
	{	
		$output_file = $nomearq.'.dar';
	}

	open(IN, $input_file) || die "Could not open the input file $input_file\n";
	open(OUT, ">$output_file");

	@linhas = <IN>; #@LINHAS POSSUI O CONTEÚDO DO ARQUIVO DE ENTRADA
	close(IN);

	$id_regra = -1; #indica qual regra está sendo trabalhada
		
	$total_regras = 0;

	foreach $regra (@linhas)
	{

		$id_regra++;
	
		if($id_regra > 0) #ignora a primeira linha
		{

			@itens = split(',',$regra); 
			#$itens[0] = LHS, $itens[1] = RHS, $itens[2] = cobertura, $itens[3] = numero de regras que possuem o LHS
			#$itens[4] = suporte, $itens[6] = confiança, $itens[7] = lift

			if ($total_regras == 0) #calcula o número total de exemplos
			{
				$total_regras = $itens[3]/$itens[2];
				@temp = split('\.',$total_regras);
				$temp[1] = '0.'.$temp[1];
				if ($temp[1] > 0.5){ #arredondando para cima (ex: 13.95 se tornará 14.95)
					$total_regras++;
				}
			}	

			#MEDIDAS[0] = SUPORTE, MEDIDAS[1] = CONFIANCA, MEDIDAS[2] = DIF. CONF.


			$suporte = $itens[4];	#SUPORTE
			$confianca = $itens[6];	#CONFIANCA
			$conf_esp = $confianca/$itens[7];  #CONFIANCA ESPERADA

			#valores entre 0 e 1
			$n_RHS = $conf_esp;  #N(RHS)
			$n_notRHS = 1 - $n_RHS;	#N(notRHS)
			$n_LHS = ($suporte/$confianca); #N(LHS)
			$n_notLHS = 1 - $n_LHS;	#N(notLHS)
	
			$n_LHS_RHS = $suporte; #N(LHS RHS)

			$n_notLHS_RHS = $n_RHS - $n_LHS_RHS; #N(notLHS RHS)
			$n_LHS_notRHS = $n_LHS - $n_LHS_RHS; #N(LHS notRHS)
	
			$n_notLHS_notRHS = $n_notRHS - $n_LHS_notRHS; #N(notLHS notRHS)


	                #formatando a saida de $id_regra
        	        if ($id_regra<10) {
                	        print OUT "[R000$id_regra]"; }
	                else {
        	                if ($id_regra<100) {
                	                print OUT "[R00$id_regra]"; }
                        	else {
             	                   if ($id_regra<1000) {
                	                        print OUT "[R0$id_regra]"; }
                        	        else{
                                	        print OUT "[R$id_regra]"; }
                      	  	}
                	}

	
			if ($opcao == 0)#PADRÃO
			{

				print OUT ",$itens[0],$itens[1],";


				printf OUT "[%0.6f,%0.6f,%0.6f,%0.6f,%d]\n",$n_LHS_RHS,$n_LHS_notRHS,$n_notLHS_notRHS,$n_notLHS_RHS,$total_regras;
			}
			else #PADRÃO ESTENDIDO
			{

				$itens[0] =~ s/ & /\n\t\t\tAND /g;
				$itens[1] =~ s/ & /\n\t\t\tAND /g;


				print OUT "\tIF\t";
			
				print OUT "$itens[0]\n\t\t\tTHEN $itens[1]\n";

				printf OUT "\t\t\t[%0.6f,%0.6f,%0.6f,%0.6f,%d]\n\n",$n_LHS_RHS,$n_LHS_notRHS,$n_notLHS_notRHS,$n_notLHS_RHS,$total_regras;			
			}
		}

	}
	close(OUT);
}


#-------------------------------------------------------------------------------------------------------------------------------
# Conversão do formato WEKA para o Padrão
#
#Parâmetros de Entrada:
#-->$nomearq: 	indica o nome do arquivo de entrada, com a extensão '.weka'
#-->$opcao: 	0 se o usuário deseja que o formato de saída seja o Padrão.
#	      	1 se o usuário deseja que o formato de saída seja o Padrão Estendido.
#-------------------------------------------------------------------------------------------------------------------------------

sub Weka_to_Padrao
{
	my($self, $nomearq, $opcao) = @_;	

	my($input_file, $output_file, @linhas, $total_regras, $id_regra);
	my($regra, @itens, @lados, @medidas);
	my($suporte, $confianca, $conf_esp);
	my($n_RHS, $n_notRHS, $n_LHS, $n_notLHS, $n_LHS_RHS, $n_notLHS_RHS, $n_LHS_notRHS, $n_notLHS_notRHS);
	my($num_RHS, $num_LHS, @LHS, @RHS);	


	$input_file = $nomearq;

	if($opcao == 0) #PADRÃO
	{
		$output_file = $nomearq.'.dcar';
	}
	else #PADRÃO ESTENDIDO
	{	
		$output_file = $nomearq.'.dar';
	}

	open(IN, $input_file) || die "Could not open the input file $input_file\n";
	open(OUT, ">$output_file");

	@linhas = <IN>; #@LINHAS POSSUI O CONTEÚDO DO ARQUIVO DE ENTRADA
	close(IN);

	$id_regra = 0; #indica qual regra está sendo trabalhada

	foreach $regra (@linhas)
	{

		if ($regra =~ s/^Instances://) #calcula o número de regras
		{	
			$total_regras = $regra;	
			$total_regras =~ s/\n//g;
			$total_regras =~ s/ //g;	
		}
		elsif ($regra =~ /\=\=\>/)
		{
			@itens = split('    ',$regra); #$ITENS[0] = REGRAS,  $ITENS[1] = MEDIDAS

			@lados = split(' \=\=\> ',$itens[0]); #$LADOS[0] = LHS, $LADOS[1] = RHS

			@LHS = split(' ',$lados[0]);
			$num_LHS = pop(@LHS);

			@RHS = split(' ',$lados[1]);
			$num_RHS = pop(@RHS);

			$itens[1] =~ s/\< //g;
			$itens[1] =~ s/\>//g;
			$itens[1] =~ s/\(//g;
			$itens[1] =~ s/\)//g;
			
			@medidas = split(' ',$itens[1]); #$MEDIDAS[1] = LIFT

			$medidas[1] =~ s/lift://g;

			$suporte = $num_RHS/$total_regras;
			$confianca = $num_RHS/$num_LHS;
			$conf_esp = $confianca/$medidas[1];

			#valores entre 0 e 1
			$n_RHS = $conf_esp;  #N(RHS)
			$n_notRHS = 1 - $n_RHS;	#N(notRHS)
			$n_LHS = ($suporte/$confianca); #N(LHS)
			$n_notLHS = 1 - $n_LHS;	#N(notLHS)
	
			$n_LHS_RHS = $suporte; #N(LHS RHS)

			$n_notLHS_RHS = $n_RHS - $n_LHS_RHS; #N(notLHS RHS)
			$n_LHS_notRHS = $n_LHS - $n_LHS_RHS; #N(LHS notRHS)
	
			$n_notLHS_notRHS = $n_notLHS - $n_notLHS_RHS; #N(notLHS notRHS)	

                    	$LHS[0] =~ s/\.//;
                     	$id_regra = $LHS[0];


	                #formatando a saida de $id_regra
        	        if ($id_regra<10) {
                	        print OUT "[R000$id_regra]"; }
	                else {
        	                if ($id_regra<100) {
                	                print OUT "[R00$id_regra]"; }
                        	else {
                                	if ($id_regra<1000) {
                                        	print OUT "[R0$id_regra]"; }
                                	else{
                                        	print OUT "[R$id_regra]"; }
                        	}
                	}


			if ($opcao == 0)#PADRÃO
			{
				print OUT ",";
			
				for($i=1; $i<$#LHS ; $i++)
				{
					print OUT "$LHS[$i] & ";
				}
				print OUT "$LHS[$i],";

				for($i=0; $i<$#RHS ; $i++)
				{
					print OUT "$RHS[$i] & ";
				}
				print OUT "$RHS[$i],";

				printf OUT "[%0.6f,%0.6f,%0.6f,%0.6f",$n_LHS_RHS,$n_LHS_notRHS,$n_notLHS_notRHS,$n_notLHS_RHS;
				print OUT ",$total_regras]\n";
			}
			else #PADRÃO ESTENDIDO
			{

				print OUT "\tIF\t";

				for($i=1; $i<$#LHS ; $i++)
				{
					print OUT "$LHS[$i]\n\t\t\tAND ";
				}
				print OUT "$LHS[$i]\n\t\t\tTHEN ";

				for($i=0; $i<$#RHS ; $i++)
				{
					print OUT "$RHS[$i]\n\t\t\tAND ";
				}
				print OUT "$RHS[$i]\n";			

				printf OUT "\t\t\t[%0.6f,%0.6f,%0.6f,%0.6f",$n_LHS_RHS,$n_LHS_notRHS,$n_notLHS_notRHS,$n_notLHS_RHS;
				print OUT ",$total_regras]\n\n";			
			}
		}


	}
	close(OUT);
}


1;
