/***************************************************************
 * File Name    : hash.c
 * Description
 *      This is an implementation file for the open hash table.
 *
 ****************************************************************/

#include "subc.h"
#include "subc.tab.h"
#include <stdlib.h>

#define  HASH_TABLE_SIZE   101

typedef struct nlist {
	struct nlist *next;
	id *data;
} nlist;

static nlist *hashTable[HASH_TABLE_SIZE];

id *enter(int tokenType, char *name, int length) {
	/* implementation is given here */
	id *test = insertOrIncrease(name, tokenType, length);
	return test;
}

/* Digit folding method for hash function */
unsigned hash(char *name) {
	int i;
	int sum = 0;

	for (i = 0; name[i] != '\0'; i++) {
		sum += name[i];
	}

	return sum % HASH_TABLE_SIZE;
}

id *insertOrIncrease(char *name, int tokenType, int length) {
	unsigned hs = hash(name);
	nlist *iter = hashTable[hs];

	if (iter == NULL) {
		// when insert to null pointer
		nlist *next = (nlist *)malloc(sizeof(nlist));
		id *nextData = (id *)malloc(sizeof(id));
		char *nameToInsert = (char *)malloc(sizeof(length));
		strcpy(nameToInsert, name);
		// for KEYWORDs first insertion when initializing hash table
		if (tokenType != ID) nextData->count = 0;
		else nextData->count = 1;
		nextData->tokenType = tokenType;
		nextData->name = nameToInsert;
		next->data = nextData;
		next->next = NULL;
		hashTable[hs] = next;
		return next->data;
	}
	
	while(iter->next != NULL && strcmp(iter->data->name, name) != 0) {
		iter = iter->next;
	}

	if (strcmp(iter->data->name, name) == 0) {
		// increase count if after first insertion
		iter->data->count = iter->data->count + 1;
		return iter->data;
	} else {
		// insert if first
		nlist *next = (nlist *)malloc(sizeof(nlist));
		id *nextData = (id *)malloc(sizeof(id));
		char *nameToInsert = (char *)malloc(sizeof(length));
		strcpy(nameToInsert, name);
		// for KEYWORDs first insertion when initializing hash table
		if (tokenType != ID) nextData->count = 0;
		else nextData->count = 1;
		nextData->tokenType = tokenType;
		nextData->name = nameToInsert;
		next->data = nextData;
		next->next = NULL;
		iter->next = next;
		return nextData;
	}
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