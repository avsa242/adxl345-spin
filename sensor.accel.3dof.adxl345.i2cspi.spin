{
    --------------------------------------------
    Filename: sensor.accel.3dof.adxl345.i2cspi.spin
    Author: Jesse Burt
    Description: Driver for the Analog Devices ADXL345 3DoF Accelerometer
    Copyright (c) 2021
    Started Mar 14, 2020
    Updated May 30, 2021
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Constants used for I2C mode only
    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF       = 3
    GYRO_DOF        = 0
    MAG_DOF         = 0
    BARO_DOF        = 0
    DOF             = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

    R               = 0
    W               = 1

' Scales and data rates used during calibration/bias/offset process
    CAL_XL_SCL      = 2
    CAL_G_SCL       = 0
    CAL_M_SCL       = 0
    CAL_XL_DR       = 100
    CAL_G_DR        = 0
    CAL_M_DR        = 0

' Scale factors used to calculate various register values
    SCL_TAPTHRESH   = 0_062500  {THRESH_TAP: 0.0625 mg/LSB}
    SCL_TAPDUR      = 625       {DUR: 625 usec/LSB}
    SCL_TAPLAT      = 1250      {LATENT: 1250 usec/LSB}
    SCL_DTAPWINDOW  = 1250      {WINDOW: 1250 usec/LSB}

' Operating modes
    STANDBY         = 0
    MEAS            = 1

' FIFO modes
    BYPASS          = %00
    FIFO            = %01
    STREAM          = %10
    TRIGGER         = %11

' ADC resolution
    FULL            = 1

' Interrupts
    DATA_RDY        = 1 << 7
    SING_TAP        = 1 << 6
    DBL_TAP         = 1 << 5
    ACTIVITY        = 1 << 4
    INACTIVITY      = 1 << 3
    FREEFALL        = 1 << 2
    WTRMARK         = 1 << 1
    OVERRUN         = 1

' Axis symbols for use throughout the driver
    X_AXIS          = 0
    Y_AXIS          = 1
    Z_AXIS          = 2

VAR

    long _ares
    long _CS

OBJ

#ifdef ADXL345_I2C
    i2c : "com.i2c"                             ' PASM I2C engine (~800kHz)
#elseifdef ADXL345_SPI
    spi : "com.spi.4w"                          ' PASM SPI engine (~1MHz)
#else
#error "One of ADXL345_I2C or ADXL345_SPI must be defined"
#endif
    core: "core.con.adxl345"                    ' HW-specific constants
    time: "time"                                ' timekeeping methods
    io  : "io"                                  ' I/O pin abstraction methods

PUB Null{}
' This is not a top-level object

#ifdef ADXL345_I2C
PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ, ADDR_BITS): status
' Start using custom I/O pin settings (I2C)
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and {
}   I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)
            i2c.write($FF)
            repeat 2
                i2c.stop{}
            if deviceid{} == core#DEVID_RESP
                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#elseifdef ADXL345_SPI
