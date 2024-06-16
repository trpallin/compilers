%{
/*
 * File Name   : subc.l
 * Description : a skeleton flex input
 */

#include "subc.h"
#include "subc.tab.h"
static int comment_depth = 0;
static int lineno = 1;
static char *filename;
%}

/* regular definitions */
letter			[A-Za-z_]
digit			[0-9]
id				{letter}({letter}|{digit})*
integer_const	([1-9]{digit}*)|"0"
white-space		[ \t]+
special-char	\\[nt]


%x COMMENT
%%
"int" 		{
	yylval.intVal = INT;
	return TYPE;
	}
"char"		{ 
	yylval.intVal = CHAR;
	return TYPE; 
	}
"void"		{ 
	yylval.intVal = VOID;
	return VOID;
	}
"NULL"		{ return NIL; }
"struct" 	{ return STRUCT; }
"return"	{ return RETURN; }
"if"		{ return IF; }
"else"		{ return ELSE; }
"while"		{ return WHILE; }
"for"		{ return FOR; }
"break"		{ return BREAK; }
"continue"	{ return CONTINUE; }
"||"		{ return LOGICAL_OR; }
"&&"		{ return LOGICAL_AND; }
"<"		|
"<="	|
">"		|
">=" 		{ return RELOP; }
"=="	|
"!="		{ return EQUOP; }
"++"		{ return INCOP; }
"--"		{ return DECOP; }
"->"		{ return STRUCTOP; }
{id}	{
		   yylval.idptr = enter(ID, yytext, yyleng);
		   return yylval.idptr->tokenType;
		}
{integer_const}	{
		   yylval.intVal = atoi(yytext);
		   return INTEGER_CONST;
		}
\"({special-char}|[^\\\"\n])*\"	{
			/* String Variable */
		   yylval.stringVal = yytext;
		   return STRING;
		}
'({special-char}|[^\\'\n])'	{
			/* Character Variable */
		   yylval.stringVal = yytext;
		   return CHAR_CONST;
		}
"("|")"|"["|"]"|"{"|"}"|";"|","|"."|"="|"+"|"-"|"*"|"%"|"/"|"&"|"|"|"!" { return yytext[0]; }
{white-space}
<*>\n		   ++lineno;
<INITIAL,COMMENT>"/*"	{
		   ++comment_depth;
		   BEGIN (COMMENT);
		}
<COMMENT>"*/"	   if(--comment_depth == 0) BEGIN (INITIAL);
<COMMENT>.		 {}


%%

int read_line()
{
	return lineno;
}

char *read_filename() {
	return filename;
}

int main(int argc, char* argv[])
{
	init_scope();
	init_type();
	startup_code();
	lineno = 1;
	if(argc >= 2) {
		filename = argv[1];
		yyin = fopen(argv[1], "r");
	} else yyin = stdin;
	if(!yyin) {
		printf("Can't open input stream!\n");
		exit(1);
	}
	yyparse();
	printLglob();
	fclose(yyin);
	return 0;
}
