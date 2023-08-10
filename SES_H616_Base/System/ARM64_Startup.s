/*********************************************************************
*                    SEGGER Microcontroller GmbH                     *
*                        The Embedded Experts                        *
**********************************************************************
*                                                                    *
*            (c) 2014 - 2023 SEGGER Microcontroller GmbH             *
*                                                                    *
*       www.segger.com     Support: support@segger.com               *
*                                                                    *
**********************************************************************
*                                                                    *
* All rights reserved.                                               *
*                                                                    *
* Redistribution and use in source and binary forms, with or         *
* without modification, are permitted provided that the following    *
* condition is met:                                                  *
*                                                                    *
* - Redistributions of source code must retain the above copyright   *
*   notice, this condition and the following disclaimer.             *
*                                                                    *
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND             *
* CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,        *
* INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF           *
* MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE           *
* DISCLAIMED. IN NO EVENT SHALL SEGGER Microcontroller BE LIABLE FOR *
* ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR           *
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT  *
* OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;    *
* OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF      *
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT          *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE  *
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH   *
* DAMAGE.                                                            *
*                                                                    *
**********************************************************************

-------------------------- END-OF-HEADER -----------------------------

File      : ARM64_Startup.s
Purpose   : Generic startup and exception handlers for ARM64 devices.

*/
        
/*********************************************************************
*
*       Macros
*
**********************************************************************
*/

//
// Mark the end of a function and calculate its size
//
.macro END_FUNC name
        .size \name,.-\name
.endm

/*********************************************************************
*
*       Global data
*
**********************************************************************
*/

/*********************************************************************
*
*       Global functions
*
**********************************************************************
*/

/*********************************************************************
*
*       Reset_Handler
*
*  Function description
*    Exception handler for reset.
*    Generic bringup of a system.
*/

  .arch armv8-a

  .global Debug_Start_Here
  .global Reset_Handler
  .global reset_handler
  .type Reset_Handler, function
  .equ reset_handler, Reset_Handler
  .section .init, "ax"

Reset_Handler:

  mrs     x1, mpidr_el1
  and     x1, x1, #3
  cbz     x1, 1f    
2:
  wfi
  b       2b
1: 
#if 0
  b .

Debug_Start_Here:
#endif
  // Move to EL1 if at EL2
  mrs x5, CurrentEL
  cmp x5, #(2<<2)
  bne 3f

  ldr x5, =__stack_el1_end__
  msr sp_el1, x5

  mrs x0, HCR_EL2
  orr x0, x0, #(1<<31) // RW
  msr HCR_EL2, x0
  mov x0, #4 // EL1t
  msr SPSR_EL2, x0
  adr x6, 3f
  msr ELR_EL2, x6
  eret
3:

  adr x0, _vectors
  msr vbar_el1, x0

  mov x0, #(0x3 << 20) // FPEN disables trapping to EL1.
  msr cpacr_el1, x0

  b _start
END_FUNC Reset_Handler

.weak synchronousExceptionHandler
.weak irqExceptionHandler

.section .init, "ax"
  .balign 0x800
  .global _vectors
_vectors:
current_el_sp0_sync:
  stp x0, x1, [sp, #-16]!
  stp x2, x3, [sp, #-16]!
  stp x4, x5, [sp, #-16]!
  stp x6, x7, [sp, #-16]!
  stp x8, x9, [sp, #-16]!
  stp x10, x11, [sp, #-16]!
  stp x12, x13, [sp, #-16]!
  stp x14, x15, [sp, #-16]!
  mrs x0, ELR_EL1
  mrs x1, ESR_EL1
  bl synchronousExceptionHandler
  msr ELR_EL1, x0
  ldp x14, x15, [sp], #16
  ldp x12, x13, [sp], #16
  ldp x10, x11, [sp], #16
  ldp x8, x9, [sp], #16
  ldp x6, x7, [sp], #16
  ldp x4, x5, [sp], #16
  ldp x2, x3, [sp], #16
  ldp x0, x1, [sp], #16
  eret
  .balign 0x80
current_el_sp0_irq:
  stp x0, x1, [sp, #-16]!
  stp x2, x3, [sp, #-16]!
  stp x4, x5, [sp, #-16]!
  stp x6, x7, [sp, #-16]!
  stp x8, x9, [sp, #-16]!
  stp x10, x11, [sp, #-16]!
  stp x12, x13, [sp, #-16]!
  stp x14, x15, [sp, #-16]!
  mrs x0, ELR_EL1
  mrs x1, ESR_EL1  
  bl irqExceptionHandler
  msr ELR_EL1, x0
  ldp x14, x15, [sp], #16
  ldp x12, x13, [sp], #16
  ldp x10, x11, [sp], #16
  ldp x8, x9, [sp], #16
  ldp x6, x7, [sp], #16
  ldp x4, x5, [sp], #16
  ldp x2, x3, [sp], #16
  ldp x0, x1, [sp], #16
  eret
  .balign 0x80
current_el_sp0_fiq:
  b .
  .balign 0x80
current_el_sp0_serror:
  b .
  .balign 0x80
current_el_spx_sync:
  mrs x0, ESR_EL1
  mrs x1, FAR_EL1
  b .
  .balign 0x80
current_el_spx_irq:
  b .
  .balign 0x80
current_el_spx_fiq:
  b .
  .balign 0x80
current_el_spx_serror:
  b .

/*************************** End of file ****************************/
