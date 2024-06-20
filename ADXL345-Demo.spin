{
----------------------------------------------------------------------------------------------------
    Filename:       ADXL345-Demo.spin
    Description:    Demo of the ADXL345 driver
    Author:         Jesse Burt
    Started:        Mar 14, 2020
    Updated:        Jun 20, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

' Uncomment the two lines below to use the driver in SPI mode
'#define ADXL345_SPI
'#pragma exportdef(ADXL345_SPI)

' Uncomment the four lines below to use the driver with a bytecode-based SPI engine
'#define ADXL345_SPI
'#define ADXL345_SPI_BC
'#pragma exportdef(ADXL345_SPI)
'#pragma exportdef(ADXL345_SPI_BC)

' Uncomment these two use the driver with a bytecode-based I2C engine
'#define ADXL345_I2C_BC
'#pragma exportdef(ADXL345_I2C_BC)


CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq

' -- User-modifiable constants
    SER_BAUD    = 115_200

    { I2C configuration }
    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_FREQ    = 400_000                       ' max is 400_000
    ADDR_BITS   = 0                             ' 0, 1

    { SPI configuration }
    CS_PIN      = 0
    SCK_PIN     = 1                             ' SCL
    MOSI_PIN    = 2                             ' SDA
    MISO_PIN    = 3                             ' SDO
'   NOTE: If ADXL345_SPI is #defined, and MOSI_PIN and MISO_PIN are the same,
'   the driver will attempt to start in 3-wire SPI mode.
' --


OBJ

    cfg:    "boardcfg.flip"
    sensor: "sensor.accel.3dof.adxl345"
    ser:    "com.serial.terminal.ansi"
    time:   "time"


PUB setup()

    ser.start(SER_BAUD)
    time.msleep(20)
    ser.clear()
    ser.strln(@"Serial terminal started")

#ifdef ADXL345_SPI
    if (sensor.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
#else
    if (sensor.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS))
#endif
        ser.strln(@"ADXL345 driver started")
    else
        ser.strln(@"ADXL345 driver failed to start - halting")
        repeat

    sensor.preset_active()
    repeat
        ser.pos_xy(0, 3)
        if ( ser.rx_check() == "c" )
            cal_accel()
        show_accel_data()

#include "acceldemo.common.spinh"                 ' code common to all accelerometer demos


DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

