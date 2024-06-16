%{
/*
 * File Name   : subc.y
 * Description : a skeleton bison input
 */

#include "subc.h"
#include "subc.tab.h"

int    yylex ();
int    yyerror (char* s);
static int lastErrLine;
static decl *intType;
static decl *charType;
static decl *voidType;
static decl *nullType;
static id *returnid;

%}

/* yylval types */
%union yystacktype {
	int		intVal;
	double	floatVal;
	char	*stringVal;
	id		*idptr;
	decl	*declptr;
	ste		*steptr; 
}

%type	<declptr>	unary binary expr type_specifier struct_specifier func_decl and_list and_expr or_list or_expr args func_decl_m
%type	<idptr>		ID
%type	<intVal>	INTEGER_CONST TYPE VOID const_expr pointers
%type	<stringVal>	CHAR_CONST STRING

/* Precedences and Associativities */
%nonassoc   NO_ELSE
%nonassoc   ELSE
%left	','
%right  '='
%left   LOGICAL_OR
%left   LOGICAL_AND
%left   '|'
%left   '&'
%left   EQUOP
%left   RELOP
%left   '+' '-'
%left   '*' '/' '%'
%right   '!' INCOP DECOP
%left   '[' ']' '(' ')' '.' STRUCTOP

/* Token and Types */
/* declclass */
%token VAR CONST FUNC TYPE
%token STRUCT RETURN IF ELSE WHILE FOR BREAK CONTINUE LOGICAL_OR LOGICAL_AND INCOP DECOP STRUCTOP VOID STRING CHAR_CONST ID INTEGER_CONST NIL
%token INT CHAR POINTER ARRAY

%%
program
		: ext_def_list
		;

ext_def_list
		: ext_def_list ext_def
		| /* empty */
		;

ext_def
		: type_specifier pointers ID ';' // TODO omitted
		| type_specifier pointers ID '[' const_expr ']' ';' // TODO omitted
		| func_decl ';'
		| type_specifier ';'
		| func_decl {
			if (!$1) {
			} else {
				push_scope();
				declare(returnid, $1->returntype->type);
				push_ste_list($1->formals);
			}
		} compound_stmt { 
			if (!$1) {
			} else {
				pop_scope();
			}
		}

type_specifier
		: TYPE { $$ = getTypeDecl($1); }
		| VOID { $$ = getTypeDecl($1); }
		| struct_specifier {
			if (!($1)) $$ = NULL;
			else $$ = $1;
		}

struct_specifier
		: STRUCT ID '{' 
		{
			decl *found = findDecl($2);
			if (found) {
				yyerror("redeclaration");
			}
			$<declptr>$ = found;
			push_scope();
		}
		def_list
		{
			ste *fields = pop_scope();
			decl *found = $<declptr>4;
			if (found) {
				$<declptr>$ = NULL;
			} else {
				declareGlobal($2, ($<declptr>$ = makeStructDecl(fields)));
			}
		} '}' { $$ = $<declptr>6; }
		| STRUCT ID {
			decl *found = findDecl($2);
			if (found != NULL) {
				$$ = found;
			} else {
				yyerror("incomplete type");
				$$ = NULL;
			}
		}

func_decl
		: type_specifier pointers ID '(' func_decl_m ')' { 
			if (!($1 && $5)) {
				$$ = NULL;
				pop_scope();
			} else {
				ste *formals = pop_scope();
				decl *procDecl = $<declptr>5;
				decl *returnConstDecl = makeFuncReturnConstDecl(formals->decl);
				procDecl->returntype = returnConstDecl;
				procDecl->formals = formals->prev;
				$$ = procDecl;
			}
		}
		| type_specifier pointers ID '(' func_decl_m VOID ')' { 
			if (!($1 && $5)) {
				$$ = NULL;
				pop_scope();
			} else {
				ste *formals = pop_scope();
				decl *procDecl = $<declptr>5; 
				decl *returnConstDecl = makeFuncReturnConstDecl(formals->decl);
				procDecl->returntype = returnConstDecl;
				procDecl->formals = formals->prev;
				$$ = procDecl;
			}
		}
		| type_specifier pointers ID '(' func_decl_m param_list ')' {
			if (!($1 && $5)) {
				$$ = NULL;
				pop_scope();
			} else {
				ste *formals = pop_scope();
				decl *procDecl = $<declptr>5;
				decl *returnConstDecl = makeFuncReturnConstDecl(formals->decl);
				procDecl->returntype = returnConstDecl;
				procDecl->formals = formals->prev;
				$$ = procDecl;
			}
		}
