#include "sys_uart.h"

void sys_uart_init(void)
{
	u32_t addr;
	u32_t val;

	/* Config GPIOH0 and GPIOH1 to txd0 and rxd0 */
	addr = 0x0300b000 + 0xfc;
	val = read32(addr);
	val &= ~(0x07);
	val |= 0x02;
	write32(addr, val);

	val = read32(addr);
	val &= ~(7 << 4);
	val |= (2 << 4);
	write32(addr, val);

	/* Open the clock gate for uart0 */
	addr = 0x0300190c;
	val = read32(addr);
	val |= 1 << 0;
	write32(addr, val);

	/* Deassert uart0 reset */
	addr = 0x0300190c;
	val = read32(addr);
	val |= 1 << 16;
	write32(addr, val);

	/* Config uart0 to 115200-8-1-0 */
	addr = 0x05000000;
	write32(addr + 0x04, 0x0);
	write32(addr + 0x08, 0xf7);
	write32(addr + 0x10, 0x0);
	val = read32(addr + 0x0c);
	val |= (1 << 7);
	write32(addr + 0x0c, val);
	write32(addr + 0x00, 0xd & 0xff);
	write32(addr + 0x04, (0xd >> 8) & 0xff);
	val = read32(addr + 0x0c);
	val &= ~(1 << 7);
	write32(addr + 0x0c, val);
	val = read32(addr + 0x0c);
	val &= ~0x1f;
	val |= (0x3 << 0) | (0 << 2) | (0x0 << 3);
	write32(addr + 0x0c, val);
}

void sys_uart_putc(char c)
{
	u32_t addr = 0x05000000;

	while((read32(addr + 0x7c) & (0x1 << 1)) == 0);
	write32(addr + 0x00, c);
}

