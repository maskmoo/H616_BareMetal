
#ifndef _SYS_I2C_H
#define _SYS_I2C_H

#include "io.h"

#define TWI0_ADDR_BASE      (0x05002000)

#define TWI_ADDR_OFFSET     (0x0000)
#define TWI_XADDR_OFFSET    (0x0004)
#define TWI_DATA_OFFSET     (0x0008)
#define TWI_CNTR_OFFSET     (0x000c)
#define TWI_STAT_OFFSET     (0x0010)
#define TWI_CCR_OFFSET      (0x0014)
#define TWI_SRST_OFFSET     (0x0018)
#define TWI_EFR_OFFSET      (0x001c)
#define TWI_LCR_OFFSET      (0x0020)


void sys_i2c_init(void);
int sys_i2c_mst_write(u8_t addr, u8_t *data, int len);
int sys_i2c_mst_read(u8_t addr, u8_t *data, int len);

#endif