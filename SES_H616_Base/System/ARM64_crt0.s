// **********************************************************************
// *                    SEGGER Microcontroller GmbH                     *
// *                        The Embedded Experts                        *
// **********************************************************************
// *                                                                    *
// *            (c) 2014 - 2023 SEGGER Microcontroller GmbH             *
// *            (c) 2001 - 2023 Rowley Associates Limited               *
// *                                                                    *
// *           www.segger.com     Support: support@segger.com           *
// *                                                                    *
// **********************************************************************
// *                                                                    *
// * All rights reserved.                                               *
// *                                                                    *
// * Redistribution and use in source and binary forms, with or         *
// * without modification, are permitted provided that the following    *
// * condition is met:                                                  *
// *                                                                    *
// * - Redistributions of source code must retain the above copyright   *
// *   notice, this condition and the following disclaimer.             *
// *                                                                    *
// * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND             *
// * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,        *
// * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF           *
// * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE           *
// * DISCLAIMED. IN NO EVENT SHALL SEGGER Microcontroller BE LIABLE FOR *
// * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR           *
// * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT  *
// * OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;    *
// * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF      *
// * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT          *
// * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE  *
// * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH   *
// * DAMAGE.                                                            *
// *                                                                    *
// **********************************************************************
//
//
//                           Preprocessor Definitions
//                           ------------------------
// APP_ENTRY_POINT
//
//   Defines the application entry point function, if undefined this setting
//   defaults to "main".
//
// INITIALIZE_STACKS
//
//   If defined, the contents of the stacks will be initialized to a the 
//   value 0xCC.
//
// INITIALIZE_SECONDARY_SECTIONS
//
//   If defined, the .text2, .data2 and .bss2 sections will be initialized.
//
// INITIALIZE_USER_SECTIONS
//
//   If defined, the function InitializeUserMemorySections will be called prior
//   to entering main in order to allow the user to initialize any user defined
//   memory sections.
//
// SUPERVISOR_START
//
//   If defined, the application will start up in supervisor mode. If 
//   undefined the application will start up in system mode.
//
// FULL_LIBRARY
//
//  If defined then 
//    - argc, argv are setup by the SEGGER_SEMIHOST_GetArgs.
//    - the exit symbol is defined and executes on return from main.
//    - the exit symbol calls destructors, atexit functions and then SEGGER_SEMIHOST_Exit.
//  
//  If not defined then
//    - argc and argv are zero.
//    - the exit symbol is defined, executes on return from main and loops
//

  .section .init, "ax"
  .balign 4

#ifndef APP_ENTRY_POINT
#define APP_ENTRY_POINT main
#endif

#ifndef ARGSSPACE
#define ARGSSPACE 128
#endif
                
  .weak _start
  .global __start  
  .extern APP_ENTRY_POINT
  .weak exit

#ifdef INITIALIZE_USER_SECTIONS
  .extern InitializeUserMemorySections
#endif

/*****************************************************************************
 * Function    : _start                                                      *
 * Description : Main entry point and startup code for C system.             *
 *****************************************************************************/
_start:
__start:
  
  ldr x5, =__stack_end__
  mov sp, x5

  ldr x5, =__tbss_start__-0x10
  msr tpidr_el0, x5

#ifdef INITIALIZE_STACKS  
  mov r2, #0xCC 
  ldr x0, =__stack_start__
  ldr x1, =__stack_end__
  bl memory_set  
#endif

  /* Copy initialized memory sections into RAM (if necessary). */
  ldr x0, =__data_load_start__
  ldr x1, =__data_start__
  ldr x2, =__data_end__
  bl memory_copy
  ldr x0, =__text_load_start__
  ldr x1, =__text_start__
  ldr x2, =__text_end__
  bl memory_copy
  ldr x0, =__fast_load_start__
  ldr x1, =__fast_start__
  ldr x2, =__fast_end__
  bl memory_copy
  ldr x0, =__ctors_load_start__
  ldr x1, =__ctors_start__
  ldr x2, =__ctors_end__
  bl memory_copy
  ldr x0, =__dtors_load_start__
  ldr x1, =__dtors_start__
  ldr x2, =__dtors_end__
  bl memory_copy
  ldr x0, =__rodata_load_start__
  ldr x1, =__rodata_start__
  ldr x2, =__rodata_end__
  bl memory_copy
  ldr x0, =__tdata_load_start__
  ldr x1, =__tdata_start__
  ldr x2, =__tdata_end__
  bl memory_copy
