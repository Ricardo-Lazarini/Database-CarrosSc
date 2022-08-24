create database carrossc;
SALVO AGORA.
use carrossc;

create table localizacoes (
	id int not null auto_increment primary key,
    estado varchar(20) not null unique,
    capital varchar(20) not null unique,
    uf varchar(3) not null unique,
    regiao varchar(20) not null ,
    qtdVenda int default(0),
    porcQtdVenda double default(0),
    SomaVenda double default(0),
    porcSoma double default(0)
);

create table categorias (
	id int not null auto_increment primary key,
    NomeCategoria varchar(30) not null unique,
	data datetime 
);

create table cores (
	id int not null auto_increment primary key,
    NomeCor varchar(20) not null unique
);

create table marcas (
	id int not null auto_increment primary key,
    NomeMarca varchar(20) not null unique,
    origem varchar(20) not null,
    categoriaId int not null,
    foreign key ( categoriaId ) references categorias ( id )
);

create table modelos (
	id int not null auto_increment primary key,
    NomeModelo varchar(20) not null unique,
    combustivel varchar(10),
	valor double not null,
    qtd int not null,
    categoriaId int ,
    foreign key ( categoriaId ) references categorias ( id ),
    marcaId int,
	foreign key ( marcaId ) references marcas ( id ),
    CorId int,
    foreign key ( CorId ) references cores ( id )
);


/*
	Trigger para formatar valores dos modelos
    Recebera os numeros sem pontos e formata com ponto após os centavos
*/

Delimiter $$
create trigger tr_format_valores before insert
on modelos
for each row
Begin

	Declare x int;
    Declare posicao1 int;
    Declare posicao2 int;
 
    set x = length(new.valor);
    set posicao1 = x - 2;
    set posicao2 = x - 1 ;
    set new.valor = concat(substring(new.valor,1,posicao1), '.', substring(new.valor,posicao2,2));
    
End $$
Delimiter ;



/* As 5 próximas tabelas, são relacionadas aos funcionarios */
create table cargos (
	id int not null auto_increment primary key,
    nomeCargo varchar(30) not null unique,
    salario double not null,
	dataCadastro datetime default( now() )
);


/* 
	Trigger para formatar os valores dos salarios recebidos do EF  
*/
Delimiter $$
create trigger tr_formatar_salario before insert 
on cargos
for each row
Begin

	Declare s double;
    Declare p1 int;
    Declare p2 int;
    
    set s = length(new.salario);
    set p1 = s - 2;
    set p2 = s - 1;
    set new.salario = concat(substring(new.salario,1,p1) , '.', substring(new.salario,p2,2));
    
End $$
Delimiter ;


/* 
	Trigger de UPDATE para formatar os valores dos salarios recebidos do EF quando houver un update
*/
Delimiter $$
create trigger tr_formatar_salario_update before update 
on cargos
for each row
Begin

	Declare s double;
    Declare p1 int;
    Declare p2 int;
    
    set s = length(new.salario);
    set p1 = s - 2;
    set p2 = s - 1;
    set new.salario = concat(substring(new.salario,1,p1) , '.', substring(new.salario,p2,2));
    
End $$
Delimiter ;


create table ajusteSalarial (
	id int not null auto_increment primary key,
    nomeCargo varchar(30) not null,
    salarioAntigo double not null,
    salarioAtualizado double not null ,
    ajuste varchar(11) not null,
    porcentagen varchar(11) not null,
	ultimoAjuste datetime ,
	dataAjuste datetime
);

/*  trigger para adicionar os ajustes dos salarios na tabela ajustesSalarial  */
delimiter $$
create trigger tr_ajusteSalario after update
on cargos
for each row
begin 

	Declare ajuste varchar(11);
    Declare res varchar(11);

	/* Verifica se o novo salario é maior ou menor que o antigo  */
    if new.salario > old.salario then
		set ajuste = concat('+ ' , new.salario - old.salario) ;
        set res = concat( round( ( (new.salario - old.salario) / old.salario ) * 100, 2) , ' % + ' ) ;
    else    
        set ajuste = concat('- ' , old.salario - new.salario) ;
        set res = concat( round( ( ( old.salario - new.salario ) / old.salario ) * 100,2), ' % - ' ) ;
    end if ;    
    
	if new.salario != old.salario then
		insert into ajusteSalarial(nomeCargo,salarioAntigo,salarioAtualizado,ajuste,porcentagen,ultimoAjuste,dataAjuste) 
			values(old.nomeCargo,old.salario,new.salario,ajuste,res,old.dataCadastro, now());
    end if ;
    