func_decl_m
		: {
			if (!$<declptr>-3) {
				$$ = NULL;
				push_scope();
			} else if (findDecl($<idptr>-1)) {
				yyerror("redeclaration");
				push_scope();
				$$ = NULL;
			} else {	
				decl *procDecl = makeProcDecl();
				declareGlobal($<idptr>-1, procDecl);
				push_scope();
				if ($<intVal>-2) {
					declare(returnid, makePtrTypeDecl($<declptr>-3));
				} else {
					declare(returnid, $<declptr>-3);
				}
				$$ = procDecl;
			}
		} /* empty */

pointers
		: '*' { $$ = 1; }
		| { $$ = 0; } /* empty */

param_list  /* list of formal parameter declaration */
		: param_decl
		| param_list ',' param_decl

param_decl  /* formal parameter declaration */
		: type_specifier pointers ID {
			if (!($1 && $3)) {
			} else {
				if (findDeclInScope($3)) {
					yyerror("redeclaration");
				} else if($2) {
					declare($3, makeVarDecl((makePtrTypeDecl($1))));
				} else {
					declare($3, makeVarDecl($1));
				}
			}
		}
		| type_specifier pointers ID '[' const_expr ']' {
			if (!($1 && $3)) {
			} else {
				if (findDeclInScope($3)) {
					yyerror("redeclaration");
				} else if($2) {
					declare($3, makeArrayConstDecl(makeArrayDecl(makeVarDecl(makePtrTypeDecl($1)), $5)));
				} else {
					declare($3, makeArrayConstDecl(makeArrayDecl(makeVarDecl($1), $5)));
				}
			}
		}

def_list    /* list of definitions, definition can be type(struct), variable, function */
		: def_list def
		| /* empty */

def
		: type_specifier pointers ID ';' {
			if (!($1 && $3)) {
			} else {
				if (findDeclInScope($3)) {
					yyerror("redeclaration");
				} else if($2) {
					declare($3, makeVarDecl((makePtrTypeDecl($1))));
				} else {
					declare($3, makeVarDecl($1));
				}
			}
		}
		| type_specifier pointers ID '[' const_expr ']' ';' {
			if (!($1 && $3)) {
			} else {
				if (findDeclInScope($3)) {
					yyerror("redeclaration");
				} else if($2) {
					declare($3, makeArrayConstDecl(makeArrayDecl(makeVarDecl(makePtrTypeDecl($1)), $5)));
				} else {
					declare($3, makeArrayConstDecl(makeArrayDecl(makeVarDecl($1), $5)));
				}
			}
		}
		| type_specifier ';'
		| func_decl ';'

compound_stmt
		: '{' local_defs stmt_list '}'

local_defs  /* local definitions, of which scope is only inside of compound statement */
		:	def_list

stmt_list
		: stmt_list stmt
		| /* empty */

stmt
		: expr ';'
		| { push_scope(); } compound_stmt { pop_scope(); }
		| RETURN ';' {
			if (findDecl(returnid) != voidType) {
				yyerror("incompatible return types");
			}
		}
		| RETURN expr ';' {
			if (!$2) {
			} else {
				if (findDecl(returnid) != $2) {
					yyerror("incompatible return types");
				}
			}
		}
		| ';'
		| IF '(' expr ')' stmt %prec NO_ELSE
		| IF '(' expr ')' stmt ELSE stmt
		| WHILE '(' expr ')' stmt
		| FOR '(' expr_e ';' expr_e ';' expr_e ')' stmt
		| BREAK ';'
		| CONTINUE ';'

expr_e
		: expr
		| /* empty */

const_expr
		: expr { $$ = 0; }

expr
		: unary '=' expr {
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				if (check_var($1)) {
					if ($3 == nullType) {
						if (check_ptr_type($1)) {
							$$ = $1->type;
						} else {
							yyerror("RHS is not a const or variable");
							$$ = NULL;
						}
					} else {
						if (check_compare_type($1->type, $3)) {
							$$ = $1->type;
						} else {
							yyerror("LHS and RHS are not same type");
							$$ = NULL;
						}
					}
				} else {
					yyerror("LHS is not a variable");
					$$ = NULL;
				}
			}
		}
		| or_expr

