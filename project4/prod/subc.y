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
static id *name;
static int isVarLine = 0;
static int needFetch = 0;

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

%type	<declptr>	unary binary expr type_specifier struct_specifier and_list and_expr or_list or_expr args
%type	<idptr>		ID
%type	<intVal>	INTEGER_CONST TYPE VOID const_expr pointers
%type	<stringVal>	CHAR_CONST STRING
%type	<steptr>	func_decl func_decl_m

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
		: type_specifier pointers ID ';' {
			if (!($1 && $3)) {
			} else {
				if (findDecl($3)) {
					yyerror("redeclaration");
				} else if($2) {
					declareGlobal($3, makeVarDecl((makePtrTypeDecl($1))));
				} else {
					declareGlobal($3, makeVarDecl($1));
				}
			}
		}
		| type_specifier pointers ID '[' const_expr ']' ';' {
			if (!($1 && $3)) {
			} else {
				if (findDecl($3)) {
					yyerror("redeclaration");
				} else if($2) {
					declare($3, makeArrayConstDecl(makeArrayDecl(makeVarDecl(makePtrTypeDecl($1)), $5)));
				} else {
					declare($3, makeArrayConstDecl(makeArrayDecl(makeVarDecl($1), $5)));
				}
			}
		}
		| func_decl ';' // TODO print func_name: ??
		| type_specifier ';'
		| func_decl {
			if (!$1) {
				$<steptr>$ = NULL;
			} else {
				printf("%s:\n", $1->name->name);
				setFuncName($1->name);
				push_scope();
				declare(returnid, $1->decl->returntype->type);
				push_ste_list($1->decl->formals);
				$<idptr>$ = $1->name;
			}
		} compound_stmt {
			if (!$1) {
			} else {
				setFuncName($1->name);
				printf("%s_final:\n", $1->name->name);
				printf("\tpush_reg fp\n");
				printf("\tpop_reg sp\n");
				printf("\tpop_reg fp\n");
				printf("\tpop_reg pc\n");
				printf("%s_end:\n", $1->name->name);
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
				decl *procDecl = $5->decl;
				decl *returnConstDecl = makeFuncReturnConstDecl(formals->decl);
				procDecl->returntype = returnConstDecl;
				procDecl->formals = formals->prev;
				procDecl->size = 0;
				$$ = $5;
			}
		}
		| type_specifier pointers ID '(' func_decl_m VOID ')' { 
			if (!($1 && $5)) {
				$$ = NULL;
				pop_scope();
			} else {
				ste *formals = pop_scope();
				decl *procDecl = $5->decl;
				decl *returnConstDecl = makeFuncReturnConstDecl(formals->decl);
				procDecl->returntype = returnConstDecl;
				procDecl->formals = formals->prev;
				procDecl->size = 0;
				$$ = $5;
			}
		}
		| type_specifier pointers ID '(' func_decl_m param_list ')' {
			if (!($1 && $5)) {
				$$ = NULL;
				pop_scope();
			} else {
				ste *formals = pop_scope();
				decl *procDecl = $5->decl;
				decl *returnConstDecl = makeFuncReturnConstDecl(formals->decl);
				procDecl->returntype = returnConstDecl;
				procDecl->formals = formals->prev;
				int count = 0;
				ste *iter = procDecl->formals;
				while (iter != NULL) {
					count++;
					iter = iter->prev;
				}
				procDecl->size = count;
				$$ = $5;
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
				$$ = declareGlobal($<idptr>-1, procDecl);
				push_scope();
				if ($<intVal>-2) {
					declare(returnid, makePtrTypeDecl($<declptr>-3));
				} else {
					declare(returnid, $<declptr>-3);
				}
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
		: '{' local_defs {
			if ($<idptr>0) {
				print_shift_sp();
				printf("%s_start:\n", getFuncName());
			}
		} stmt_list '}'

local_defs  /* local definitions, of which scope is only inside of compound statement */
		:	def_list

stmt_list
		: stmt_list stmt
		| /* empty */

stmt
		: expr ';' {
			if (isVarLine) {
				isVarLine = 0;
				printf("\tshift_sp -1\n");
			}
		}
		| { push_scope(); $<idptr>$ = NULL; } compound_stmt { pop_scope(); }
		| RETURN ';' {
			if (findDecl(returnid) != voidType) {
				yyerror("incompatible return types");
			}
			printf("\tjump %s_final\n", getFuncName());
		}
		| RETURN {
			printf("\tpush_reg fp\n");
			printf("\tpush_const -1\n");
			printf("\tadd\n");
			printf("\tpush_const -1\n");
			printf("\tadd\n");
		} expr ';' {
			if (!$3) {
			} else {
				if (findDecl(returnid) != $3) {
					yyerror("incompatible return types");
				} else {
					printf("\tassign\n");
					printf("\tjump %s_final\n", getFuncName());
				}
			}
		}
		| ';'
		| IF '(' if_labeling expr ')' if_sub stmt {
			printf("label_%d:\n", get_label());
		} %prec NO_ELSE
		| IF '(' if_labeling expr ')' if_sub stmt ELSE {
			int oldLabel = new_label();
			printf("\tjump label_%d\n", get_label());
			printf("label_%d:\n", oldLabel);
		} stmt {
			printf("label_%d:\n", get_label());
		}
		| WHILE '(' expr ')' stmt
		| FOR '(' expr_e ';' expr_e ';' expr_e ')' stmt
		| BREAK ';'
		| CONTINUE ';'

if_labeling
		: {
			printf("label_%d:\n", new_label());
		}

if_sub
		: {
			printf("\tbranch_false label_%d\n", get_label());
		}

expr_e
		: expr
		| /* empty */

const_expr
		: INTEGER_CONST { $$ = $1; }

expr
		: unary '=' {
			printf("\tpush_reg sp\n");
			printf("\tfetch\n");
		} expr {
			if (!($1 && $4)) {
				$$ = NULL;
			} else {
				if (check_var($1)) {
					if ($4 == nullType) {
						if (check_ptr_type($1)) {
							printf("\tassign\n");
							printf("\tfetch\n");
							isVarLine = 1;
							needFetch = 0;
							$$ = $1->type;
						} else {
							yyerror("RHS is not a const or variable");
							$$ = NULL;
						}
					} else {
						if (check_compare_type($1->type, $4)) {
							printf("\tassign\n");
							printf("\tfetch\n");
							isVarLine = 1;
							needFetch = 0;
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
						printf("\tequal\n");
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
					printf("\tadd\n");
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
					printf("\tsub\n");
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
				if (check_var($1)) {
					if (needFetch) {
						printf("\tfetch\n");
						needFetch = 0;
					}
				}
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
		| INTEGER_CONST {
			printf("\tpush_const %d\n", $1);
			$$ = makeIntConstDecl(intType, $1);
			}
		| CHAR_CONST {
			printf("\tpush_const %s\n", $1);
			$$ = makeCharConstDecl(charType);
			}
		| STRING {
			int str_label = new_str_label();
			printf("str_%d. string %s\n", str_label, $1);
			printf("\tpush_const str_%d\n", str_label);
			$$ = makeCharConstDecl(makePtrTypeDecl(charType));
			}
		| NIL { $$ = makeNullConstDecl(nullType); } // processing NULL
		| ID { 
			decl *found = findDecl($1);
			if (found) {
				if (check_var(found) || check_array(found)) {
					print_push(found);
					needFetch = 1;
				} else if (check_func(found)) {
					name = $1;
				}
				$$ = found;
			} else if (strcmp($1->name, "write_int") || strcmp($1->name, "write_string")) {
				name = $1;
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
					printf("\tfetch\n");
					printf("\tnegate\n");
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
					printf("\tfetch\n");
					printf("\tnot\n");
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
					printf("\tpush_reg sp\n");
					printf("\tfetch\n");
					printf("\tpush_reg sp\n");
					printf("\tfetch\n");
					printf("\tfetch\n");
					printf("\tpush_const 1\n");
					printf("\tadd\n");
					printf("\tassign\n");
					printf("\tfetch\n");
					printf("\tpush_const 1\n");
					printf("\tsub\n");
					if (check_type(intType, $1)) {
						$$ = makeIntConstDecl(intType, 0); // TODO
					} else if (check_type(charType, $1)) {
						$$ = makeCharConstDecl(charType);
					} else {
						$$ = NULL;
					}
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
					printf("\tpush_reg sp\n");
					printf("\tfetch\n");
					printf("\tpush_reg sp\n");
					printf("\tfetch\n");
					printf("\tfetch\n");
					printf("\tpush_const 1\n");
					printf("\tsub\n");
					printf("\tassign\n");
					printf("\tfetch\n");
					printf("\tpush_const 1\n");
					printf("\tadd\n");
					if (check_type(intType, $1)) {
						$$ = makeIntConstDecl(intType, 0); // TODO
					} else if (check_type(charType, $1)) {
						$$ = makeCharConstDecl(charType);
					} else {
						$$ = NULL;
					}
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
					printf("\tpush_reg sp\n");
					printf("\tfetch\n");
					printf("\tpush_reg sp\n");
					printf("\tfetch\n");
					printf("\tfetch\n");
					printf("\tpush_const 1\n");
					printf("\tadd\n");
					printf("\tassign\n");
					printf("\tfetch\n");
					if (check_type(intType, $2)) {
						$$ = makeIntConstDecl(intType, 0); // TODO
					} else if (check_type(charType, $2)) {
						$$ = makeCharConstDecl(charType);
					} else {
						$$ = NULL;
					}
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
					printf("\tpush_reg sp\n");
					printf("\tfetch\n");
					printf("\tpush_reg sp\n");
					printf("\tfetch\n");
					printf("\tfetch\n");
					printf("\tpush_const 1\n");
					printf("\tsub\n");
					printf("\tassign\n");
					printf("\tfetch\n");
					if (check_type(intType, $2)) {
						$$ = makeIntConstDecl(intType, 0); // TODO
					} else if (check_type(charType, $2)) {
						$$ = makeCharConstDecl(charType);
					} else {
						$$ = NULL;
					}
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
					needFetch = 0;
					$$ = makeVarDeclNoOffset(makePtrTypeDecl($2->type));
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
					needFetch = 1;
					printf("\tfetch\n");
					$$ = makeVarDeclNoOffset($2->type->ptrto);
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
					needFetch = 1;
					int elementSize = $1->type->elementvar->type->size;
					if (elementSize > 1) {
						printf("\tpush_const %d\n", $1->type->elementvar->type->size);
						printf("\tmul\n");
					}
					printf("\tadd\n");
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
						needFetch = 1;
						if (fieldFound->size) {
							printf("\tpush_const %d\n", fieldFound->size);
							printf("\tadd\n");
						}
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
						needFetch = 1;
						if (fieldFound->size) {
							printf("\tpush_const %d\n", fieldFound->size);
							printf("\tadd\n");
						}
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
		| unary '(' {
			if (!strcmp(name->name, "write_int") || !strcmp(name->name, "write_string")) {
			} else {
				int labelNum = new_label();
				printf("\tshift_sp 1\n");
				printf("\tpush_const label_%d\n", labelNum);
				printf("\tpush_reg fp\n");
				$<intVal>$ = labelNum;
			}
		} args ')' {
			if (!($1 && $4)) {
				$$ = NULL;
			} else {
				if (check_func($1)) {
					if (check_func_formals($1->formals, $4)) {
						printf("\tpush_reg sp\n");
						printf("\tpush_const -%d\n", $1->size);
						printf("\tadd\n");
						printf("\tpop_reg fp\n");
						printf("\tjump %s\n", name->name);
						printf("label_%d:\n", $<intVal>3);
						isVarLine = 1;
						$$ = $1->returntype;
					} else {
						yyerror("actual args are not equal to formal args");
						$$ = NULL;
					}
				} else if (!strcmp(name->name, "write_int") || !strcmp(name->name, "write_string")) {
					printf("\t%s\n", name->name);
				} else {
					yyerror("not a function");
					$$ = NULL;
				}
			}
		}
		| unary '(' {
			int labelNum = new_label();
			printf("\tshift_sp 1\n");
			printf("\tpush_const label_%d\n", labelNum);
			$<intVal>$ = labelNum;
		} ')' {
			if (!$1) {
				$$ = NULL;
			} else {
				if (check_func($1)) {
					if ($1->formals == NULL) {
						printf("\tjump %s\n", name->name);
						printf("label_%d:\n", $<intVal>3);
						isVarLine = 1;
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
	init_globalscope(enter(ID, "*globalscope", 12));
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

void startup_code() {
	// printf("\tshift_sp 1\n");
	printf("\tpush_const EXIT\n");
	printf("\tpush_reg fp\n");
	printf("\tpush_reg sp\n");
	printf("\tpop_reg fp\n");
	printf("\tjump main\n");
	printf("EXIT:\n");
	printf("\texit\n");
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
		// fprintf(stderr, "%s:%d: error:%s\n", read_filename(), currLine, s);
		lastErrLine = currLine;
	}
	return 1;
}