PUB Startx(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN): status
' Start using custom I/O pin settings (SPI)
    if lookdown(CS_PIN: 0..31) and lookdown(SCL_PIN: 0..31) and {
}   lookdown(SDA_PIN: 0..31) and lookdown(SDO_PIN: 0..31)
        if (status := spi.init(SCL_PIN, SDA_PIN, SDO_PIN, core#SPI_MODE))
            time.msleep(1)
            _CS := CS_PIN

            io.high(_CS)                        ' ensure CS starts high
            io.output(_CS)
            if deviceid{} == core#DEVID_RESP
                return status
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE
#endif
PUB Stop{}

#ifdef ADXL345_I2C
    i2c.deinit{}
#elseifdef ADXL345_SPI
    spi.deinit{}
#endif

PUB Defaults{}
' Factory default settings
    acceladcres(10)
    acceldatarate(100)
    accelscale(2)
    accelselftest(FALSE)
    fifomode(BYPASS)
    intmask(%00000000)
    accelopmode(STANDBY)

PUB Preset_Active{}
' Like Defaults(), but sensor measurement active
    defaults{}
    accelopmode(MEAS)

PUB Preset_ClickDet{}
' Presets for click-detection
    accelopmode(MEAS)
    acceladcres(FULL)
    accelscale(4)
    acceldatarate(100)
    accelaxisenabled(%111)
    clickthresh(2_500000)                       ' must be > 2.5g to be a tap
    clickaxisenabled(%001)                      ' watch z-axis only
    clicktime(5_000)                            ' must be < 5ms to be a tap
    clicklatency(100_000)                       ' wait for 100ms after 1st tap
                                                '   to check for second tap
    doubleclickwindow(300_000)                  ' check second tap for 300ms
    clickintenabled(TRUE)

PUB AccelADCRes(bits): curr_res
' Set accelerometer ADC resolution, in bits
'   Valid values:
'       10: 10bit ADC resolution (AccelScale determines maximum g range and scale factor)
'       FULL: Output resolution increases with the g range, maintaining a 4mg/LSB scale factor
'   Any other value polls the chip and returns the current setting
    curr_res := 0
    readreg(core#DATA_FORMAT, 1, @curr_res)
    case bits
        10:
            bits := 0
        FULL:
            bits <<= core#FULL_RES
        other:
            return ((curr_res >> core#FULL_RES) & 1)

    bits := ((curr_res & core#FULL_RES_MASK) | bits)
    writereg(core#DATA_FORMAT, 1, @bits)

PUB AccelAxisEnabled(xyz_mask)
' Dummy method

PUB AccelBias(bias_x, bias_y, bias_z, rw) | tmp
' Read or write/manually set accelerometer calibration offset values
'   Valid values:
'       rw:
'           R (0), W (1)
'       bias_x, bias_y, bias_z:
'           -128..127
'   NOTE: When rw is set to READ, bias_x, bias_y and bias_z must be addresses
'       of respective variables to hold the returned calibration offset values.
    case rw
        R:
            readreg(core#OFSX, 3, @tmp)
            long[bias_x] := ~tmp.byte[X_AXIS]
            long[bias_y] := ~tmp.byte[Y_AXIS]
            long[bias_z] := ~tmp.byte[Z_AXIS]
            return
        W:
            case bias_x
                -128..127:
                other:
            case bias_y
                -128..127:
                other:
            case bias_z
                -128..127:
                other:
            writereg(core#OFSX, 1, @bias_x)
            writereg(core#OFSY, 1, @bias_y)
            writereg(core#OFSZ, 1, @bias_z)

PUB AccelData(ptr_x, ptr_y, ptr_z) | tmp[2]
' Reads the Accelerometer output registers
    longfill(@tmp, 0, 2)
    readreg(core#DATAX0, 6, @tmp)

    long[ptr_x] := ~~tmp.word[X_AXIS]
    long[ptr_y] := ~~tmp.word[Y_AXIS]
    long[ptr_z] := ~~tmp.word[Z_AXIS]

PUB AccelDataOverrun{}: flag
' Flag indicating previously acquired data has been overwritten
'   Returns: TRUE (-1) if data has overflowed/been overwritten, FALSE otherwise
    flag := 0
    readreg(core#INT_SOURCE, 1, @flag)
    return ((flag & 1) == 1)

PUB AccelDataRate(rate): curr_rate
' Set accelerometer output data rate, in Hz
'   Valid values: See case table below
'   Any other value polls the chip and returns the current setting
'   NOTE: Values containing an underscore represent fractional settings.
'       Examples: 0_10 == 0.1Hz, 12_5 == 12.5Hz
    curr_rate := 0
    readreg(core#BW_RATE, 1, @curr_rate)
    case rate
        0_10, 0_20, 0_39, 0_78, 1_56, 3_13, 6_25, 12_5, 25, 50, 100, 200, 400,{
}       800, 1600, 3200:
            rate := lookdownz(rate: 0_10, 0_20, 0_39, 0_78, 1_56, 3_13, 6_25,{
}           12_5, 25, 50, 100, 200, 400, 800, 1600, 3200)
        other:
            curr_rate &= core#RATE_BITS
            return lookupz(curr_rate: 0_10, 0_20, 0_39, 0_78, 1_56, 3_13,{
}           6_25, 12_5, 25, 50, 100, 200, 400, 800, 1600, 3200)

    rate := ((curr_rate & core#RATE_MASK) | rate)
    writereg(core#BW_RATE, 1, @rate)

PUB AccelDataReady{}: flag
' Flag indicating accelerometer data is ready
'   Returns: TRUE (-1) if data ready, FALSE otherwise
    flag := 0
    readreg(core#INT_SOURCE, 1, @flag)
    return (((flag >> core#DATA_RDY) & 1) == 1)

PUB AccelG(ptr_x, ptr_y, ptr_z) | tmpx, tmpy, tmpz
' Reads the Accelerometer output registers and scales the outputs to micro-g's (1_000_000 = 1.000000 g = 9.8 m/s/s)
    acceldata(@tmpx, @tmpy, @tmpz)
    long[ptr_x] := tmpx * _ares
    long[ptr_y] := tmpy * _ares
    long[ptr_z] := tmpz * _ares

PUB AccelOpMode(mode): curr_mode
' Set operating mode
'   Valid values:
'       STANDBY (0): Standby
'       MEAS (1): Measurement mode
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#PWR_CTL, 1, @curr_mode)
    case mode
        STANDBY, MEAS:
            mode <<= core#MEAS
        other:
            return ((curr_mode >> core#MEAS) & 1)

    mode := ((curr_mode & core#MEAS_MASK) | mode)
    writereg(core#PWR_CTL, 1, @mode)

PUB AccelScale(scale): curr_scl
' Set measurement range of the accelerometer, in g's
'   Valid values: 2, 4, 8, 16
'   Any other value polls the chip and returns the current setting
    curr_scl := 0
    readreg(core#DATA_FORMAT, 1, @curr_scl)
    case scale
        2, 4, 8, 16:
            scale := lookdownz(scale: 2, 4, 8, 16)
            if acceladcres(-2) == FULL          ' ADC full-res scale factor
                _ares := 4_300                  '   is always 4.3mg/LSB
            else                                ' 10-bit res is scale-dependent
                _ares := lookupz(scale: 4_300, 8_700, 17_500, 34_500)
        other:
            curr_scl &= core#RANGE_BITS
            return lookupz(curr_scl: 2, 4, 8, 16)

    scale := ((curr_scl & core#RANGE_MASK) | scale)
    writereg(core#DATA_FORMAT, 1, @scale)

PUB AccelSelfTest(state): curr_state
' Enable self-test mode
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#DATA_FORMAT, 1, @curr_state)
    case ||(state)
        0, 1:
            state := ||(state) << core#SELF_TEST
        other:
            return (((curr_state >> core#SELF_TEST) & 1) == 1)

    state := ((curr_state & core#SELF_TEST_MASK) | state)
    writereg(core#DATA_FORMAT, 1, @state)

PUB CalibrateAccel{} | axis, orig_res, orig_scl, orig_drate, tmp[3], tmpx, tmpy, tmpz, samples, scale
' Calibrate the accelerometer
'   NOTE: The accelerometer must be oriented with the package top facing up for this method to be successful
    longfill(@axis, 0, 7)                       ' initialize vars to 0
    orig_res := acceladcres(-2)                 ' save user's current settings
    orig_scl := accelscale(-2)
    orig_drate := acceldatarate(-2)

    accelbias(0, 0, 0, W)

    ' set sensor to full ADC resolution, +/-2g range, 100Hz data rate
    acceladcres(FULL)
    accelscale(CAL_XL_SCL)
    acceldatarate(CAL_XL_DR)
    samples := CAL_XL_DR
    ' conversion scale for calibration offset regs (15.6mg per LSB / 4.3mg)
    scale := 15_6000 / 4_3

    repeat samples                              ' average 10 samples together
        repeat until acceldataready{}
        acceldata(@tmpx, @tmpy, @tmpz)
        tmp[X_AXIS] -= (tmpx * 1_000)           ' scale up to preserve accuracy
        tmp[Y_AXIS] -= (tmpy * 1_000)
        tmp[Z_AXIS] += ((tmpz * 1_000)-256_000) ' cancel out 1g on Z-axis

    repeat axis from X_AXIS to Z_AXIS
        tmp[axis] /= samples

    ' write the offsets to the sensor (volatile memory)
    accelbias(tmp[X_AXIS]/scale, tmp[Y_AXIS]/scale, tmp[Z_AXIS]/scale, W)

    acceladcres(orig_res)                       ' restore user's settings
    accelscale(orig_scl)
    acceldatarate(orig_drate)

PUB CalibrateMag(samples)
' Dummy method

PUB CalibrateXLG{}
' Calibrate accelerometer and gyroscope
'   (compatibility method)
    calibrateaccel{}

PUB ClickAxisEnabled(mask): curr_mask
' Enable click detection, per axis bitmask
'   Valid values: %000..%111 (%xyz)
'   Any other value polls the chip and returns the current setting
    curr_mask := 0
    readreg(core#TAP_AXES, 1, @curr_mask)
    case mask
        %000..%111:
        other:
            return curr_mask & core#TAPXYZ_BITS

    mask := ((curr_mask & core#TAPXYZ_MASK) | mask)
    writereg(core#TAP_AXES, 1, @mask)

PUB Clicked{}: flag
' Flag indicating the sensor was single-clicked
'   NOTE: Calling this method clears all interrupts
    return ((interrupt{} & SING_TAP) <> 0)

PUB ClickedInt{}: intstat
' Clicked interrupt status
'   NOTE: Calling this method clears all interrupts
    return (interrupt{} >> core#TAP) & core#TAP_BITS

PUB ClickedX{}: flag
' Flag indicating click event on X axis
'   Returns: TRUE (-1) if click event detected
    flag := 0
    readreg(core#ACT_TAP_STATUS, 1, @flag)
    return (((flag >> core#TAP_X_SRC) & 1) == 1)

PUB ClickedY{}: flag
' Flag indicating click event on Y axis
'   Returns: TRUE (-1) if click event detected
    flag := 0
    readreg(core#ACT_TAP_STATUS, 1, @flag)
    return (((flag >> core#TAP_X_SRC) & 1) == 1)

PUB ClickedZ{}: flag
' Flag indicating click event on Z axis
'   Returns: TRUE (-1) if click event detected
    flag := 0
    readreg(core#ACT_TAP_STATUS, 1, @flag)
    return (((flag >> core#TAP_X_SRC) & 1) == 1)

PUB ClickedXYZ{}: mask
' Mask indicating which axes click event occurred on
'   Returns: %xyz event bitmask (0 = no click, 1 = clicked)
    mask := 0
    readreg(core#ACT_TAP_STATUS, 1, @mask)
    return (mask & core#TAP_SRC_BITS)

PUB ClickIntEnabled(state): curr_state | tmp
' Enable click interrupts
'   Valid values: TRUE (-1 or 1), FALSE (0)
'   Any other value polls the chip and returns the current setting
    curr_state := intmask(-2)
    case ||(state)
        0:
        1:
            state := %11 << core#TAP            ' enable both single & dbl tap
        other:
            return ((curr_state >> core#TAP) & core#TAP_BITS)

    state := ((curr_state & core#TAP_MASK) | state)
    intmask(state)

PUB ClickLatency(clat): curr_clat
' Set minimum interval/wait between detection of first click and start of
'   window during which a second click can be detected, in usec
'   Valid values: 0..318_750 (will be rounded to nearest multiple of 1_250)
'   Any other value polls the chip and returns the current setting
    case clat
        0..318_750:
            clat /= SCL_TAPLAT
            writereg(core#LATENT, 1, @clat)
        other:
            curr_clat := 0
            readreg(core#LATENT, 1, @curr_clat)
            return curr_clat * SCL_TAPLAT

PUB ClickThresh(level): curr_lvl
' Set threshold for recognizing a click, in micro-g's
'   Valid values: 0..16_000_000 (will be rounded to nearest multiple of 62_500)
'   Any other value polls the chip and returns the current setting
    case level
        0..16_000_000:
            level /= SCL_TAPTHRESH
            writereg(core#THRESH_TAP, 1, @level)
        other:
            curr_lvl := 0
            readreg(core#THRESH_TAP, 1, @curr_lvl)
            return curr_lvl * SCL_TAPTHRESH

PUB ClickTime(usec): curr_ctime
' Set maximum elapsed interval between start of click and end of click, in uSec
' Events longer than this will not be considered a click
'   Valid values: 0..159_375 (will be rounded to nearest multiple of 625)
'   Any other value polls the chip and returns the current setting
    case usec
        0..159_375:
            usec /= SCL_TAPDUR
            writereg(core#DUR, 1, @usec)
        other:
            curr_ctime := 0
            readreg(core#DUR, 1, @curr_ctime)
            return curr_ctime * SCL_TAPDUR

PUB DeviceID{}: id
' Read device identification
    id := 0
    readreg(core#DEVID, 1, @id)

PUB DoubleClicked{}: flag
' Flag indicating sensor was double-clicked
'   NOTE: Calling this method clears all interrupts
    return ((interrupt{} & DBL_TAP) <> 0)

PUB DoubleClickWindow(dctime): curr_dctime
' Set window of time after ClickLatency() elapses that a second click
'   can be detected
'   Valid values: 0..318_750 (will be rounded to nearest multiple of 1_250)
'   Any other value polls the chip and returns the current setting
    case dctime
        0..318_750:
            dctime /= SCL_DTAPWINDOW
            writereg(core#WINDOW, 1, @dctime)
        other:
            curr_dctime := 0
            readreg(core#WINDOW, 1, @curr_dctime)
            return curr_dctime * SCL_DTAPWINDOW

PUB FIFOMode(mode): curr_mode
' Set FIFO operation mode
'   Valid values:
'      *BYPASS (%00): Don't use the FIFO functionality
'       FIFO (%01): FIFO enabled (stops collecting data when full, but device continues to operate)
'       STREAM (%10): FIFO enabled (continues accumulating samples; holds latest 32 samples)
'       TRIGGER (%11): FIFO enabled (holds latest 32 samples. When trigger event occurs, the last n samples,
'           set by FIFOSamples(), are kept. The FIFO then collects samples as long as it isn't full.
'   Any other value polls the chip and returns the current setting
    curr_mode := 0
    readreg(core#FIFO_CTL, 1, @curr_mode)
    case mode
        BYPASS, FIFO, STREAM, TRIGGER:
            mode <<= core#FIFO_MODE
        other:
            return (curr_mode >> core#FIFO_MODE) & core#FIFO_MODE_BITS

    mode := ((curr_mode & core#FIFO_MODE_MASK) | mode)
    writereg(core#FIFO_CTL, 1, @mode)

PUB GyroAxisEnabled(xyzmask)
' Dummy method

PUB GyroBias(x, y, z, rw)
' Dummy method

PUB GyroData(x, y, z)
' Dummy method

PUB GyroDataReady{}
' Dummy method

PUB GyroDPS(x, y, z)
' Dummy method

PUB GyroScale(scale)
' Dummy method

PUB Interrupt{}: int_src
' Flag indicating interrupt(s) asserted
'   Bits: 76543210
'       7: Data Ready
'       6: Single-tap
'       5: Double-tap
'       4: Activity
'       3: Inactivity
'       2: Free-fall
'       1: Watermark
'       0: Overrun
'   NOTE: Calling this method clears all interrupts
    readreg(core#INT_SOURCE, 1, @int_src)

PUB IntMask(mask): curr_mask
' Set interrupt mask
'   Bits: 76543210
'       7: Data Ready (Always enabled, regardless of setting)
'       6: Single-tap
'       5: Double-tap
'       4: Activity
'       3: Inactivity
'       2: Free-fall
'       1: Watermark (Always enabled, regardless of setting)
'       0: Overrun (Always enabled, regardless of setting)
'   Valid values: %00000000..%11111111
'   Any other value polls the chip and returns the current setting
    case mask
        %0000_0000..%1111_1111:
            writereg(core#INT_ENABLE, 1, @mask)
        other:
            curr_mask := 0
            readreg(core#INT_ENABLE, 1, @curr_mask)
            return curr_mask

PUB MagBias(x, y, z, rw)
' Dummy method

PUB MagData(x, y, z)
' Dummy method

PUB MagDataRate(hz)
' Dummy method

PUB MagDataReady{}
' Dummy method

PUB MagGauss(x, y, z)
' Dummy method

PUB MagScale(scale)
' Dummy method

PRI readReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from slave device into ptr_buff
    case reg_nr
        $00, $1D..$31, $38, $39:
        $32..$37:                               ' accel data regs; set the
#ifdef ADXL345_SPI
            reg_nr |= core#MB                   '   multi-byte transaction bit
#endif
        other:
            return

#ifdef ADXL345_I2C
    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start{}
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start{}
    i2c.wr_byte(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
    i2c.stop{}
#elseifdef ADXL345_SPI
    io.low(_CS)
    spi.wr_byte(reg_nr | core#R)
    spi.rdblock_lsbf(ptr_buff, nr_bytes)
    io.high(_CS)
#endif

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes from ptr_buff to slave device
    case reg_nr
        $1D..$2A, $2C..$2F, $31, $38:
#ifdef ADXL345_I2C
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
            i2c.stop{}
#elseifdef ADXL345_SPI
            io.low(_CS)
            spi.wr_byte(reg_nr)
            spi.wrblock_lsbf(ptr_buff, nr_bytes)
            io.high(_CS)
#endif
        other:
            return

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
