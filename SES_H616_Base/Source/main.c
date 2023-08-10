/*********************************************************************
*                    SEGGER Microcontroller GmbH                     *
*                        The Embedded Experts                        *
**********************************************************************

-------------------------- END-OF-HEADER -----------------------------

File    : main.c
Purpose : Generic application start

*/

#include <stdio.h>
#include <stdlib.h>
#include "io.h"
#include "sys_uart.h"
#include "printk.h"
/*********************************************************************
*
*       main()
*
*  Function description
*   Application entry point.
*/
int main(void) {
    //write32(0x0300B04C, 0x77177777);
    //write32(0x0300B058, (1 << 13));
    
    //sys_uart_init();
    int text_arr2[16] = {0};
    int text_arr[10] = {1,2,3,4,5,6,7,8,9,10};
    //int text_arr1[1020] = {0};   


    text_arr2[0] = 1;

    printf("system start \r\n");
    
    while(1)
    {
        printf("JTAG-Mode\r\n");
    }
    
}

/*************************** End of file ****************************/