or_expr
		: or_list

or_list
		: or_list LOGICAL_OR and_expr { 
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				if (intType == $1 && intType == $3) {
					$$ = $1;
				} else {
					yyerror("not computable");
					$$ = NULL;
				}
			}
		}
		| and_expr

and_expr
		: and_list

and_list
		: and_list LOGICAL_AND binary { 
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				if (intType == $1 && intType == $3) {
					$$ = $1;
				} else {
					yyerror("not computable");
					$$ = NULL;
				}
			}
		}
		| binary

binary
		: binary RELOP binary {
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				if((intType == $1 && intType == $3) ||
					(charType == $1 && charType == $3)) {
						$$ = intType;
				} else {
					yyerror("not comparable");
					$$ = NULL;
				}
			}
		}
		| binary EQUOP binary {
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				if((intType == $1 && intType == $3) || 
					(charType == $1 && charType == $3) ||
					($1->typeclass == POINTER && $3->typeclass == POINTER && $1->ptrto == $3->ptrto) ||
					($1->typeclass == POINTER && $3->typeclass == NIL) ||
					($1->typeclass == NIL && $3->typeclass == POINTER) ||
					($1->typeclass == NIL && $3->typeclass == NIL)) {
						$$ = intType;
				} else {
					yyerror("not comparable");
					$$ = NULL;
				}
			}
		}
		| binary '+' binary {
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				if(intType == $1 && intType == $3) {
					$$ = intType;
				} else {
					yyerror("not computable");
					$$ = NULL;
				}
			}
		}
		| binary '-' binary {
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				if(intType == $1 && intType == $3) {
				$$ = intType;
			} else {
				yyerror("not computable");
				$$ = NULL;
			}
			}
		}
		| unary %prec '=' { 
			if (!($1)) {
				$$ = NULL;
			} else {
				$$ = $1->type;
			}
		}

