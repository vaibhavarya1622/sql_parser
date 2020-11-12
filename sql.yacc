  
/* symbolic tokens */

%union {
	int intval;
	double floatval;
	char *strval;
	int subtok;
}
	
%token NAME
%token STRING
%token INTNUM APPROXNUM

	/* operators */

%left OR
%left AND
%left NOT
%left <subtok> COMPARISON /* = <> < > <= >= */
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

	/* literal keyword tokens */

%token ALL AMMSC ANY AS ASC BETWEEN BY DROP
%token CHARACTER CHECK CLOSE COMMIT CONTINUE CREATE CURRENT
%token CURSOR DECIMAL DECLARE DEFAULT DELETE DESC DISTINCT DOUBLE
%token ESCAPE EXISTS FETCH FLOAT FOR FOREIGN FOUND FROM GOTO
%token GRANT GROUP HAVING IN INDICATOR INSERT INTEGER INTO
%token IS KEY LANGUAGE LIKE NULLX NUMERIC OF ON OPEN OPTION
%token ORDER PARAMETER PRECISION PRIMARY PRIVILEGES PROCEDURE
%token PUBLIC REAL REFERENCES ROLLBACK DATABASE SELECT SET
%token SMALLINT SOME SQLCODE SQLERROR TABLE TO UNION
%token UNIQUE UPDATE USER VALUES VIEW WHENEVER WHERE WITH WORK

%%

sql_list:
		sql ';'	{ end_sql(); }
	|	sql_list sql ';' { end_sql(); }
	;


	/* schema definition language */
sql:		schema
	;
	
schema:
        base_create
        | base_table_def
        | view_def
	    ;

 base_create:
             CREATE DATABASE user
             DROP DATABASE user
             ;

base_table_def:
		CREATE TABLE table_name '(' base_table_element_commalist ')'
	;

base_table_element_commalist:
		base_table_element
	|	base_table_element_commalist ',' base_table_element
	;

base_table_element:
		column_def
	;

column_def:
		column data_type column_def_opt_list
	;

column_def_opt_list:
		/* empty */
	|	column_def_opt_list column_def_opt
	;

column_def_opt:
		NOT NULLX
	|	NOT NULLX UNIQUE
	|	NOT NULLX PRIMARY KEY
	|	REFERENCES table_name
	;

view_def:
		CREATE VIEW '['view_list']'
		AS manipulative_statement
	;

view_list: view_name 
        | view_list ',' view_name
          ;

view_name: NAME
           ;

	/* manipulative statements */

sql:		manipulative_statement
	;

manipulative_statement:
	|	delete_statement_searched
	|	insert_statement
	|	select_statement
	|	update_statement_searched
	;

delete_statement_searched:
		DELETE FROM table_name opt_where_clause
	;

insert_statement:
		INSERT INTO table_name '(' column_commalist ')' values_or_query_spec
	;

    
column_commalist:
		column
	|	column_commalist ',' column
	;


values_or_query_spec:
		VALUES '(' insert_atom_commalist ')'
	|	query_spec
	;

insert_atom_commalist:
		insert_atom
	|	insert_atom_commalist ',' insert_atom
	;

insert_atom:
		atom
	|	NULLX
	;

select_statement:
		SELECT opt_all_distinct selection
		table_exp
	;

opt_all_distinct:
		/* empty */
	|	ALL
	|	DISTINCT
	;

assignment_commalist:
	|	assignment
	|	assignment_commalist ',' assignment
	;

assignment:
		column '=' scalar_exp
	|	column '=' NULLX
	;

update_statement_searched:
		UPDATE table_name SET assignment_commalist opt_where_clause
	;

target_commalist:
		target
	|	target_commalist ',' target
	;

target:
		parameter_ref
	;

opt_where_clause:
		/* empty */
	|	where_clause
	;

	/* query expressions */

query_exp:
		query_term
	|	query_exp UNION query_term
	|	query_exp UNION ALL query_term
	;

query_term:
		query_spec
	|	'(' query_exp ')'
	;

query_spec:
		SELECT opt_all_distinct selection table_exp
	;

selection:
		scalar_exp_commalist
	|	'*'
	;

