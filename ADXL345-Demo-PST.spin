{
    --------------------------------------------
    Filename: ADXL345-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADXL345 driver
    Copyright (c) 2021
    Started Mar 14, 2020
    Updated Jan 1, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_PIN      = 0
    SCL_PIN     = 1
    SDA_PIN     = 2
    SDO_PIN     = 3
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    int     : "string.integer"
    accel   : "sensor.accel.3dof.adxl345.spi"

PUB Main{}

    setup{}
    accel.preset_active{}
    calibrate{}

    repeat
        ser.position(0, 3)
        accelcalc{}
        if ser.rxcheck{} == "c"
            calibrate{}
    until ser.rxcheck{} == "q"

    repeat

PUB AccelCalc{} | ax, ay, az

    repeat until accel.acceldataready{}
    accel.accelg(@ax, @ay, @az)
    ser.str(string("Accel micro-g: "))
    ser.position(DAT_X_COL, 3)
    decimal(ax, 1_000_000)
    ser.position(DAT_Y_COL, 3)
    decimal(ay, 1_000_000)
    ser.position(DAT_Z_COL, 3)
    decimal(az, 1_000_000)
    ser.clearline{}
    ser.newline{}

PUB Calibrate{}

    ser.position(0, 3)
    ser.str(string("Calibrating..."))
    accel.calibrate{}
    ser.position(0, 3)
    ser.clearline{}

PRI Decimal(scaled, divisor) | whole[4], part[4], places, tmp, sign
' Display a scaled up number as a decimal
'   Scale it back down by divisor (e.g., 10, 100, 1000, etc)
    whole := scaled / divisor
    tmp := divisor
    places := 0
    part := 0
    sign := 0
    if scaled < 0
        sign := "-"
    else
        sign := " "

    repeat
        tmp /= 10
        places++
    until tmp == 1
    scaled //= divisor
    part := int.deczeroed(||(scaled), places)

    ser.char(sign)
    ser.dec(||(whole))
    ser.char(".")
    ser.str(part)

PUB Setup{}

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear{}
    ser.strln(string("Serial terminal started"))
    if accel.start(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.strln(string("ADXL345 driver started"))
    else
        ser.str(string("ADXL345 driver failed to start - halting"))
        accel.stop{}
        time.msleep(5)
        ser.stop{}
        repeat

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
