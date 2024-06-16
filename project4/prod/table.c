#include "subc.h"
#include "subc.tab.h"
#include <stdlib.h>
#include <string.h>

static ste *defStackTop;
static scope *scopeStackTop;
static scope *globalScope;
static int label = 0;
static int str_label = 0;
static id *funcName;

void init_globalscope(id *name) {
    scope *newScope = (scope *)malloc(sizeof(scope));
    ste *firstSte = (ste *)malloc(sizeof(ste));
    newScope->prev = NULL;
    newScope->ste = firstSte;
    newScope->offset = 0;
    firstSte->name = name;
    firstSte->decl = NULL;
    firstSte->prev = NULL;
    defStackTop = firstSte;
    globalScope = newScope;
    scopeStackTop = newScope;
}

void push_scope() {
    scope *newScope = (scope *)malloc(sizeof(scope));
    if (scopeStackTop != NULL) {
        newScope->ste = scopeStackTop->ste;
    }
    newScope->prev = scopeStackTop;
    newScope->offset = 0;
    scopeStackTop = newScope;
}

ste *pop_scope() {
    ste *prev = NULL;
    ste *prev_prev = NULL;
    ste *iter = scopeStackTop->ste;
    scope *nextScopeTop = scopeStackTop->prev;
    while (iter != nextScopeTop->ste) {
        prev_prev = prev;
        prev = iter;
        iter = iter->prev;
        prev->prev = prev_prev;
    }
    scopeStackTop = nextScopeTop;
    defStackTop = scopeStackTop->ste;
    return prev;
}

/**
 * TYPE
 */
decl *makeTypeDecl(int typeclass) {
    decl *typeDecl = (decl *)malloc(sizeof(decl));
    typeDecl->declclass = TYPE;
    typeDecl->typeclass = typeclass;
    typeDecl->size = 1;
    return typeDecl;
}

decl *makeArrayDecl(decl *varDecl, int intVal) {
    decl *arrayDecl = (decl *)malloc(sizeof(decl));
    arrayDecl->declclass = TYPE;
    arrayDecl->typeclass = ARRAY;
    arrayDecl->elementvar = varDecl;
    arrayDecl->num_index = intVal;
    arrayDecl->size = varDecl->type->size * intVal;
    return arrayDecl;
}

decl *makePtrTypeDecl(decl *typeDecl) {
    decl *ptrDecl = (decl *)malloc(sizeof(decl));
    ptrDecl->declclass = TYPE;
    ptrDecl->typeclass = POINTER;
    ptrDecl->ptrto = typeDecl;
    ptrDecl->size = 1;
    return ptrDecl;
}

/**
 * VAR
 */
decl *makeVarDecl(decl *typeDecl) {
    decl *varDecl = (decl *)malloc(sizeof(decl));
    varDecl->declclass = VAR;
    varDecl->type = typeDecl;
    varDecl->scope = scopeStackTop;
    varDecl->size = scopeStackTop->offset;
    // printf("type is %d, size is %d, scopeOffset is %d\n", typeDecl->typeclass, typeDecl->size, scopeStackTop->offset);
    incrementScopeOffset(typeDecl->size);
    return varDecl;
}

decl *makeVarDeclNoOffset(decl *typeDecl) {
    decl *varDecl = (decl *)malloc(sizeof(decl));
    varDecl->declclass = VAR;
    varDecl->type = typeDecl;
    varDecl->scope = scopeStackTop;
    varDecl->size = scopeStackTop->offset;
    return varDecl;
}

/**
 * CONST
 */

decl *makeIntConstDecl(decl *typeDecl, int intVal) {
    decl *intConstDecl = (decl *)malloc(sizeof(decl));
    intConstDecl->declclass = CONST;
    intConstDecl->type = typeDecl;
    intConstDecl->value = intVal;
    intConstDecl->real_value = intVal;
    return intConstDecl;
}

decl *makeCharConstDecl(decl *typeDecl) {
    decl *charConstDecl = (decl *)malloc(sizeof(decl));
    charConstDecl->declclass = CONST;
    charConstDecl->type = typeDecl;
    return charConstDecl;
}

decl *makeNullConstDecl(decl *typeDecl) {
    decl *nullConstDecl = (decl *)malloc(sizeof(decl));
    nullConstDecl->declclass = CONST;
    nullConstDecl->type = typeDecl;
    return nullConstDecl;
}

decl *makeArrayConstDecl(decl *typeDecl) {
    decl *arrayConstDecl = (decl *)malloc(sizeof(decl));
    arrayConstDecl->declclass = CONST;
    arrayConstDecl->type = typeDecl;
    arrayConstDecl->size = scopeStackTop->offset - typeDecl->size/typeDecl->num_index;
    arrayConstDecl->scope = scopeStackTop;
    incrementScopeOffset(typeDecl->size - typeDecl->size/typeDecl->num_index);
    return arrayConstDecl;
}

