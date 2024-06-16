/******************************************************
 * File Name   : subc.h
 * Description
 *    This is a header file for the subc program.
 ******************************************************/

#ifndef __SUBC_H__
#define __SUBC_H__

#include <stdio.h>
#include <strings.h>

typedef struct id {
	int tokenType;
	char *name;
} id;

typedef struct scope {
	struct ste *ste;
	struct scope *prev;
	int offset;
} scope;

typedef struct ste {
	struct id *name;
	struct decl *decl;
	struct ste *prev;
} ste;

typedef struct decl {
	int declclass;		/* DECL class: VAR, CONST, FUNC, TYPE  */
	struct decl *type;			/* VAR, CONST: pointer to its TYPE decl */
	int value;			/* CONST: value of integer constant */ 
	float real_value;	/* CONST: value of float constant */
	struct ste *formals;		/* FUNC: pointer to formal argument list */
	struct decl *returntype;	/* FUNC: pointer to return TYPE decl */
	int typeclass;		/* TYPE: type class: INT, array, ptr, … */
	struct decl *elementvar;	/* TYPE (array): ptr to element VAR decl */
	int num_index;		/* TYPE (array): number of elements */
	struct ste *fieldlist;		/* TYPE (struct): ptr to field list */
	struct decl *ptrto;		/* TYPE (pointer): type of the pointer */
	int size;			/* ALL: size in bytes */
	struct scope *scope;		/* VAR: scope when VAR declared */
	struct decl *next;			/* For list_of_variables declarations */ 
} decl;					/* Or parameter check of function call */

/* hash.c */
unsigned hash(char *name);
id *enter(int tokenType, char *name, int length);
void print_hashtable();

/* table.c */
void init_globalscope();
void push_scope();
ste *pop_scope();
decl *makeTypeDecl(int declType);
decl *makeArrayDecl(decl *varDecl, int intVal);
decl *makePtrTypeDecl(decl *typeDecl);
decl *makeVarDecl(decl *typeDecl);
decl *makeVarDeclNoOffset(decl *typeDecl);
decl *makeIntConstDecl(decl *typeDecl, int intVal);
decl *makeCharConstDecl(decl *typeDecl);
decl *makeNullConstDecl(decl *typeDecl);
decl *makeArrayConstDecl(decl *typeDecl);
decl *makeFuncReturnConstDecl(decl *typeDecl);
decl *makeDummyConstDecl(decl *typeDecl);
decl *makeStructDecl(ste *fields);
decl *makeProcDecl();
decl *findDecl(id *name);
decl *findDeclInScope(id *name);
void setFuncName(id *name);
char *getFuncName();
int push_ste_list(ste *formals);
void add_actual_arguments(decl *args, decl *newArg);
ste *declare(id *name, decl *decl);
ste *declareGlobal(id *name, decl *decl);
void print_scope();
void print_defstack();
void print_push(decl *decl);
void print_shift_sp();
void incrementScopeOffset(int size);
int new_label();
int get_label();
int new_str_label();
void printLglob();

/* check.c */
int check_lhs_var(decl *decl);
int check_compatible(decl *lhs, decl *rhs);
int check_rhs_null();
int check_type(decl *type, decl *decl);
int check_ptr_type(decl *decl);
int check_array(decl *decl);
int check_struct(decl *decl);
int check_struct_typeclass(decl *decl);
int check_var(decl *decl);
int check_func(decl *decl);
decl *check_struct_field(ste *fieldlist, id *name);
int check_compare_type(decl *type1, decl *type2);
int check_func_formals(ste *formals, decl *actuals);

/* etc */
int read_line();
char *read_filename();
void init_scope();
void init_type();
void startup_code();
decl *getTypeDecl(int type);
int yyerror(char *s);

#endif
