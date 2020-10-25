/*
 *	Text handling routines for simple embedded SQL
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

char save_buf[2000]; /* buffer for SQL command */
char *savebp;		 /* current buffer pointer */

#define NPARAM 20		/* max params per function */
char *varnames[NPARAM]; /* parameter names */

/* start an embedded command after EXEC SQL */
void start_save(void)
{

	savebp = save_buf;
} /* start_save */

/* save a SQL token */
void save_str(char *s)
{

	strcpy(savebp, s);
	savebp += strlen(s);
} /* save_str */

/* save a parameter reference */
void save_param(char *n)
{
	int i;
	char pbuf[10];

	/* look up the variable name in the table */

	for (i = 1; i < NPARAM; i++)
	{
		if (!varnames[i])
		{

			/* not there, enter it */
			varnames[i] = strdup(n);
			break;
		}

		if (!strcmp(varnames[i], n))
			break; /* already present */
	}

	if (i >= NPARAM)
	{
		yyerror("Too many parameter references");
		exit(1);
	}

	/* save #n referece by variable number */
	sprintf(pbuf, " #%d", i);
	save_str(pbuf);

} /* save_param */

/* end of SQL command, now write it out */
void end_sql(void)
{
	int i;
	register char *cp;

	savebp--; /* back over the closing semicolon */

	/* call exec_sql function */

	printf("exec_sql(\"");

	/* write out saved buffer as a big C string
	 * starting new lines as needed
	 */

	for (cp = save_buf, i = 20; cp < savebp; cp++, i++)
	{
		if (i > 70)
		{ /* need new line */
			printf("\\\n");
			i = 0;
		}
		printf("%c", *cp);
	}
	printf("\"");

	/* pass address of every referenced variable */
	for (i = 1; i < NPARAM; i++)
	{
		if (!varnames[i])
			break;
		printf(",\n\t&%s", varnames[i]);
		free(varnames[i]);
		varnames[i] = 0;
	}

	printf(");\n");

} /* end_sql */