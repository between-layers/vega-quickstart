APPS := $(patsubst apps/%/Makefile,%,$(wildcard apps/*/Makefile))

.PHONY: all list clean $(APPS) $(addprefix flash-,$(APPS))

all: $(APPS)

$(APPS):
	$(MAKE) -C apps/$@

$(addprefix flash-,$(APPS)):
	$(MAKE) -C apps/$(patsubst flash-%,%,$@) flash

list:
	@echo $(APPS)

SERIAL_DEV ?= $(firstword $(wildcard /dev/ttyACM* /dev/ttyUSB* /dev/cu.usbmodem*))

serial:
	@[ -n "$(SERIAL_DEV)" ] || { echo "No serial device found"; exit 1; }
	sudo minicom -D $(SERIAL_DEV) -b 115200

clean:
	rm -rf build
