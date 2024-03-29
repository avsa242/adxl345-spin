{
    --------------------------------------------
    Filename: ADXL345-FreeFall-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADXL345 driver
        Free-fall detection functionality
    Copyright (c) 2022
    Started Nov 7, 2021
    Updated Nov 5, 2022
    See end of file for terms of use.
    --------------------------------------------

    Build-time symbols supported by driver:
        -DADXL345_SPI
        -DADXL345_SPI_BC
        -DADXL345_I2C (default if none specified)
        -DADXL345_I2C_BC
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
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

    INT1        = 16
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    accel   : "sensor.accel.3dof.adxl345"

VAR

    long _isr_stack[50]                         ' stack for ISR core
    long _intflag                               ' interrupt flag

PUB main{} | intsource

    setup{}
    accel.preset_freefall{}                     ' default settings, but enable
                                                ' sensors, set scale factors,
                                                ' and free-fall parameters

    ser.pos_xy(0, 3)
    ser.puts(string("Waiting for free-fall condition..."))

    ' When the sensor detects free-fall, a message is displayed and
    '   is cleared after the user presses a key
    ' The preset for free-fall detection sets a free-fall threshold of
    '   0.315g's for a minimum time of 100ms. This can be tuned using
    '   accel.freefall_sethresh() and accel.freefall_set_time():
    accel.freefall_set_thresh(0_315000)         ' 0.315g's
    accel.freefall_set_time(100_000)            ' 100_000us/100ms

    repeat
        if (_intflag)                           ' interrupt triggered?
            intsource := accel.accel_int{}      ' read & clear interrupt flags
            if (intsource & accel#INT_FFALL)    ' free-fall event?
                ser.pos_xy(0, 3)
                ser.puts(string("Sensor in free-fall!"))
                ser.clear_line{}
                ser.newline{}
                ser.puts(string("Press any key to reset"))
                ser.getchar{}
                ser.pos_x(0)
                ser.clear_line{}
                ser.pos_xy(0, 3)
                ser.puts(string("Sensor stable"))
                ser.clear_line{}

        if (ser.rx_check{} == "c")               ' press the 'c' key in the demo
            calibrate{}                         ' to calibrate sensor offsets
                                                ' (ensure sensor is level and
                                                ' chip package top faces up)

PRI calibrate{}
' Calibrate sensor/set bias offsets
    ser.pos_xy(0, 7)
    ser.puts(string("Calibrating..."))
    accel.calibrate_accel{}
    ser.pos_x(0)
    ser.clear_line{}

PRI cog_isr{}
' Interrupt service routine
    dira[INT1] := 0                             ' INT1 as input
    dira[LED] := 1                              ' LED as output
    repeat
        waitpeq(|< INT1, |< INT1, 0)            ' wait for INT1 (active high)
        outa[LED] := 1                          ' light LED
        _intflag := 1                           '   set flag

        waitpne(|< INT1, |< INT1, 0)            ' now wait for it to clear
        outa[LED] := 0                          ' turn off LED
        _intflag := 0                           '   clear flag

PUB setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef ADXL345_SPI
    if (accel.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
#else
    if (accel.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS))
#endif
        ser.strln(string("ADXL345 driver started"))
    else
        ser.strln(string("ADXL345 driver failed to start - halting"))
        repeat

    cognew(cog_isr{}, @_isr_stack)              ' start ISR in another core

DAT
{
Copyright 2022 Jesse Burt

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

