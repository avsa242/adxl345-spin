# adxl345-spin Makefile - requires GNU Make, or compatible
# Variables below can be overridden on the command line
#	e.g. IFACE=ADXL345_SPI3W make

# P1, P2 device nodes and baudrates
#P1DEV=
P1BAUD=115200
#P2DEV=
P2BAUD=2000000

# P1, P2 compilers
P1BUILD=openspin
#P1BUILD=flexspin
P2BUILD=flexspin

# ADXL345 interface: I2C, SPI-3wire or SPI-4wire
IFACE=ADXL345_I2C
#IFACE=ADXL345_SPI3W
#IFACE=ADXL345_SPI4W

# Paths to spin-standard-library, and p2-spin-standard-library,
#  if not specified externally
SPIN1_LIB_PATH=-L ../spin-standard-library/library
SPIN2_LIB_PATH=-L ../p2-spin-standard-library/library

# Load both P1 and P2 targets (will build first, if necessary)
all: p1 p2

# Load P1 or P2 target (will build first, if necessary)
p1: loadp1
p2: loadp2

# Build binaries
ADXL345-Demo.binary: ADXL345-Demo.spin sensor.accel.3dof.adxl345.i2cspi.spin core.con.adxl345.spin
	$(P1BUILD) $(SPIN1_LIB_PATH) -b -D $(IFACE) ADXL345-Demo.spin

ADXL345-Demo.bin2: ADXL345-Demo.spin2 sensor.accel.3dof.adxl345.i2cspi.spin2 core.con.adxl345.spin
	$(P2BUILD) $(SPIN2_LIB_PATH) -b -2 -D $(IFACE) -o ADXL345-Demo.bin2 ADXL345-Demo.spin2

# Load binaries to RAM (will build first, if necessary)
loadp1: ADXL345-Demo.binary
	proploader -t -p $(P1DEV) -Dbaudrate=$(P1BAUD) ADXL345-Demo.binary

loadp2: ADXL345-Demo.bin2
	loadp2 -SINGLE -p $(P2DEV) -v -b$(P2BAUD) -l$(P2BAUD) ADXL345-Demo.bin2 -t

# Remove built binaries and assembler outputs
clean:
	rm -fv *.binary *.bin2 *.pasm *.p2asm