end $$
delimiter ;



create table funcionarios (
	id int not null primary key auto_increment,
    matricula varchar(15) not null unique, 	/* trigger */
    nome varchar(20) not null,
    sobrenome varchar(40) not null,
    sexo varchar(10) not null,
    cpf varchar(14) not null unique,
    idade int not null,
    peso double not null,
    altura double not null,
    imc double not null, /* trigger */
    classificacaoImc varchar(36) not null, /* trigger */
    filho int not null,
    cargo varchar(30) not null,
    salario double not null,
    lojaCidade varchar(20) not null,
	bairro varchar(20) not null,
    rua varchar(50) not null,
    numero int not null ,
    LocalizacaoId int ,
    admissao datetime default( now() ),
    foreign key ( LocalizacaoId ) references localizacoes ( id )
);


/* Trigger para adicionar matricula, mascara no cpf, conversões de tipo ( peso e altura ) calculo do imc, classificacaoImc e os registros na tabela vendedores */
delimiter $$
create trigger tr_funcionarios before insert 
	on funcionarios 
	for each row
	Begin
		Declare cont int ;
        Declare idcargo int ;
        Declare salariox float;
        
        Declare p int;
        Declare p1 int;
        Declare p2 int;
        Declare a int;
        Declare a1 int;
        Declare a2 int;
        
        
        /* Recebe o salario da tabela cargos referente ao cargo informado e seta no atributo salario da tabela funcionarios*/
        select id into idcargo from cargos where nomeCargo = new.cargo;
        select salario into salariox from cargos where id = idcargo;
        set new.salario =  salariox;
        
       
            
        /* Soma a quantidade de registros exisentes para a criação de uma matricula unica*/
        select count(id) into cont from funcionarios; 
	    set new.matricula = concat( substring(new.cargo,1,4) , '-' , extract(year from new.admissao) , '-' , cont + 1);
        
        /* Mascara para o cpf*/
        set new.cpf = concat(substring(new.cpf,1,3) , '.' , substring(new.cpf,4,3) ,'.' , substring(new.cpf,7,3) ,'-' , substring(new.cpf,10,2) );
		
        /* Converter tipo de peso e altura */
        set p = length(new.peso);
        set p1 = p - 2;
        set p2 = p -1;
        set new.peso = concat(substring(new.peso,1,p1), '.', substring(new.peso,p2,2));
        
        set new.altura = concat(substring(new.altura,1,1), '.', substring(new.altura,2,2));
        
        
        /* Calculo de imc */
        set new.imc =  round(new.peso / (new.altura * new.altura ),2);
        
        /* Verifica a classificação do imc e adiciona o valor ao campo classificacaoImc */
        if new.imc < 18.5 then
			set new.classificacaoImc = 'Abaixo do peso';
		elseif new.imc >= 18.5 and new.imc < 25 then
			set new.classificacaoImc = 'Peso Normal';
        elseif new.imc >= 25 and new.imc < 30 then
			set new.classificacaoImc = 'Sobrepeso';
        elseif new.imc >= 30 and new.imc < 35 then
			set new.classificacaoImc = 'Obesidade Grau |';
        elseif new.imc >= 35 and new.imc < 40 then
			set new.classificacaoImc = 'Obesidade Grau ||';
        elseif new.imc >= 40 then
			set new.classificacaoImc = 'Obesidade Grau ||| ou Mórbida';
		end if;
        
        /* Inserção dos registros de nome e matricula na tabela de vendedores */
        if substring(new.cargo,1,4) = 'Vend' then
			insert into vendedores(nome,matricula)values(new.nome, concat( substring(new.cargo,1,4) , '-' , extract(year from new.admissao) , '-' , cont + 1));
        end if ;    
        
	End $$
delimiter ;

create table vendedores(
id int not null auto_increment primary key,
nome varchar(20),
matricula varchar(20) unique,
qtdVendas int default(0),
somaVendas double default(0)
);


