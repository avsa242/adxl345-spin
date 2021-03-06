{
    --------------------------------------------
    Filename: ADXL345-Demo.spin
    Author: Jesse Burt
    Description: Demo of the ADXL345 driver
    Copyright (c) 2021
    Started Mar 14, 2020
    Updated May 30, 2021
    See end of file for terms of use.
    --------------------------------------------
}
#define ADXL345_I2C
'#define ADXL345_SPI

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

' -- User-modifiable constants
    LED         = cfg#LED1
    SER_BAUD    = 115_200

    CS_PIN      = 0                             ' SPI
    SCL_PIN     = 1                             ' SPI, I2C
    SDA_PIN     = 2                             ' SPI, I2C
    SDO_PIN     = 3                             ' SPI
    I2C_HZ      = 400_000                       ' I2C (max: 400_000)
    ADDR_BITS   = 0                             ' I2C
' --

    DAT_X_COL   = 20
    DAT_Y_COL   = DAT_X_COL + 15
    DAT_Z_COL   = DAT_Y_COL + 15

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal.ansi"
    time    : "time"
    int     : "string.integer"
    accel   : "sensor.accel.3dof.adxl345.i2cspi"

PUB Main{}

    setup{}
    accel.preset_active{}
    calibrate{}
    ser.hidecursor{}

    repeat
        ser.position(0, 3)
        accelcalc{}
        if ser.rxcheck{} == "c"
            calibrate{}
    until ser.rxcheck{} == "q"

    ser.showcursor{}
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
    accel.calibrateaccel{}
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

#ifdef ADXL345_I2C
    if accel.startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS)
        ser.strln(string("ADXL345 driver started (I2C)"))
#elseifdef ADXL345_SPI
    if accel.startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN)
        ser.strln(string("ADXL345 driver started (SPI)"))
#endif
    else
        ser.str(string("ADXL345 driver failed to start - halting"))
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
