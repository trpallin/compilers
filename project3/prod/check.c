#include "subc.h"
#include "subc.tab.h"
#include <stdlib.h>
#include <string.h>

int check_lhs_var(decl *decl) {
    if (decl->declclass != VAR) {
        yyerror("LHS is not a variable");
        return 1;
    }
    return 0;
}

int check_compatible(decl *lhs, decl *rhs) {
    if (lhs->type != rhs->type) {
        yyerror("LHS and RHS are not same type");
        return 1;
    }
    return 0;
}

int check_type(decl *type, decl *decl) {
    return decl->type == type;
}

int check_ptr_type(decl *decl) {
    return decl->type->typeclass == POINTER;
}

int check_array(decl *decl) {
    return decl->type->typeclass == ARRAY;
}

int check_struct(decl *decl) {
    return decl->type->typeclass == STRUCT;
}

int check_struct_typeclass(decl *decl) {
    return decl->typeclass == STRUCT;
}

int check_var(decl *decl) {
    return decl->declclass == VAR;
}

int check_func(decl *decl) {
    return decl->declclass == FUNC;
}

decl *check_struct_field(ste *fieldlist, id *name) {
    ste *iter = fieldlist;
    while (iter != NULL) {
        if (iter->name == name) return iter->decl;
        iter = iter->prev;
    }
    return NULL;
}

int check_compare_type(decl *type1, decl *type2) {
    if (type1 == type2) {
        return 1;
    } else if (type1->typeclass == POINTER && type2->typeclass == POINTER) {
        if (type1->ptrto == type2->ptrto) return 1;
        else return 0;
    } else return 0;
}

int check_func_formals(ste *formals, decl *actuals) {
    ste *formalsIter = formals;
    while (formalsIter != NULL && actuals != NULL) {
        if (formalsIter->decl->type != actuals->type) {
            if ((check_ptr_type(formalsIter->decl) && check_ptr_type(actuals)) &&
                (formalsIter->decl->type->ptrto == actuals->type->ptrto)) {
            } else return 0;
        }
        formalsIter = formalsIter->prev;
        actuals = actuals->next;
    }
    if (formalsIter != NULL || actuals != NULL) {
        return 0;
    }
    return 1;
}