create table demissoes (
	id int not null primary key auto_increment,
    matricula varchar(15) not null ,
    nome varchar(20) not null,
    sobrenome varchar(40) not null,
    sexo varchar(10) not null,
    cpf varchar(14) not null unique,
    idade int not null,
    peso double not null,
    altura double not null,
    imc double not null, /* trigger */
    classificacaoImc varchar(36) not null, /* trigger */
    filho int not null,
    cargo varchar(30) not null,
    salario double not null,
	lojaCidade varchar(20) not null,
    bairro varchar(20) not null,
    rua varchar(50) not null,
    numero int not null ,
	Localizacao int,
    admissao date ,
    dataDemissao datetime default( now() )
);

/* Trigger para adicionar os funcionarios demitidos à tabela de demissoes */
delimiter $$
create trigger tr_demissao before delete
on funcionarios
for each row
begin 

	insert into demissoes (matricula,nome,sobrenome,sexo,cpf,idade,peso,altura,imc,classificacaoImc,filho,cargo,salario,lojaCidade,bairro,rua,numero,Localizacao,admissao) 
    values(old.matricula,old.nome,old.sobrenome,old.sexo,old.cpf,old.idade,old.peso,old.altura,old.imc,old.classificacaoImc,old.filho,old.cargo,old.salario,old.lojaCidade,old.bairro,old.rua,old.numero,
    old.LocalizacaoId,old.admissao);
    
end $$
delimiter ;

create table clientes (
	id int not null auto_increment primary key ,
    nome varchar(15) not null,
    sobrenome varchar(30) not null,
    sexo varchar(10) not null,
    cpf varchar(14) not null unique,
    cidade varchar(30) not null,
    bairro varchar(20) not null,
    rua varchar(50) not null,
    estadoId int not null ,
    dataNascimento date,
    idade varchar(3) ,  /* trigger */
    faixaEtaria varchar(16)  /* trigger */,
    dataCadastro datetime default(now() ),
    foreign key ( estadoId ) references localizacoes ( id )
);


/* Trigger para adicionar mascara ao cpf, idade e faixa etaria à tabela de clientes */
delimiter $$
create trigger tr_faixaEtaria before insert
on clientes
for each row
Begin

	Declare  dataAtual date;
    set dataAtual = now();
    
    /* Adicionar mascara ao cpf do cliente */
    set new.cpf = concat(substring(new.cpf,1,3) ,'.' , substring(new.cpf,4,3) ,'.' , substring(new.cpf,7,3) ,'-' , substring(new.cpf,10,2) );
    
    /* Verificação da idade */
	if extract(day from dataAtual) >= extract(day from new.dataNascimento) and extract(month from dataAtual) >= extract(month from new.dataNascimento) then
		set new.idade = extract(year from dataAtual) - extract(year from new.dataNascimento);
	else    
		set new.idade = ( extract(year from dataAtual) - extract(year from new.dataNascimento) ) - 1 ;
	end if;
    
    /* Verificação da faixa etaria */
    if new.idade <= 19 then
		set new.faixaEtaria = 'Jovem';
    elseif new.idade > 19 and new.idade <= 59 then
		set new.faixaEtaria = 'Adulto';
    elseif new.idade >= 60 then
		set new.faixaEtaria = 'Idoso';
    end if;    
    
End $$
delimiter ;



/* As 3 próximas tabelas, são relacionadas às vendas, reclamações e serviços prestados pela empresa */

create table vendas (
id int not null auto_increment primary key,
funcionarioId int ,
matricula varchar(14) ,
clienteId int ,
cpfCliente varchar(14) ,
estadoClienteId int not null,
categoriaId int,
marcaId int,
modeloId int ,
valor double not null,
corId int ,
dataVenda datetime default( now() ),
foreign key ( funcionarioId ) references funcionarios ( id ),
foreign key ( clienteId )  references clientes ( id ),
foreign key ( categoriaId ) references categorias ( id ),
foreign key ( marcaId ) references marcas ( id ),
foreign key ( modeloId ) references modelos ( id ),
foreign key ( corId ) references cores ( id )
);