unary
		: '(' expr ')' {
			if (!($2)) {
				$$ = NULL;
			} else {
				$$ = makeDummyConstDecl($2);
			}
		}
		| '(' unary ')' {
			if (!($2)) {
				$$ = NULL;
			} else {
				$$ = $2;
			}
		}
		| INTEGER_CONST { $$ = makeIntConstDecl(intType, $1); }
		| CHAR_CONST { $$ = makeCharConstDecl(charType); }
		| STRING { $$ = makeCharConstDecl(makePtrTypeDecl(charType)); }
		| NIL { $$ = makeNullConstDecl(nullType); } // processing NULL
		| ID { 
			decl *found = findDecl($1);
			if (found) {
				$$ = found;
			} else {
				yyerror("not declared");
				$$ = NULL;
			}
		}
		| '-' unary	{ 
			if (!($2)) {
				$$ = NULL;
			} else {
				if(check_type(intType, $2)) {
					$$ = $2;
				} else {
					yyerror("not computable");
					$$ = NULL;
				}
			}
		 } %prec '!'
		| '!' unary {
			if (!($2)) {
				$$ = NULL;
			} else {
				if(check_type(intType, $2)) {
					$$ = $2;
				} else {
					yyerror("not computable");
					$$ = NULL;
				}
			}
		}
		| unary INCOP {
			if (!($1)) {
				$$ = NULL;
			} else {
				if(check_var($1) && (check_type(intType, $1) || check_type(charType, $1))) {
					$$ = $1;
				} else {
					yyerror("not computable");
					$$ = NULL;
				}
			}
		}
		| unary DECOP {
			if (!($1)) {
				$$ = NULL;
			} else {
				if(check_var($1) && (check_type(intType, $1) || check_type(charType, $1))) {
					$$ = $1;
				} else {
					yyerror("not computable");
					$$ = NULL;
				}
			}
		}
		| INCOP unary {
			if (!($2)) {
				$$ = NULL;
			} else {
				if(check_var($2) && (check_type(intType, $2) || check_type(charType, $2))) {
					$$ = $2;
				} else {
					yyerror("not computable");
					$$ = NULL;
				}
			}
		}
		| DECOP unary {
			if (!($2)) {
				$$ = NULL;
			} else {
				if(check_var($2) && (check_type(intType, $2) || check_type(charType, $2))) {
					$$ = $2;
				} else {
					yyerror("not computable");
					$$ = NULL;
				}
			}
		}
		| '&' unary	%prec '!' {
			if (!($2)) {
				$$ = NULL;
			} else {
				if (check_var($2)) {
					$$ = makeVarDecl(makePtrTypeDecl($2->type));
				} else {
					yyerror("not a variable");
					$$ = NULL;
				}
			}
		}
		| '*' unary	%prec '!' {
			if (!($2)) {
				$$ = NULL;
			} else {
				if (check_ptr_type($2)) {
					$$ = makeVarDecl($2->type->ptrto);
				} else {
					yyerror("not a pointer");
					$$ = NULL;
				}
			}
		}
		| unary '[' expr ']' {
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				if (check_array($1)) {
				$$ = $1->type->elementvar;
			} else {
				yyerror("not an array type");
				$$ = NULL;
			}
			}
		}
		| unary '.' ID {
			if (!($1)) {
				$$ = NULL;
			} else {
				if (check_struct($1)) {
					decl *fieldFound = check_struct_field($1->type->fieldlist, $3);
					if (fieldFound) {
						$$ = fieldFound;
					} else {
						yyerror("struct not have same name field");
						$$ = NULL;
					}
				} else {
					yyerror("not a struct");
					$$ = NULL;
				}
			}
		}
		| unary STRUCTOP ID {
			if (!($1)) {
				$$ = NULL;
			} else {
				if (check_ptr_type($1) && check_struct_typeclass($1->type->ptrto)) {
					decl *fieldFound = check_struct_field($1->type->ptrto->fieldlist, $3);
					if (fieldFound) {
						$$ = fieldFound;
					} else {
						yyerror("struct not have same name field");
						$$ = NULL;
					}
				} else {
					yyerror("not a struct pointer");
					$$ = NULL;
				}
			}
		}
		| unary '(' args ')' {
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				if (check_func($1)) {
					if (check_func_formals($1->formals, $3)) {
						$$ = $1->returntype;
					} else {
						yyerror("actual args are not equal to formal args");
						$$ = NULL;
					}
				} else {
					yyerror("not a function");
					$$ = NULL;
				}
			}
		}
		| unary '(' ')' {
			if (!$1) {
				$$ = NULL;
			} else {
				if (check_func($1)) {
					if ($1->formals == NULL) {
						$$ = $1->returntype;
					} else {
						yyerror("actual args are not equal to formal args");
						$$ = NULL;
					}
				} else {
					yyerror("not a function");
					$$ = NULL;
				}
			}
		}

args    /* actual parameters(function arguments) transferred to function */
		: expr {
			if (!$1) {
				$$ = NULL;
			} else {
				$$ = makeDummyConstDecl($1);
			}
		}
		| args ',' expr {
			if (!($1 && $3)) {
				$$ = NULL;
			} else {
				add_actual_arguments($1, makeDummyConstDecl($3));
				$$ = $1;
			}
		}
%%

/*  Additional C Codes here */
void init_scope() {
	push_scope(); // globalscope
	declare(enter(ID, "*globalscope", 12), NULL);
	set_globalscope();
	push_scope(); // localscope
}

void init_type() {
	lastErrLine = 0;
	intType = makeTypeDecl(INT);
	charType = makeTypeDecl(CHAR);
	voidType = makeTypeDecl(VOID);
	nullType = makeTypeDecl(NIL);
	returnid = enter(ID, "*return", 7);
	declare(enter(ID, "int", 3), intType);
	declare(enter(ID, "char", 4), charType);
	declare(enter(ID, "void", 4), voidType);
	declare(enter(ID, "NULL", 4), nullType);
}

decl *getTypeDecl(int type) {
	switch(type) {
		case INT: return intType;
		case CHAR: return charType;
		case VOID: return voidType;
		default: return voidType;
	}
}

int yyerror (char *s)
{
	int currLine = read_line();
	if (currLine > lastErrLine) {
		fprintf(stderr, "%s:%d: error:%s\n", read_filename(), currLine, s);
		lastErrLine = currLine;
	}
	return 1;
}