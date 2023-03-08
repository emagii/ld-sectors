# ld-sectors
Support for flash sector alignment when using the GNU linker (ld-bfd)

This utility takes an infile called XXX.dat describing the sector
and bank arrangement of the internal flash memory of a microcontroller
and generates include files that can be used in the GNU ld-bfd linker
to extend the current location to the end of the current flash sector.

The utility takes a single parameter for the infile

Example:

	ld-sectors XXX

The utility reads "XXX.dat" and generates two files.

* "XXX_sectors.inc"
* "XXX_align.inc"

The format of the ".dat" file is one or more 'bank's.

	bank:   'FLASH' NAME '{'
			sector_definition*
		'}' ';'
	
	sector_definition:  'SECTOR' SIZE MULTIPLIER ';'
	
	multiplier:    'kB' | 'MB' | 'BYTES'

The 'NAME' is the name of the flash bank and it is used as a prefix
when generating other symbols.

====================
Example:

	FLASH bank0 {
	  sector  16 kB;
	  sector  16 kB;
	  sector  32 kB;
	};
	
	FLASH bank1 {
	  sector  64 kB;
	  sector  64 kB;
	  sector  64 kB;
	};

====================

The "XXX_sectors.inc" file describe the flash sections.

Each sector with a "begin", an "end" and a "size" symbol wwith 

Example:

	"bank0#00#start"                = 0x00000000;
	"bank0#00#end"                  = 0x00003fff;
	"bank0#00#size"                 = 0x00004000;

====================

The "XXX_align.inc" file is used to align
to the end of the current sector.

For each sector, it checks if the location is inside that sector,
and if it is, the location counter is aligned with the sector size.
Otherwise the location counter remains as it is.

Since the sectors do not overlap, only one rule will be triggered.

Example:

	. = ((. >= "bank0#00#start")  && (. <= "bank0#00#end"))   ?
		ALIGN("bank0#00#size")   :
		.;

The '.'	is the location.

If '.' is between "start" and "end" (inside the sector), then
the 'aligned' value is assigned to the location counter.

If it is not inside the sector, the statement is simplified to ". = .;"
That is, the location counter is assigned the current value of the
location counter, so the value does not change.

The linker script command file (typically ldscript) must
contains INCLUDE statements to include both files.

The symbols contain the "illegal" character '#' which normally
is not accepted as a part of a symbol name, but since we
enclose in hyphens ('"'), this works.
