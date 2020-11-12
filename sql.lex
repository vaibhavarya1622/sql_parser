%{
#include "y.tab.h"
#include <string.h>

int lineno = 1;
void yyerror(char *s);

/* macro to save the text and return a token */
#define TOK(name) { save_str(yytext);return name; }
%}
%s SQL
%%

START_SQL	{ printf("SQL started\n");BEGIN SQL; start_save(); }


	/* literal keyword tokens */

<SQL>SET        TOK(SET)
<SQL>DROP       TOK(DROP)
<SQL>ALL		TOK(ALL)
<SQL>AND		TOK(AND)
<SQL>AVG		TOK(AMMSC)
<SQL>MIN		TOK(AMMSC)
<SQL>MAX		TOK(AMMSC)
<SQL>SUM		TOK(AMMSC)
<SQL>COUNT		TOK(AMMSC)
<SQL>ANY		TOK(ANY)
<SQL>AS			TOK(AS)
<SQL>ASC		TOK(ASC)
<SQL>BETWEEN		TOK(BETWEEN)
<SQL>BY			TOK(BY)
<SQL>CREATE		TOK(CREATE)
<SQL>DELETE		TOK(DELETE)
<SQL>DESC		TOK(DESC)
<SQL>DISTINCT	TOK(DISTINCT)
<SQL>FROM		TOK(FROM)
<SQL>DECIMAL	TOK(DECIMAL)
<SQL>INT(EGER)?	TOK(INTEGER)
<SQL>NUMERIC	TOK(NUMERIC)
<SQL>PRECISION	TOK(PRECISION)
<SQL>PRIMARY	TOK(PRIMARY)
<SQL>SMALLINT	TOK(SMALLINT)
<SQL>FLOAT		TOK(FLOAT)
<SQL>CHAR(ACTER)? TOK(CHARACTER)
<SQL>REAL		TOK(REAL)
<SQL>DOUBLE		TOK(DOUBLE)
<SQL>KEY		TOK(KEY)
<SQL>INSERT		TOK(INSERT)
<SQL>GROUP		TOK(GROUP)
<SQL>HAVING		TOK(HAVING)
<SQL>IN			TOK(IN)
<SQL>INTO		TOK(INTO)
<SQL>LIKE		TOK(LIKE)
<SQL>NOT		TOK(NOT)
<SQL>NULL		TOK(NULLX)
<SQL>OR			TOK(OR)
<SQL>ORDER		TOK(ORDER)
<SQL>DATABASE	TOK(DATABASE)
<SQL>SELECT		TOK(SELECT)
<SQL>TABLE		TOK(TABLE)
<SQL>TO			TOK(TO)
<SQL>UNION		TOK(UNION)
<SQL>UNIQUE		TOK(UNIQUE)
<SQL>UPDATE		TOK(UPDATE)
<SQL>USER		TOK(USER)
<SQL>VALUES		TOK(VALUES)
<SQL>VIEW		TOK(VIEW)
<SQL>WHERE		TOK(WHERE)
<SQL>IS         TOK(IS)

	/* punctuation */

<SQL>"="	|
<SQL>"<"	|
<SQL>">"	|
<SQL>"<="	|
<SQL>">="		TOK(COMPARISON)

<SQL>[-+*/(),.;]	TOK(yytext[0])

	/* names */
<SQL>[A-Za-z][A-Za-z0-9_]*	TOK(NAME)

	/* parameters */
<SQL>":"[A-Za-z][A-Za-z0-9_]*	{
			save_param(yytext+1);
			return PARAMETER;
		}

	/* numbers */

<SQL>[0-9]+	|
<SQL>[0-9]+"."[0-9]* |
<SQL>"."[0-9]*		TOK(INTNUM)

	/* strings */

<SQL>'[^'\n]*'	{
		int c = input();

		unput(c);	/* just peeking */
		if(c != '\'') {
			save_str(yytext);return STRING;
		} else
			yymore();
	}
		
<SQL>'[^'\n]*$	{	yyerror("Unterminated string"); }

<SQL>\n		{ save_str(" ");lineno++; }
\n		{ lineno++; ECHO; }

<SQL>[ \t\r]+	save_str(" ");	/* white space */

.		ECHO;	/* random non-SQL text */
%%

void yyerror(char *s)
{
	printf("%d: %s at %s\n", lineno, s, yytext);
}

int main()
{
	if(!yyparse())
		printf("Embedded SQL parse worked\n");
	else
		printf("Embedded SQL parse failed\n");
}

/* leave SQL lexing mode */
un_sql()
{
	BEGIN INITIAL;
}