table_exp:
		from_clause
		opt_where_clause
		opt_group_by_clause
		opt_having_clause
	;

from_clause:
		FROM table_ref_commalist
	;

table_ref_commalist:
		table_ref
	|	table_ref_commalist ',' table_ref
	;

table_ref:
		table_name 
	|	table_name range_variable
	;

where_clause:
		WHERE search_condition
	;

opt_group_by_clause:
		/* empty */
	|	GROUP BY column_ref_commalist
	;

column_ref_commalist:
		column_ref
	|	column_ref_commalist ',' column_ref
	;

opt_having_clause:
		/* empty */
	|	HAVING search_condition
	;

	/* search conditions */

search_condition:
	|	search_condition OR search_condition
	|	search_condition AND search_condition
	|	NOT search_condition
	|	'(' search_condition ')'
	|	predicate
	;

predicate:
		comparison_predicate
	|	between_predicate
	|	like_predicate
	|	test_for_null
	|	in_predicate
	|	all_or_any_predicate
	|	existence_test
	;

comparison_predicate:
		scalar_exp COMPARISON scalar_exp
	|	scalar_exp COMPARISON subquery
	;

between_predicate:
		scalar_exp NOT BETWEEN scalar_exp AND scalar_exp
	|	scalar_exp BETWEEN scalar_exp AND scalar_exp
	;

like_predicate:
		scalar_exp NOT LIKE atom opt_escape
	|	scalar_exp LIKE atom opt_escape
	;

opt_escape:
		/* empty */
	|	ESCAPE atom
	;

test_for_null:
		column_ref IS NOT NULLX
	|	column_ref IS NULLX
	;

in_predicate:
		scalar_exp NOT IN '(' subquery ')'
	|	scalar_exp IN '(' subquery ')'
	|	scalar_exp NOT IN '(' atom_commalist ')'
	|	scalar_exp IN '(' atom_commalist ')'
	;

atom_commalist:
		atom
	|	atom_commalist ',' atom
	;

all_or_any_predicate:
		scalar_exp COMPARISON any_all_some subquery
	;
			
any_all_some:
		ANY
	|	ALL
	|	SOME
	;

existence_test:
		EXISTS subquery
	;

subquery:
		'(' SELECT opt_all_distinct selection table_exp ')'
	;

	/* scalar expressions */

scalar_exp:
		scalar_exp '+' scalar_exp
	|	scalar_exp '-' scalar_exp
	|	scalar_exp '*' scalar_exp
	|	scalar_exp '/' scalar_exp
	|	atom
	|	column_ref
	|	function_ref
	|	'(' scalar_exp ')'
	;

scalar_exp_commalist:
		scalar_exp
	|	scalar_exp_commalist ',' scalar_exp
	;

atom:
		parameter_ref
	|	literal
	|	USER
	;

parameter_ref:
		parameter
	|	parameter parameter
	|	parameter INDICATOR parameter
	;

function_ref:
		AMMSC '(' '*' ')'
	|	AMMSC '(' DISTINCT column_ref ')'
	|	AMMSC '(' ALL scalar_exp ')'
	|	AMMSC '(' scalar_exp ')'
	;

literal:
		STRING
	|	INTNUM
	|	APPROXNUM
	;

	/* miscellaneous */

table_name:
		NAME
	|	NAME '.' NAME
	;

column_ref:
		NAME
	|	NAME '.' NAME	/* needs semantics */
	|	NAME '.' NAME '.' NAME
	;

		/* data types */

data_type:
		CHARACTER
	|	CHARACTER '(' INTNUM ')'
	|	NUMERIC
	|	NUMERIC '(' INTNUM ')'
	|	NUMERIC '(' INTNUM ',' INTNUM ')'
	|	DECIMAL
	|	DECIMAL '(' INTNUM ')'
	|	DECIMAL '(' INTNUM ',' INTNUM ')'
	|	INTEGER
	|	SMALLINT
	|	FLOAT
	|	FLOAT '(' INTNUM ')'
	|	REAL
	|	DOUBLE PRECISION
	;

	/* the various things you can name */

column:		NAME
	;

parameter:
		PARAMETER	/* :name handled in parser */
	;

range_variable:	NAME
	;

user:		NAME
	;
%%
