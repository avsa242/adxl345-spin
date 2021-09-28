# P1, P2 device nodes and baudrates
#P1DEV=
P1BAUD=115200
#P2DEV=
P2BAUD=2000000

# ADXL345 interface: I2C, SPI-3wire or SPI-4wire
IFACE=ADXL345_I2C
#IFACE=ADXL345_SPI3W
#IFACE=ADXL345_SPI4W

default:
	@echo "Available make targets:"
	@echo "p1: build P1 demo (bytecode)"
	@echo "p2: build P2 demo (native code)"
	@echo "loadp1: load P1 binary to board set by P1DEV"
	@echo "loadp2: load P2 binary to board set by P2DEV"

p1: ADXL345-Demo.spin sensor.accel.3dof.adxl345.i2cspi.spin core.con.adxl345.spin
	openspin $(SPIN1_LIB_PATH) -b -D $(IFACE) ADXL345-Demo.spin

p2: ADXL345-Demo.spin2 sensor.accel.3dof.adxl345.i2cspi.spin2 core.con.adxl345.spin
	flexspin $(SPIN2_LIB_PATH) -b -2 -D $(IFACE) -o ADXL345-Demo.bin2 ADXL345-Demo.spin2

loadp1: ADXL345-Demo.binary
	proploader -t -p $(P1DEV) -D $(P1BAUD) ADXL345-Demo.binary

loadp2: ADXL345-Demo.bin2
	loadp2 -SINGLE -p $(P2DEV) -v -b$(P2BAUD) -l$(P2BAUD) ADXL345-Demo.bin2 -t

clean:
	rm -fv *.binary *.bin2 *.pasm *.p2asm