decl *makeFuncReturnConstDecl(decl *typeDecl) {
    decl *returnConstDecl = (decl *)malloc(sizeof(decl));
    returnConstDecl->declclass = CONST;
    returnConstDecl->type = typeDecl;
    return returnConstDecl;
}

decl *makeDummyConstDecl(decl *typeDecl) {
    decl *dummyConstDecl = (decl *)malloc(sizeof(decl));
    dummyConstDecl->declclass = CONST;
    dummyConstDecl->type = typeDecl;
    dummyConstDecl->next = NULL;
    return dummyConstDecl;
}

/*
 * struct, func
 */

decl *makeStructDecl(ste *fields) {
    decl *structDecl = (decl *)malloc(sizeof(decl));
    int size = 0;
    structDecl->declclass = TYPE;
    structDecl->typeclass = STRUCT;
    structDecl->fieldlist = fields;
    structDecl->scope = globalScope;
    ste *iter = fields;
    while (iter != NULL) {
        size = size + iter->decl->type->size;
        iter = iter->prev;
    }
    structDecl->size = size;
    return structDecl;
}

decl *makeProcDecl() {
    decl *procDecl = (decl *)malloc(sizeof(decl));
    procDecl->declclass = FUNC;
    procDecl->formals = NULL;
    procDecl->returntype = NULL;
    procDecl->scope = globalScope;
    return procDecl;
}

decl *findDecl(id *name) {
    ste *iter = defStackTop;
    while(iter != NULL && iter->name != name) {
        iter = iter->prev;
    }
    if (iter != NULL) {
        return iter->decl;
    } else {
        return NULL;
    }
}

decl *findDeclInScope(id *name) {
    ste *iter = defStackTop;
    id *prevScopeTopId = scopeStackTop->prev->ste->name;
    while(iter != NULL && iter->name != name && iter->name != prevScopeTopId) {
        iter = iter->prev;
    }
    if (iter != NULL && iter->name != prevScopeTopId) {
        return iter->decl;
    } else {
        return NULL;
    }
}

void setFuncName(id *name) {
    funcName = name;
}

char *getFuncName() {
    if (funcName) {
        return funcName->name;
    } else return NULL;
}

int push_ste_list(ste *formals) {
    ste *iter = formals;
    int count = 0;
    while (iter != NULL) {
        declare(iter->name, iter->decl);
        iter = iter->prev;
        count++;
    }
    return count;
}

void add_actual_arguments(decl *args, decl *newArg) {
    decl *iter = args;
    while (iter->next != NULL) {
        iter = iter->next;
    }
    iter->next = newArg;
}

ste *declare(id *name, decl *decl) {
    if (scopeStackTop == globalScope) {
        return declareGlobal(name, decl);
    } else {
        ste *newSte = (ste *)malloc(sizeof(ste));
        newSte->name = name;
        newSte->decl = decl;
        newSte->prev = defStackTop;
        defStackTop = newSte;
        scopeStackTop->ste = newSte;
        return newSte;
    }
}

ste *declareGlobal(id *name, decl *decl) {
    ste *newSte = (ste *)malloc(sizeof(ste));
    newSte->name = name;
    newSte->decl = decl;
    newSte->prev = globalScope->ste->prev;
    globalScope->ste->prev = newSte;
    return newSte;
}

/**
 * offset
 */
void print_push(decl *decl) {
    if (decl->scope == globalScope) {
        printf("\tpush_const Lglob+%d\n", decl->size);
    } else {
        printf("\tpush_reg fp\n");
        printf("\tpush_const %d\n", decl->size+1);
        printf("\tadd\n");
    }
}

void print_shift_sp() {
    if (scopeStackTop->offset) {
        printf("\tshift_sp %d\n", scopeStackTop->offset);
    }
}

void incrementScopeOffset(int size) {
    scopeStackTop->offset = scopeStackTop->offset + size;
}

int new_label() {
    return label++;
}

int get_label() {
    return label;
}

int new_str_label() {
    return str_label++;
}

void printLglob() {
    printf("Lglob.\tdata %d\n", globalScope->offset);
}

void print_scope() {
    scope *iter = scopeStackTop;
    int count = 0;
    printf("[scope]  ");
    while (iter != NULL) {
        count++;
        printf("(%s: %d) | ", iter->ste->name->name, iter->offset);
        iter = iter->prev;
    }
    printf("END, %d scope(s)\n", count);
}

void print_defstack() {
    ste *iter = defStackTop;
    printf("[defstack]  ");
    while (iter != NULL) {
        printf("%s -> ", iter->name->name);
        iter = iter->prev;
    }
    printf("NULL\n");
}