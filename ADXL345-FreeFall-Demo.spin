{
    --------------------------------------------
    Filename: ADXL345-FreeFall-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADXL345 driver
        Free-fall detection functionality
    Copyright (c) 2021
    Started Nov 7, 2021
    Updated Nov 12, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_PIN      = 0                             ' SPI
    SCL_PIN     = 1                             ' SPI, I2C
    SDA_PIN     = 2                             ' SPI, I2C
    SDO_PIN     = 3                             ' SPI (4-wire only)
    I2C_HZ      = 400_000                       ' I2C (max: 400_000)
    ADDR_BITS   = 0                             ' I2C

    INT1        = 16
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    accel   : "sensor.accel.3dof.adxl345.i2cspi"
    int     : "string.integer"

VAR

    long _isr_stack[50]                         ' stack for ISR core
    long _intflag                               ' interrupt flag

PUB Main{} | intsource

    setup{}
    accel.preset_freefall{}                     ' default settings, but enable
                                                ' sensors, set scale factors,
                                                ' and free-fall parameters

    ser.position(0, 3)
    ser.str(string("Waiting for free-fall condition..."))

    ' When the sensor detects free-fall, a message is displayed and
    '   is cleared after the user presses a key
    ' The preset for free-fall detection sets a free-fall threshold of
    '   0.315g's for a minimum time of 100ms. This can be tuned using
    '   accel.FreeFallThresh() and accel.FreeFallTime():
    accel.freefallthresh(0_315000)              ' 0.315g's
    accel.freefalltime(100_000)                 ' 100_000us/100ms

    repeat
        if _intflag                             ' interrupt triggered?
            intsource := accel.interrupt{}      ' read & clear interrupt flags
            if (intsource & accel#INT_FFALL)    ' free-fall event?
                ser.position(0, 3)
                ser.str(string("Sensor in free-fall!"))
                ser.clearline{}
                ser.newline{}
                ser.str(string("Press any key to reset"))
                ser.charin{}
                ser.positionx(0)
                ser.clearline{}
                ser.position(0, 3)
                ser.str(string("Sensor stable"))
                ser.clearline{}

        if ser.rxcheck{} == "c"                 ' press the 'c' key in the demo
            calibrate{}                         ' to calibrate sensor offsets
                                                ' (ensure sensor is level and
                                                ' chip package top faces up)

PRI Calibrate{}
' Calibrate sensor/set bias offsets
    ser.position(0, 7)
    ser.str(string("Calibrating..."))
    accel.calibrateaccel{}
    ser.positionx(0)
    ser.clearline{}

PRI ISR{}
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

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))

#ifdef ADXL345_I2C
    if accel.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS)
        ser.strln(string("ADXL345 driver started (I2C)"))
#elseifdef ADXL345_SPI3W
    if accel.startx(CS_PIN, SCL_PIN, SDA_PIN)
        ser.strln(string("ADXL345 driver started (SPI-3 wire)"))
#elseifdef ADXL345_SPI4W
    if accel.startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.strln(string("ADXL345 driver started (SPI-4 wire)"))
#endif
    else
        ser.strln(string("ADXL345 driver failed to start - halting"))
        repeat

    cognew(isr, @_isr_stack)                    ' start ISR in another core

DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
