#include "sys_i2c.h"

void sys_i2c_init(void)
{
	u32_t addr;
	u32_t val;

	/* Config GPIOL0 and GPIOL1 */
	addr = 0x07022000;
	val = read32(addr);
	val &= ~(0x07);
	val |= 0x03;
	write32(addr, val);

	val = read32(addr);
	val &= ~(7 << 4);
	val |= (3 << 4);
	write32(addr, val);

	/* Open the clock gate */
	addr = 0x0300191c;
	val = read32(addr);
	val |= 1 << 0;
	write32(addr, val);

	/* Deassert reset */
	addr = 0x0300191c;
	val = read32(addr);
	val |= 1 << 16;
	write32(addr, val);  

    /* set clock 400Khz 50% duty */
    addr = 0x05002000 + 0x14;
    val = (0 << 7) | (2 << 3) | (1 << 0);
    write32(addr, val);  

    /* enable twi */
    addr = 0x05002000 + 0x0c;
    write32(addr, (1 << 6));

    /* reset twi */
    addr = 0x05002000 + 0x18;
    write32(addr, (1 << 0));
    while(read32(addr) & (1 << 0));
}

enum {
	I2C_STAT_BUS_ERROR	= 0x00,
	I2C_STAT_TX_START	= 0x08,
	I2C_STAT_TX_RSTART	= 0x10,
	I2C_STAT_TX_AW_ACK	= 0x18,
	I2C_STAT_TX_AW_NAK	= 0x20,
	I2C_STAT_TXD_ACK	= 0x28,
	I2C_STAT_TXD_NAK	= 0x30,
	I2C_STAT_LOST_ARB	= 0x38,
	I2C_STAT_TX_AR_ACK	= 0x40,
	I2C_STAT_TX_AR_NAK	= 0x48,
	I2C_STAT_RXD_ACK	= 0x50,
	I2C_STAT_RXD_NAK	= 0x58,
	I2C_STAT_IDLE		= 0xf8,
};

static int sys_i2c_wait_status(void)
{
    int ret = 0;
    while(1)
    {
        if((read32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET) & (1 << 3)))
        {
            ret = read32(TWI0_ADDR_BASE + TWI_STAT_OFFSET);
            break;
        }
    }

    return ret;
}

static int sys_i2c_start(void)
{
	u32_t val;

	val = read32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET);
	val |= (1 << 5) | (1 << 3);
	write32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET, val);

    while(1)
    {
        if(!(read32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET) & (1 << 5)))
        {
            break;
        }
    }
    return sys_i2c_wait_status();
}

static int sys_i2c_stop(void)
{
    u32_t val;

	val = read32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET);
	val |= (1 << 4) | (1 << 3);
	write32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET, val);

    while(1)
    {
        if(!(read32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET) & (1 << 4)))
			break;
    }
    return sys_i2c_wait_status();
}

static int sys_i2c_send_data(u8_t dat)
{
	write32(TWI0_ADDR_BASE + TWI_DATA_OFFSET, dat);
	write32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET, read32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET) | (1 << 3));
	return sys_i2c_wait_status();
}

static int sys_i2c_write(u8_t addr, u8_t *data, int len)
{
	u8_t * p = data;

	if(sys_i2c_send_data(addr) != I2C_STAT_TX_AW_ACK)
		return -1;

	while(len > 0)
	{
		if(sys_i2c_send_data(*p++) != I2C_STAT_TXD_ACK)
        {
            return -1;
        }
			
		len--;
	}
	return 0;
}


static int sys_i2c_read(u8_t addr, u8_t *data, int len)
{
	u8_t * p = data;
    int ret = len;
    u8_t ss;

	if(sys_i2c_send_data(addr | 0x01) != I2C_STAT_TX_AR_ACK)
    {
        return -1;
    }
		
	write32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET, read32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET) | (1 << 2));
	while(len > 0)
	{
		if(len == 1)
		{
			write32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET, (read32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET) & ~(1 << 2)) | (1 << 3));
			if(sys_i2c_wait_status() != I2C_STAT_RXD_NAK)
            {
                return -1;
            }
		}
		else
		{
			write32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET, read32(TWI0_ADDR_BASE + TWI_CNTR_OFFSET) | (1 << 3));
			if(sys_i2c_wait_status() != I2C_STAT_RXD_ACK)
            {
                return -1;
            }
		}
        ss = read32(TWI0_ADDR_BASE + TWI_DATA_OFFSET);
		*p++ = ss;
		len--;
	}
	return ret;
}


int sys_i2c_mst_write(u8_t addr, u8_t *data, int len)
{
    if(sys_i2c_start() != I2C_STAT_TX_START)
    {
        return -1;
    }

    sys_i2c_write(addr, data, len);

    sys_i2c_stop();

    return 0;
}

int sys_i2c_mst_read(u8_t addr, u8_t *data, int len)
{
    if(sys_i2c_start() != I2C_STAT_TX_START)
    {
        return -1;
    }

    sys_i2c_read(addr, data, len);

    sys_i2c_stop();

    return 0;
}


