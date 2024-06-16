/***************************************************************
 * File Name    : hash.c
 * Description
 *      This is an implementation file for the open hash table.
 *
 ****************************************************************/

#include "subc.h"
#include "subc.tab.h"
#include <stdlib.h>
#include <string.h>

#define  HASH_TABLE_SIZE   101

typedef struct nlist {
	struct nlist *next;
	id *data;
} nlist;

static nlist *hashTable[HASH_TABLE_SIZE];

/* Digit folding method for hash function */
unsigned hash(char *name) {
	int i;
	int sum = 0;

	for (i = 0; name[i] != '\0'; i++) {
		sum += name[i];
	}

	return sum % HASH_TABLE_SIZE;
}

id *enter(int tokenType, char *name, int length) {
	unsigned hs = hash(name);
	nlist *prev = NULL;
	nlist *iter = hashTable[hs];

	while (iter != NULL) {
		if (strcmp(iter->data->name, name) == 0) {
			return iter->data;
		}
		prev = iter;
		iter = iter->next;
	}
	nlist *new_nlist = (nlist *)malloc(sizeof(nlist));
	id *new_id = (id *)malloc(sizeof(id));
	char *nameToInsert = (char *)malloc(sizeof(length));
	strcpy(nameToInsert, name);
	new_nlist->data = new_id;
	new_nlist->next = NULL;
	new_id->name = nameToInsert;
	new_id->tokenType = tokenType;
	if (prev == NULL) hashTable[hs] = new_nlist;
	else prev->next = new_nlist;

	return new_id;
}

/* for debugging */
void print_hashtable() {
	printf("************* PRINT HASHTABLE START **************\n");
	for (int i = 0; i < HASH_TABLE_SIZE; i++) {
		nlist *iter = hashTable[i];
		if (iter != NULL) {
			printf("  [%d] ", i);
			while(iter != NULL) {
				printf("(%s) -> ", iter->data->name);
				iter = iter->next;
			}
			printf("NULL\n");
		}
	}
	printf("************* PRINT HASHTABLE END **************\n");
}