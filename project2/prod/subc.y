%{
/*
 * File Name   : subc.y
 * Description : a skeleton bison input
 */

#include "subc.h"

int    yylex ();
int    yyerror (char* s);
void 	REDUCE(char* s);

%}

/* yylval types */
%union {
	int		intVal;
	char	*stringVal;
}

/* Precedences and Associativities */
%nonassoc   BELOW_ELSE
%nonassoc   ELSE
%left	','
%right  ASSIGNOP '='
%left   LOGICAL_OR
%left   LOGICAL_AND
%left   '|'
%left   '&'
%left   EQUOP
%left   RELOP
%left   '+' '-'
%left   '*' '/' '%'
%right   PLUS_PLUS MINUS_MINUS UNOT UMINUS UPTR UADDR
%left 	STRUCTOP
%nonassoc   '(' '['

/* Token and Types */
%token 				TYPE STRUCT RETURN IF ELSE WHILE FOR BREAK CONTINUE ASSIGNOP LOGICAL_OR LOGICAL_AND RELOP EQUOP PLUS_PLUS MINUS_MINUS STRUCTOP
%token<stringVal>	ID CHAR_CONST STRING
%token<intVal>		INTEGER_CONST

%%
program: ext_def_list	{ REDUCE("program->ext_def_list"); }
        ;
ext_def_list: ext_def_list ext_def	{ REDUCE("ext_def_list->ext_def_list ext_def"); }
        | /* empty */	{ REDUCE("ext_def_list->epsilon"); }
        ;
ext_def: opt_specifier ext_decl_list ';' { REDUCE("ext_def->opt_specifier ext_decl_list ';'"); }
        | opt_specifier funct_decl compound_stmt { REDUCE("ext_def->opt_specifier funct_decl compound_stmt"); }
        ;
ext_decl_list:	ext_decl { REDUCE("ext_decl_list->ext_decl"); }
		| ext_decl_list ',' ext_decl { REDUCE("ext_decl_list ',' ext_decl"); }
        ;
ext_decl: var_decl { REDUCE("ext_decl->var_decl"); }
		| funct_decl { REDUCE("ext_decl->funct_decl"); }
        ;
opt_specifier: type_specifier { REDUCE("opt_specifier->type_specifier"); }
		| /* empty */ { REDUCE("opt_specifier->epsilon"); }
        /*<= When the type specifier is omitted, the default type is 'int'*/
        ;
type_specifier:	TYPE { REDUCE("type_specifier->TYPE"); }
		| struct_specifier { REDUCE("type_specifier->struct_specifier"); }
        ;
struct_specifier: STRUCT opt_tag '{' def_list '}' { REDUCE("struct_specifier->STRUCT opt_tag '{' def_list '}'"); }
		| STRUCT ID { REDUCE("struct_specifier->STRUCT ID"); }
        /*<= In the second case, the struct must have been defined before.*/
        ;
opt_tag: ID { REDUCE("opt_tag->ID"); }
		| /* empty */ { REDUCE("opt_tag->epsilon"); }
        /* <= In the second case, the struct becomes anonymous. */
        ;
var_decl: ID { REDUCE("var_decl->ID"); }
		| ID '[' ']' { REDUCE("var_decl->ID '[' ']'"); }
		| ID '[' INTEGER_CONST ']' { REDUCE("var_decl->ID '[' INTEGER_CONST ']'"); }
		| '*' ID { REDUCE("var_decl->'*' ID"); }
        /* <= ID[] is the same as *ID. (pointer type) */
        ;
funct_decl:	ID '(' ')' { REDUCE("funct_decl->ID '(' ')'"); }
		| ID '(' var_list ')' { REDUCE("funct_decl->ID '(' var_list ')'"); }
	    /* <= When we declare a function with ID(), we want to have a function which has no parameter. */
        ;
var_list: param_decl { REDUCE("var_list->param_decl"); }
		| var_list ',' param_decl { REDUCE("var_list->var_list ',' param_decl"); }
        ;
param_decl:	type_specifier var_decl { REDUCE("param_decl->type+_specifier var_decl"); }
        ;
def_list: def_list def { REDUCE("def_list->def_list def"); }
		| /* empty */ { REDUCE("def_list->epsilon"); }
        ;
def: type_specifier decl_list ';' { REDUCE("def->type_specifier decl_list ';'"); }
        ;
decl_list: decl_list ',' decl { REDUCE("decl_list->decl_list ',' decl"); }
		| decl { REDUCE("decl_list->decl"); }
        ;
decl: funct_decl { REDUCE("decl->funct_decl"); }
		| var_decl { REDUCE("decl->var_decl"); }
        ;
compound_stmt:	'{' local_defs stmt_list '}' { REDUCE("compound_stmt->'{' local_defs stmt_list '}'"); }
        ;
local_defs:	def_list { REDUCE("local_defs->def_list"); }
        ;
