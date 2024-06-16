%{
/**************************************************************
* File Name   : subc.l
*
* Description
*	This is a skeleton input file to lex.
*
* Which tool to use
*	The GNU lex-clone, flex/flex++ is recommended to use.
*	It supports a C++ mode.
*	For any information about flex, refer to flex.man.
*
*	Good Luck!
*
***************************************************************/

/**************************************************************/
/* This section will appear at the head of lex.yy.c/lex.yy.cc */
/**************************************************************/

#include "subc.h"
void initHash();
int add_id(char *name);
int commentdepth=0;
%}

letter				[A-Za-z_]
digit				[0-9]
white-space			[ \r\t\n]+
integer-constant	([1-9]+{digit}*)|0|([1-9]+{digit}*)
float-constant		{digit}+\.{digit}*([eE][\+\-]?{digit}+)?
identifier			{letter}({letter}|{digit})*
comment-start		\/\*
comment-end			\*\/
operator			"("|")"|"["|"]"|"{"|"}"|"->"|"."|","|".."|"!"|"~"|"++"|"--"|"*"|"/"|"%"|"+"|"-"|"<<"|">>"|"<"|"<="|">"|">="|"=="|"!="|"&"|"^"|"|"|"&&"|"||"|"?"|":"|";"|"="|"+="|"-="|"*="|"/="|"%="|"&="|"^="|"|="|"<<="|">>="

%start normal comment

%%
<normal>{white-space}				;
<normal>{identifier}				{ add_id(yytext); }
<normal>{operator}					{ printf("OP\t%s\n", yytext); }
<normal>{integer-constant}			{ printf("INT\t%s\n", yytext); }
<normal>{float-constant}/[^".."]	{ printf("F\t%s\n", yytext); }

<comment>{white-space}			;
<comment>{identifier}			;
<comment>{operator}				;
<comment>{integer-constant}		;
<comment>{float-constant}		;

<normal>{comment-start}		{ BEGIN comment; commentdepth++; }
<comment>{comment-start}	{ commentdepth++; }
<comment>{comment-end}		{ if(--commentdepth == 0) BEGIN normal; }

%%
void initHash() 
{
	int i;

	char* keyWord[]={
		"auto","break","case","char","continue","default","do","double",
		"else","extern","float","for","goto","if","int","long","register",
		"return","short", "sizeof","static","struct","switch","typedef","union",
		"unsigned","void","while","\0"
	};

	/* Initilize Hash Tabel with Keywords */
	for (i = 0; strcmp(keyWord[i], "\0") !=0; i++) {
		enter(KEYWORD, keyWord[i], strlen(keyWord[i]));
	}
}

/* add keyword or identifier to hash table and return token type */
int add_id(char *name) {
	id *data = enter(IDENTIFIER, name, strlen(name));

	// print KEYWORDS or IDENTIFIER
	switch(data->tokenType) {
		case KEYWORD: 
			printf("KEY\t%s\t%d\n", data->name, data->count);
			break;
		case IDENTIFIER:
			printf("ID\t%s\t%d\n", data->name, data->count);
			break;
	}

	return data->tokenType;
}

int main(int argc, char** argv)
{
	id* temp;

	++argv;
	--argc;

	if (argc > 0) {
		yyin = fopen(argv[0], "r");
	} else {
		yyin = stdin;
	}

	initHash();

	BEGIN normal;
	yylex ();

	/* for debugging */
	// print_hashtable();
	return 0;
}
