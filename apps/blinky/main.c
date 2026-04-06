#include "board.h"
#include "fsl_debug_console.h"
#include "fsl_gpio.h"

static void delay(void)
{
    volatile uint32_t i;
    for (i = 0; i < 800000; ++i)
        __asm("NOP");
}

int main(void)
{
    gpio_pin_config_t led_config = {
        kGPIO_DigitalOutput, 0,
    };

    BOARD_InitPins();
    BOARD_BootClockRUN();
    BOARD_InitDebugConsole();

    PRINTF("\r\nRV32M1-VEGA RI5CY baremetal app\r\n");
    PRINTF("LED is blinking.\r\n");

    GPIO_PinInit(BOARD_LED_GPIO, BOARD_LED_GPIO_PIN, &led_config);

    while (1) {
        delay();
        GPIO_TogglePinsOutput(BOARD_LED_GPIO, 1u << BOARD_LED_GPIO_PIN);
    }
}
