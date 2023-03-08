%{
 #define _POSIX_SOURCE		1
 #define _POSIX_C_SOURCE	1
#include <stdio.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>
#include <malloc.h>
#include "ld-sectors_yy.h"
extern int fileno(FILE *stream);
 
char* maketoken(const char* data, int len);
char* makestring(const char* data, int len, int s);
//printf("Unknown Token = '%s' , 0x%02x\n", yytext, yytext[0]); yyterminate();

#define SAVE_TOKEN     yylval.str = maketoken(yytext, yyleng)
#define SAVE_INT       yylval.value = atoi(yytext)
#define SAVE_STRING    yylval.str = makestring(yytext, yyleng, 2)

%}

%option noyywrap

%%
"flash"                   		        return FLASH;
"FLASH"                   		        return FLASH;
"sector"				                      return SECTOR;
"SECTOR"				                      return SECTOR;
[bB][yY][tT][eE][sS]                  return BYTES;
[kK][bB]  		                        return KBYTES;
[mM][bB]			                        return MBYTES;
[\{]					                        return L_BRACE;
[\}]				                          return R_BRACE;
[\;]					                        return SEMICOLON;
[0-9]+                    SAVE_INT;  	return NUMBER;
0x[0-9A-Fa-f]+            SAVE_INT;  	return NUMBER;
[a-zA-Z_][a-zA-Z0-9_\.]*  SAVE_TOKEN;	return NAME;
\"(\\.|[^\\"])*\"         SAVE_STRING;	return STRING;
[[:space:]]+              /* No action */
%%

char* maketoken(const char* data, int len) {
    char* str = (char*) malloc(len+1);
    strncpy(str, data, len);
    str[len] = 0;
    return str;
}

char* makestring(const char* data, int len, int s) {
    char* str = (char*) malloc(len-s+1);
    strncpy(str, data+s-1, len-s);
    str[len-s] = 0;
    if (s == 3) return str;
    return str;
}

// int yywrap(){}
