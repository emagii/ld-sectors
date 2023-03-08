/* calculator. */
%{
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdbool.h>
#include <string.h>
#include <stdint.h>
#include "ld-sectors_yy.h"

extern int yylex();
extern int yylineno;
extern char* yytext;
extern int yyleng;
extern FILE *yyin;
void yyerror(const char *s);

#define MAX_SECTOR 256
#define MAX_NAME	 32
void yyerror(const char *msg);

 // Here is an example how to create custom data structure
typedef struct {
	char*	 name;
	uint64_t start;
	uint64_t end;
	uint64_t size;
} sector_t;

typedef struct {
	char *name;
	uint32_t from;
	uint32_t to;
} bank_t;

static
void do_sectors(bank_t *bank,sector_t *s, uint32_t from, uint32_t to);
static
void do_alignment(bank_t *bank,sector_t *s, uint32_t from, uint32_t to);

sector_t flash[MAX_SECTOR];
sector_t *sector = &flash[0];

bank_t bank[4];


uint32_t flash_ix    = 0;
uint32_t bank_ix    = 0;
uint64_t location = 0;

const char *app;
char *sector_data;
char *sectors;
char *sector_align;
FILE *sect_file;
FILE *align_file;

%}

%union{
  uint64_t value;
  char* str;
  struct custom_data* cval; // define the pointer type for custom data structure
}

%define parse.error verbose

%locations
%token FLASH
%token 						SECTOR
%token <str> 			BYTES;
%token <str> 			KBYTES;
%token <str> 			MBYTES;
%token L_BRACE R_BRACE SEMICOLON
%token <str> 			NAME
%token <value> NUMBER
%token <str>			STRING
%type  <value>    sector
%type  <value>    size

%start input
%% 

input:	statement_list

statement_list
		: statement
		| statement_list statement
		;

statement
		:	FLASH NAME {
			  bank[bank_ix].name = $2;
			  bank[bank_ix].from = flash_ix;
      }	L_BRACE sector_list R_BRACE SEMICOLON {
			  bank[bank_ix].to   = flash_ix - 1;
				if (strlen($2) < MAX_NAME)
				  {
						do_sectors  (&bank[bank_ix], &flash[0], bank[bank_ix].from, bank[bank_ix].to);
						do_alignment(&bank[bank_ix], &flash[0], bank[bank_ix].from, bank[bank_ix].to);
				  }
			  else
			  	{
				  	fprintf(stderr, "flash bank name too long \"%s\"\n", bank->name); 
					}
				bank_ix++;
			}
		;

sector_list
    : sector SEMICOLON
    | sector_list  sector SEMICOLON
    ;

sector:	SECTOR NUMBER size	{
				if (flash_ix < MAX_SECTOR)
				  {
						sector				 = &flash[flash_ix++];
						sector->name  = bank[bank_ix].name;
						sector->start = location;
						sector->size  = $2*$3;
						location       = sector->start + sector->size;
						sector->end   = location - 1;
					}
				else
					{
						fprintf(stderr, "Number of sectors exceeded\n");
					}
			}
			;

size: BYTES				{ $$ = 1; }
		| KBYTES			{ $$ = 1024; }
		| MBYTES			{ $$ = 1024 * 1024; }
		;

%%

/* This filter will try to use ';' instead '\n' as the next token.
 * If the transition works without error, we will issue a ';' token,
 * Othervise we will ignore '\n' and produce the next token
 */
#if	0
int yyfilter(int yychar, int yyn, int yystate, yy_state_t *yyssp) {
    if ((yychar == '\n') || (yychar == ' ')) {
   		printf("Skipping...\n");
      do {
      	yychar = yylex();
    	} while (yychar == '\n'); 
      return yychar;
    }
    return yychar;
}
#endif
static
void do_sectors(bank_t *bank,sector_t *s, uint32_t from, uint32_t to)
{
	char label[MAX_NAME+32];
  for (int i = from ; i <= to ; i++)
    {
			sprintf(label, 		 "\"%s#%02d#start\"",   bank->name, i);
      fprintf(sect_file, "\t%-32s= 0x%08lx;\n", label, s[i].start);
			sprintf(label, 		 "\"%s#%02d#end\"",		  bank->name, i);
      fprintf(sect_file, "\t%-32s= 0x%08lx;\n", label, s[i].end);
			sprintf(label, 		 "\"%s#%02d#size\"",		bank->name, i);
      fprintf(sect_file, "\t%-32s= 0x%08lx;\n", label, s[i].size);
      fprintf(sect_file, "\n");
    }
}

static
void do_alignment(bank_t *bank,sector_t *s, uint32_t from, uint32_t to)
{
	char comp[MAX_NAME+32];
	
  for (int i = from ; i <= to ; i++)
    {
      fprintf(align_file, "\t. = (");
			sprintf(comp, "(. >= \"%s#%02d#start\")", bank->name, i);
      fprintf(align_file, "%-24s", comp);
      fprintf(align_file, " && ");
			sprintf(comp, "(. <= \"%s#%02d#end\"))", bank->name, i);
      fprintf(align_file, "%-24s ? ", comp);
			sprintf(comp, "ALIGN(\"%s#%02d#size\")", bank->name, i);
      fprintf(align_file, "%-24s", comp);
      fprintf(align_file, " : .;\n");
    }
}

const char *help[] = {
	"The program will read in '<chipname>.dat' and create",
	"* '<chipname>_sectors.inc'",
	"* '<chipname>_align.inc'",
	"which can be 'included' in the linker command file",
	NULL
};

static
void usage(void)
{
 	printf("Usage:\n");
 	printf("%s: <chipname>\n", app);
 	for(int i = 0 ; help[i] != NULL ; i++)
   	{
   		printf("\t%s\n", help[i]);
   	}
}

char *concat(const char *fname, const char *ext)
{
	char *s = malloc(strlen(fname) + strlen(ext) + 1);
	if (s == NULL)
		return NULL;
	sprintf(s, "%s%s", fname, ext);
  return s;
}

int main(int argc, char **argv)
{
  uint32_t status;
	extern int yydebug;
//   yydebug = 1;
	app = argv[0];
	if (argc > 1)
  	{
  		sector_data  = concat(argv[1], ".dat");
  		sectors      = concat(argv[1], "_sectors.inc");
  		sector_align = concat(argv[1], "_align.inc");
  		
      yyin = fopen(sector_data, "r");
      if (yyin == NULL)
      	{
					usage();
					return 1;
      	}

      sect_file  = fopen(sectors, "w");
			if (sect_file == NULL)
			  {
			  	usage();
					status = 1;
					goto e1;
			  }

			align_file = fopen(sector_align, "w");
			if (align_file == NULL)
			  {
			  	usage();
					status = 1;
					goto e2;
			  }

	   	yyparse();			
   	}
  else
  	{
			usage();
			return 1;
		}
e3:
	fclose(align_file);
e2:
	fclose(sect_file);
e1:
	fclose(yyin);
e0:
	free(sector_data);
	free(sectors);
	free(sector_align);
	return status;
}

void yyerror(const char *msg) {
   printf("** Line %d: %s\n", yylloc.first_line, msg);
}
