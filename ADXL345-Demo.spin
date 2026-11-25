{
----------------------------------------------------------------------------------------------------
    Filename:       ADXL345-Demo.spin
    Description:    Demo of the ADXL345 driver
        * accelerometer data output
    Author:         Jesse Burt
    Started:        Mar 14, 2020
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
'#pragma exportdef(ADXL345_I2C_BC)


CON

    _clkmode    = xtal1+pll16x
    _xinfreq    = 5_000_000


OBJ

    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.accel.3dof.adxl345" |   {I2C} SCL=28, SDA=29, I2C_FREQ=400_000, I2C_ADDR=0, ...
                                            {SPI} CS=0, SCK=1, MOSI=2, MISO=3
'   NOTE: If ADXL345_SPI is #defined, and MOSI_PIN and MISO_PIN are the same,
'   the driver will attempt to start in 3-wire SPI mode.


PUB main() | a[3], axis, sign

    setup()

    sensor.preset_active()
    repeat
        ser.pos_xy(0, 3)
        if ( ser.getchar_noblock() == "c" )
            cal_accel()
        repeat
        until sensor.accel_data_rdy()
        sensor.accel_g(@a[sensor.X_AXIS], @a[sensor.Y_AXIS], @a[sensor.Z_AXIS])
        ser.str(@"Accel (g):  ")
        repeat axis from sensor.X_AXIS to sensor.Z_AXIS
            if ( a[axis] < 0 )
                sign := "-"
            else
                sign := " "
            ser.printf(@"%c%d.%06.6d     ", sign, ...
                                            abs(a[axis] / 1_000_000), ...
                                            abs(a[axis] // 1_000_000) )
        ser.newline()


PUB cal_accel()
' Calibrate the accelerometer
    ser.pos_xy(0, 3)
    ser.str(@"Calibrating accelerometer...")
    ser.clear_ln()
    sensor.calibrate_accel()
    ser.pos_xy(0, 3)
    ser.clear_ln()


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
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