#ifdef INITIALIZE_SECONDARY_SECTIONS
  ldr x0, =__data2_load_start__
  ldr x1, =__data2_start__
  ldr x2, =__data2_end__
  bl memory_copy
  ldr x0, =__text2_load_start__
  ldr x1, =__text2_start__
  ldr x2, =__text2_end__
  bl memory_copy
  ldr x0, =__rodata2_load_start__
  ldr x1, =__rodata2_start__
  ldr x2, =__rodata2_end__
  bl memory_copy
#endif /* #ifdef INITIALIZE_SECONDARY_SECTIONS */
  
  /* Zero the bss. */
  ldr x0, =__bss_start__
  ldr x1, =__bss_end__
  mov x2, #0
  bl memory_set
  ldr x0, =__tbss_start__
  ldr x1, =__tbss_end__
  mov x2, #0
  bl memory_set
#ifdef INITIALIZE_SECONDARY_SECTIONS
  ldr x0, =__bss2_start__
  ldr x1, =__bss2_end__
  mov x2, #0
  bl memory_set
#endif /* #ifdef INITIALIZE_SECONDARY_SECTIONS */

#if !defined(__HEAP_SIZE__) || (__HEAP_SIZE__)
  /* Initialize the heap */
  ldr x0, = __heap_start__
  ldr x1, = __heap_end__
  sub x1, x1, x0
#if defined(__SES_ARM)
  bl __SEGGER_RTL_init_heap
#else
  cmp r1, #8
  movge r2, #0
  strge r2, [r0], #+4
  strge r1, [r0]
#endif
#endif

#ifdef INITIALIZE_USER_SECTIONS
  ldr r2, =InitializeUserMemorySections
  mov lr, pc
#ifdef __ARM_ARCH_3__
  mov pc, r2
#else
  bx r2
#endif
#endif

  .type start, function
start:

  /* Call constructors */
  ldr x0, =__ctors_start__
  ldr x1, =__ctors_end__
ctor_loop:
  cmp x0, x1
  beq ctor_end
  ldr x2, [x0], #+8
  stp x0, x1, [sp, #0x0]! 
  blr x2
  ldp x0, x1, [sp, #0x0]!
  b ctor_loop
ctor_end:

  .type __startup_complete, function
__startup_complete:

  /* Jump to application entry point */
#ifdef FULL_LIBRARY
  mov x0, #ARGSSPACE
  ldr x1, =args
  ldr x2, =SEGGER_SEMIHOST_GetArgs
  blr x2
  ldr x1, =args
#else
  mov x0, #0
  mov x1, #0
#endif
  ldr x2, =APP_ENTRY_POINT
  blr x2

  .type exit, function
exit:
#ifdef FULL_LIBRARY  
  mov x19, x0 // save the exit parameter/return result
  
  /* Call destructors */
  ldr x0, =__dtors_start__
  ldr x1, =__dtors_end__
dtor_loop:
  cmp x0, x1
  beq dtor_end
  ldr x2, [x0], #+8
  stp x0, x1, [sp, #0x0]!
  //stmfd sp!, {r0-r1}
  blr x2
  ldp x0, x1, [sp, #0x0]! 
  b dtor_loop
dtor_end:

  /* Call atexit functions */
  ldr x2, =__SEGGER_RTL_execute_at_exit_fns 
  blr x2

  /* Call SEGGER_SEMIHOST_Exit with return result/exit parameter */
  mov x0, x19
  ldr x2, =SEGGER_SEMIHOST_Exit 
  blr x2
#endif

  /* Returned from application entry point/SEGGER_SEMIHOST_Exit, loop forever. */
exit_loop:
  b exit_loop

memory_copy:
  cmp w0,w1
  beq 2f
  subs w2,w2, w1
  beq 2f
1:
  ldr w3, [x0]
  adds w0, w0, #4
  str w3, [x1]
  adds w1, w1, #4
  subs w2, w2, #4
  bne 1b
2:
  ret

memory_set:
  cmp w0,w1
  beq 2f
  subs w2,w2, w1
  beq 2f
1:
  str wzr, [x0]
  adds w0, w0, #4
  cmp w0,w1
  bne 1b
2:
  ret

  // default C/C++ library helpers

.macro HELPER helper_name
  .section .text.\helper_name, "ax", %progbits
  .balign 4
  .type \helper_name, function
  .weak \helper_name  
\helper_name:  
.endm

HELPER abort
#ifdef FULL_LIBRARY
  mov x0, #1
  ldr x2, =SEGGER_SEMIHOST_Exit 
  blr x2
#endif
  b .
HELPER __assert
  b .
HELPER __assert_func
  b .
HELPER __sync_synchronize
  ret

#ifdef FULL_LIBRARY
  .bss
args:
  .space ARGSSPACE
#endif

  /* Setup attibutes of stack and heap sections so they don't take up unnecessary room in the elf file */
  .section .stack, "wa", %nobits 
  .section .heap, "wa", %nobits
