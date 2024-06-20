{
----------------------------------------------------------------------------------------------------
    Filename:       ADXL345-ClickDemo.spin
    Description:    Demo of the ADXL345 driver
        * click-detection functionality
    Author:         Jesse Burt
    Started:        May 30, 2021
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
    LED         = cfg.LED1
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
    ser:    "com.serial.terminal.ansi"
    time:   "time"
    accel:  "sensor.accel.3dof.adxl345"


VAR

    long _showclk_stack[60]
    long _s_cnt, _d_cnt
    long _click_src, _dclicked, _sclicked
    long _dc_wind


PUB main()

    setup()
    accel.preset_clickdet()                     ' preset settings for click-detection
    _s_cnt := _d_cnt := 0
    _dc_wind := (accel.dbl_click_win() / 1000)
    repeat
        repeat until _click_src := accel.clicked_int()

        _dclicked := (_click_src & 1)
        _sclicked := ((_click_src >> 1) & 1)
        if (_dclicked)
            _click_src := 0
            _d_cnt++
            next
        if (_sclicked)
            _click_src := 0
            _s_cnt++


PRI cog_show_click_status()
' Secondary cog to display click status
    repeat
        ser.position(0, 3)
        ser.printf2(@"Double-clicked:  %s (%d)\n\r", yesno(_dclicked), _d_cnt)
        ser.printf2(@"Single-clicked:  %s (%d)\n\r", yesno(_sclicked), _s_cnt)
        _dclicked := _sclicked := false
        ' wait for double-click window time to elapse, so the display doesn't
        '   update too fast to be seen
        time.msleep(_dc_wind)


PRI yesno(val): resp
' Return pointer to string "Yes" or "No" depending on value called with
    case ||(val)
        0:
            return @"No "
        1:
            return @"Yes"


PUB setup()

    ser.start(SER_BAUD)
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

#ifdef ADXL345_SPI
    if (accel.startx(CS_PIN, SCK_PIN, MOSI_PIN, MISO_PIN))
#else
    if (accel.startx(SCL_PIN, SDA_PIN, I2C_FREQ, ADDR_BITS))
#endif
        ser.strln(@"ADXL345 driver started")
    else
        ser.strln(@"ADXL345 driver failed to start - halting")
        repeat

    cognew(cog_show_click_status(), @_showclk_stack)


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

