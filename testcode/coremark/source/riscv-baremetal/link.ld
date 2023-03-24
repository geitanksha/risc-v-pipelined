OUTPUT_ARCH( "riscv" )
ENTRY(_start)

_text_start = 0x80000000;
_stack_top  = 0xC0000000;

SECTIONS
{

  . = _text_start;

  .text.swinit1 : 
  { 
    . = ALIGN(4);
    *(.text.swinit1)
  }

  . = .;

  .text.swfin : 
  { 
    . = ALIGN(4);
    *(.text.swfin)
  }

  . = .;

  .tohost : 
  {
    . = ALIGN(8);
    *(.tohost)
  }

  . = .;

  .fromhost : 
  {
    . = ALIGN(8);
    *(.fromhost)
  }

  . = .;

  .text : 
  {
    . = ALIGN(4);
    _text_vma_start = .;
    
    *(.text)
    *(.text*)

    . = ALIGN(4);
    _text_vma_end = .;
  }

  . = .;

  .data : 
  {
    . = ALIGN(4);
    _data_vma_start = .;

    *(.*data*)

    . = ALIGN(4);
    _data_vma_end = .;
  }

  . = .;

  .bss : 
  {
    . = ALIGN(4);
    _bss_vma_start = .;

    *(.*bss*)

    . = ALIGN(4);
    _bss_vma_end = .;
  }

  _end = .;

  /DISCARD/ :
  {
    *(.eh_frame)
    *(.riscv.attributes)
    *(.comment)
    *(.debug*)
  }
}