/* triggers para inserção de valores de forma automatica na tabela de vendas
Puxara da tabela de modelo , valor, da tabela categoria, categoria, da tabela marca, marca e da tabela cor a cor , da tabela funcionario a matricula 
*/
delimiter $$
create trigger tr_desc_vendas before insert
on vendas
for each row
Begin

	/* dados do vendeddor*/
	Declare idv int;
    Declare mat varchar(20);
    
    /* dados do cliente*/
    Declare idc int;
    Declare cpff varchar(20);
    Declare est int;
    
    /* dados do modelo */
    Declare idm int;
    Declare idcate varchar(20);
	Declare idmarc varchar(20);
    Declare idcor varchar(20);
    Declare preco double;
    
   select id into idv from funcionarios where id = new.funcionarioId;
   select matricula into mat from funcionarios where id = idv;
   set new.matricula = mat;
    
    select id into idc from clientes where id = new.clienteId;
    select cpf into cpff from clientes where id = idc;
    select estadoId into est from clientes where id = idc;
    set new.cpfCliente = cpff;
    set new.estadoClienteId = est;
    
    select id into idm from modelos where id = new.modeloId;
    select categoriaId into idcate from modelos where id = idm;
    select marcaId into idmarc from modelos where id = idm;
    select corId into idcor from modelos where id = idm;
    select valor into preco from modelos where id = idm;
    set new.categoriaId = idcate;
    set new.marcaId = idmarc;
    set new.CorId = idcor;
    set new.valor = preco;
    
End $$
delimiter ;


/* Trigger para realizar os calculos da tabela de vendedores */
Delimiter $$
create trigger tr_calculosVendas after insert 
on vendas
for each row
Begin 

    Declare idd int ;
    Declare qtd int ;
    Declare qtdTotal int;
    Declare soma double;
    Declare somaTotal double;

    
    
	select id into idd from vendedores where new.matricula = matricula limit 1;   	/* seleciona o id dos vendedores onde a matricula da venda é igual ao da tabela de vendedores*/
    select count(*) into qtdTotal from vendas;  									/* Soma a quantidade total de vendas da tabela vendas */
    select count(id) into qtd from vendas where matricula = new.matricula;			/* Soma a quantidade total de vendas que o vendedor que fez a ultima  venda tem no total */

    select sum(valor) into soma from vendas where matricula = new.matricula;  		/* Soma o valor total das vendas da tabela vendas */
    select sum(valor) into somaTotal from vendas;

    update vendedores set qtdVendas = qtd where id = idd;
    update vendedores set somaVendas = soma where id = idd;
    
End $$

Delimiter ;


/* Trigger para realizar os calculos da tabela de estados. Vendas por estado */
Delimiter $$
create trigger tr_calculos_Estados after insert
on vendas
for each row
Begin
	Declare ide int ;
    declare qtdTotalVendas int; 
    Declare qtdlEstado int;
    declare somaTotal double;
    Declare somaEstado double;
    
    set ide = new.estadoClienteId;
    select count(id) into qtdTotalVendas from vendas; 
    select count(id) into qtdlEstado from vendas where estadoClienteId = ide;
    
    select sum(valor) into somaTotal from vendas; 
    select round(sum(valor),2) into somaEstado from vendas where estadoClienteId = ide;
    
    update localizacoes set qtdVenda = qtdlEstado where id = ide;
    update localizacoes set somaVenda = somaEstado where id = ide ;
   
End $$
Delimiter ;

create table servicos (
 id int not null auto_increment primary key,
 descricao varchar(100) not null,
 veiculo varchar(30) not null,
 categoriaId int not null,
 placa varchar (10) not null,
 kilometragem int not null,
 valorServico double not null,
 funcionarioId int not null,
 clienteId int not null,
 dataServico date
 );


/* Trigger de mascara para placas padrão antigas e mercosul*/
delimiter $$
create trigger tr_placas before insert
on servicos
for each row
Begin

	if length(new.placa) = 6 then
		set new.placa = concat(substring(new.placa,1,3) , '-' , substring(new.placa,4,6));
    end if;
    
End $$
delimiter ;

create table reclamacoes (
	id int not null auto_increment primary key,
    descricao longtext not null,
    relacionado varchar(30) not null,
    quemFez varchar(20) not null,
	dataReclamacao datetime default( now() )
);
