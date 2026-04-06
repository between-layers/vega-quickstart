# Baremetal build for RV32M1-VEGA RI5CY core
# Requires: riscv32-unknown-elf-gcc toolchain, OpenOCD with RV32M1 support
APP_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
APP_NAME := $(notdir $(patsubst %/,%,$(dir $(APP_DIR))))
WORKSPACE_ROOT := $(APP_DIR)../../

# Toolchain
CROSS_COMPILE ?= riscv32-unknown-elf-
CC      = $(CROSS_COMPILE)gcc
AS      = $(CROSS_COMPILE)gcc
OBJCOPY = $(CROSS_COMPILE)objcopy
SIZE    = $(CROSS_COMPILE)size

# Directories (relative to this Makefile)
SDK_ROOT    ?= $(WORKSPACE_ROOT)rv32m1-sdk/
DEVICE_DIR  = $(SDK_ROOT)devices/RV32M1/
DRIVER_DIR  = $(DEVICE_DIR)drivers/
UTIL_DIR    = $(DEVICE_DIR)utilities/
BOARD_DIR   = $(SDK_ROOT)boards/rv32m1_vega/
BUILD_DIR   = $(WORKSPACE_ROOT)build/$(APP_NAME)/

# Linker script
LDSCRIPT = $(BOARD_DIR)driver_examples/gpio/led_output/ri5cy/riscvgcc/RV32M1_ri5cy_flash.ld

# OpenOCD
OPENOCD     ?= openocd
OPENOCD_CFG  = $(WORKSPACE_ROOT)support/openocd_rv32m1_vega_ri5cy.cfg

# Target
TARGET = $(BUILD_DIR)$(APP_NAME)

# Application sources
APP_SRCS = \
	main.c \
	board.c

# SDK sources
SDK_SRCS = \
	$(DEVICE_DIR)system_RV32M1_ri5cy.c \
	$(DRIVER_DIR)fsl_common.c \
	$(DRIVER_DIR)fsl_gpio.c \
	$(DRIVER_DIR)fsl_clock.c \
	$(DRIVER_DIR)fsl_msmc.c \
	$(DRIVER_DIR)fsl_lpuart.c \
	$(UTIL_DIR)fsl_debug_console.c \
	$(UTIL_DIR)fsl_io.c \
	$(UTIL_DIR)fsl_log.c \
	$(UTIL_DIR)fsl_str.c

# Startup assembly
ASM_SRCS = $(DEVICE_DIR)gcc/startup_RV32M1_ri5cy.S

# All sources
C_SRCS = $(APP_SRCS) $(SDK_SRCS)

# Object files (all go into BUILD_DIR with flat names)
C_OBJS   = $(addprefix $(BUILD_DIR), $(notdir $(C_SRCS:.c=.o)))
ASM_OBJS = $(addprefix $(BUILD_DIR), $(notdir $(ASM_SRCS:.S=.o)))
OBJS     = $(C_OBJS) $(ASM_OBJS)

# Tell make where to find sources
VPATH = . $(dir $(SDK_SRCS)) $(dir $(ASM_SRCS))

# Include paths
INCLUDES = \
	-I$(APP_DIR) \
	-I$(DEVICE_DIR) \
	-I$(DRIVER_DIR) \
	-I$(UTIL_DIR) \
	-I$(SDK_ROOT)RISCV \
	-I$(SDK_ROOT)devices

# Defines
DEFINES = \
	-DCPU_RV32M1_ri5cy \
	-D__STARTUP_CLEAR_BSS

# Architecture flags
ARCH_FLAGS = -march=rv32imcxpulpv2

# C flags
CFLAGS = $(ARCH_FLAGS) $(DEFINES) $(INCLUDES) \
	-g -O0 \
	-Wall \
	-fno-common \
	-ffunction-sections \
	-fdata-sections \
	-ffreestanding \
	-fno-builtin \
	-std=gnu99 \
	-MMD -MP

# Assembly flags
ASFLAGS = $(ARCH_FLAGS) $(DEFINES) \
	-g \
	-Wall \
	-fno-common \
	-ffunction-sections \
	-fdata-sections \
	-ffreestanding \
	-fno-builtin

# Linker flags
LDFLAGS = $(ARCH_FLAGS) \
	-T$(LDSCRIPT) \
	-ffreestanding \
	-fno-builtin \
	-nostdlib \
	-Xlinker --gc-sections \
	-Xlinker -static \
	-Xlinker -z -Xlinker muldefs

LDLIBS = -Wl,--start-group -lm -lc -lgcc -lnosys -Wl,--end-group

# Rules
.PHONY: all clean flash t

all: $(TARGET).elf $(TARGET).bin $(TARGET).hex
	@$(SIZE) $(TARGET).elf

t:
	@echo APP_DIR $(APP_DIR)
	@echo APP_NAME $(APP_NAME)
	@echo ROOT $(WORKSPACE_ROOT)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)%.o: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)%.o: %.S | $(BUILD_DIR)
	$(AS) $(ASFLAGS) -c -o $@ $<

$(TARGET).elf: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $^ $(LDLIBS)

$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex $< $@

flash: $(TARGET).elf
	$(OPENOCD) -f $(OPENOCD_CFG) \
		-c "init" \
		-c "halt" \
		-c "ri5cy_boot" \
		-c "flash write_image erase $(TARGET).elf" \
		-c "reset run" \
		-c "exit"

clean:
	rm -rf $(BUILD_DIR)

# Include generated dependency files
-include $(C_OBJS:.o=.d)