stmt_list:	stmt_list stmt { REDUCE("stmt_list->stmt_list stmt"); }
		| /* empty */ { REDUCE("stmt_list->epsilon"); }
        ;
stmt: expr ';' { REDUCE("stmt->expr ';'"); }
		| compound_stmt { REDUCE("stmt->compound_stmt"); }
		| RETURN ';' { REDUCE("stmt->RETURN ';'"); }
		| RETURN expr ';' { REDUCE("stmt->RETURN expr ';'"); }
		| ';' { REDUCE("stmt->';'"); }
		| IF '(' test ')' stmt { REDUCE("stmt->IF '(' test ')' stmt"); } %prec BELOW_ELSE
		| IF '(' test ')' stmt ELSE stmt { REDUCE("stmt->IF '(' test ')' stmt ELSE stmt"); }
		| WHILE '(' test ')' stmt { REDUCE("stmt->WHILE '(' test ')' stmt"); }
		| FOR '(' opt_expr ';' test ';' opt_expr ')' stmt { REDUCE("stmt->FOR '(' opt_expr ';' test ';' opt_expr ')' stmt"); }
		| BREAK ';' { REDUCE("stmt->BREAK ';'"); }
		| CONTINUE ';' { REDUCE("stmt->CONTINUE ';'"); }
        ;
test:		expr { REDUCE("test->expr"); }
		| /* empty */ { REDUCE("test->epsilon"); }
        ;
opt_expr:	expr { REDUCE("opt_expr->expr"); }
		| /* empty */ { REDUCE("opt_expr->epsilon"); }
        ;
expr:		expr ASSIGNOP expr { REDUCE("expr->expr ASSIGNOP expr"); }
		| expr '=' expr { REDUCE("expr->expr '=' expr"); }
		| or_expr { REDUCE("expr->or_expr"); }
        ;
or_expr:	or_list { REDUCE("or_expr->or_list"); }
        ;
or_list:	or_list LOGICAL_OR and_expr { REDUCE("or_list->or_list LOGICAL_OR and_expr"); }
		| or_list '|' and_expr { REDUCE("or_list->or_list '|' and_expr"); }
		| and_expr { REDUCE("or_list->and_expr"); }
        ;
and_expr:	and_list { REDUCE("and_expr->and_list"); }
        ;
and_list:	and_list LOGICAL_AND binary { REDUCE("and_list->and_list LOGICAL_AND binary"); }
		| and_list '&' binary { REDUCE("and_list->and_list '&' binary"); }
		| binary { REDUCE("and_list->binary"); }
        ;
binary:		binary RELOP binary { REDUCE("binary->binary RELOP binary"); }
		| binary EQUOP binary { REDUCE("binary->binary EQUOP binary"); }
		| binary '*' binary { REDUCE("binary->binary '*' binary"); }
		| binary '/' binary { REDUCE("binary->binary '/' binary"); }
		| binary '%' binary { REDUCE("binary->binary '%' binary"); }
		| binary '+' binary { REDUCE("binary->binary '+' binary"); }
		| binary '-' binary { REDUCE("binary->binary '-' binary"); }
		| unary { REDUCE("binary->unary"); }
        ;
unary:		'(' expr ')' { REDUCE("unary->'(' expr ')'"); }
		| INTEGER_CONST { REDUCE("unary->INTEGER_CONST"); }
		| CHAR_CONST { REDUCE("unary->CHAR_CONST"); }
		| ID { REDUCE("unary->ID"); }
		| STRING { REDUCE("unary->STRING"); }
		| '-' unary { REDUCE("unary->'-' unary"); } %prec UMINUS
		| '!' unary { REDUCE("unary->'!' unary"); } %prec UNOT
		| unary PLUS_PLUS { REDUCE("unary->unary PLUS_PLUS"); }
		| unary MINUS_MINUS { REDUCE("unary->unary MINUS_MINUS"); }
		| '&' unary { REDUCE("unary->'&' unary"); } %prec UADDR
		| '*' unary	{ REDUCE("unary->'*' unary"); } %prec UPTR //<= The type of unary is pointer.
		| unary '[' expr ']' { REDUCE("unary->unary '[' expr ']'"); }	//<= The type of expr is integer.
		| unary STRUCTOP ID { REDUCE("unary->unary STRUCTOP ID"); } //<= The type of unary is a struct.
		| unary '(' args ')' { REDUCE("unary->unary '(' args ')'"); } //<= The type of unary is a function.
		| unary '(' ')' { REDUCE("unary->unary '(' ')'"); }
        ;
args:		expr { REDUCE("args->expr"); }
		| args ',' expr { REDUCE("args->args ',' expr"); }
        ;
%%

/*  Additional C Codes  */

int    yyerror (char* s)
{
	fprintf (stderr, "%s\n", s);
}

void 	REDUCE( char* s)
{
	printf("%s\n",s);
}
