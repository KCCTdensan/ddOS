TARGET = kernel.elf
OBJS = main.o asm.o asmfunc.o error.o \
       lib/string.o \
       graphics/graphics.o graphics/font.o graphics/fontascii.o graphics/console.o \
       memory/memory_map.o memory/segment.o memory/paging.o memory/manager.o \
       support/newlib_support.o support/libcxx_support.o #\
       timer.o interrupt.o \
       driver/pci.o \
       driver/usb/memory.o driver/usb/device.o driver/usb/xhci/ring.o driver/usb/xhci/trb.o \
       driver/usb/xhci/xhci.o driver/usb/xhci/port.o driver/usb/xhci/device.o driver/usb/xhci/devmgr.o \
       driver/usb/xhci/registers.o driver/usb/classdriver/base.o driver/usb/classdriver/hid.o \
       driver/usb/classdriver/keyboard.o driver/usb/classdriver/mouse.o driver/usb/classdriver/cdc.o
DEPENDS = $(join $(dir $(OBJS)),$(addprefix .,$(notdir $(OBJS:.o=.d))))

CPPFLAGS += -I.
CFLAGS   += -O2 -Wall -g --target=x86_64-elf -ffreestanding -mno-red-zone
CXXFLAGS += -O2 -Wall -g --target=x86_64-elf -ffreestanding -mno-red-zone \
            -fno-exceptions -fno-rtti -std=c++17
LDCFLAGS += -O2 -release -betterC \
            --extern-std=c++17
LDFLAGS  += --entry _main -z norelro --image-base 0x100000 --static


.PHONY: all
all: $(TARGET)

.PHONY: clean
clean:
	rm -rf *.o .*.d \
           */*.o */.*.d \
           */*/*.o */*/.*.d \
           */*/*/*.o */*/*/.*.d

kernel.elf: $(OBJS) Makefile
	ld.lld $(LDFLAGS) -o kernel.elf $(OBJS) -lc #-lc++ -lc++abi #-lm -lfreetype

%.o: %.d Makefile
	ldc2 $(LDCFLAGS) -c $< --of=$@

%.o: %.cpp Makefile
	clang++ $(CPPFLAGS) $(CXXFLAGS) -c $< -o $@

.%.d: %.cpp
	clang++ $(CPPFLAGS) $(CXXFLAGS) -MM $< > $@
	$(eval OBJ = $(<:.cpp=.o))
	sed --in-place 's|$(notdir $(OBJ))|$(OBJ)|' $@

%.o: %.c Makefile
	clang $(CPPFLAGS) $(CFLAGS) -c $< -o $@

.%.d: %.c
	clang $(CPPFLAGS) $(CFLAGS) -MM $< > $@
	$(eval OBJ = $(<:.c=.o))
	sed --in-place 's|$(notdir $(OBJ))|$(OBJ)|' $@

%.o: %.s Makefile
	nasm -f elf64 -o $@ $<

%.bin: %.bdf
	../assets/bdf2bin.py $< $@

%.o: %.bin
	objcopy -I binary -O elf64-x86-64 -B i386:x86-64 $< $@

.%.d: %.bin
	touch $@

.PHONY: depends
depends:
	$(MAKE) $(DEPENDS)

-include $(DEPENDS)
