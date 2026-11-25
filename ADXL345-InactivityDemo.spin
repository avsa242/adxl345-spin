{
----------------------------------------------------------------------------------------------------
    Filename:       ADXL345-InactivityDemo.spin
    Description:    Demo of the ADXL345 driver
        * Inactivity interrupt functionality
    Author:         Jesse Burt
    Started:        Aug 29, 2021
    Updated:        Nov 25, 2026
    Copyright (c) 2026 - See end of file for terms of use.
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


CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    accel:  "sensor.accel.3dof.adxl345" |   {I2C} SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=0, ...
                                            {SPI} CS=0, SCK=1, MOSI=2, MISO=3
'   NOTE: If ADXL345_SPI is #defined, and MOSI_PIN and MISO_PIN are the same,
'   the driver will attempt to start in 3-wire SPI mode.


PUB main() | i

    setup()
    accel.preset_active()                       ' default settings, but enable
                                                ' sensor data acquisition and
                                                ' set scale factor
    accel.calibrate_accel()
    accel.act_inact_link(TRUE)
    accel.act_set_thresh(0_500000)
    accel.inact_set_thresh(0_125000)
    accel.inact_set_time(3)
    accel.act_axis_ena(%110)
    accel.inact_axis_ena(%110)
    accel.accel_int_set_mask(accel.INT_ACTIV | accel.INT_INACT)
    accel.auto_sleep_ena(TRUE)

    ser.printf(@"Activity threshold: %dug\n\r", accel.act_thresh())
    ser.printf(@"Inactivity threshold: %dug\n\r", accel.inact_thresh())
    ser.printf(@"Inactivity time: %dsecs\n\r", accel.inact_time())
    ser.printf(@"Auto-sleep enabled: %d\n\r", accel.auto_sleep_ena())
    ser.printf(@"Activity axes enabled (XYZ): %03.3b\n\r", accel.act_axis_ena())
    ser.printf(@"Inactivity axes enabled (XYZ): %b\n\r", accel.inact_axis_ena())
    ser.strln(@"Move the sensor to awaken it.")
    ser.strln(@"This can be done again, once it reports INACTIVE.")

    repeat
        i := accel.accel_int()
        if (i & accel.INT_INACT)
            ser.strln(@"INACTIVE")
        if (i & accel.INT_ACTIV)
            ser.strln(@"ACTIVE")


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( accel.start() )
        ser.strln(@"ADXL345 driver started")
    else
        ser.strln(@"ADXL345 driver failed to start - halting")
        repeat


DAT
{
Copyright 2026 Jesse Burt

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

