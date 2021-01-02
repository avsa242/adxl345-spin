{
    --------------------------------------------
    Filename: sensor.accel.3dof.adxl345.spi.spin
    Author: Jesse Burt
    Description: Driver for the Analog Devices ADXL345 3DoF Accelerometer
    Copyright (c) 2020
    Started Mar 14, 2020
    Updated Jul 19, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' Indicate to user apps how many Degrees of Freedom each sub-sensor has
'   (also imply whether or not it has a particular sensor)
    ACCEL_DOF           = 3
    GYRO_DOF            = 0
    MAG_DOF             = 0
    BARO_DOF            = 0
    DOF                 = ACCEL_DOF + GYRO_DOF + MAG_DOF + BARO_DOF

    R                   = 0
    W                   = 1


' Operating modes
    STANDBY             = 0
    MEAS                = 1

' FIFO modes
    BYPASS              = %00
    FIFO                = %01
    STREAM              = %10
    TRIGGER             = %11

' ADC resolution
    FULL                = 1

' Axis symbols for use throughout the driver
    X_AXIS              = 0
    Y_AXIS              = 1
    Z_AXIS              = 2

VAR

    long _ares
    long _abiasraw[3]
    long _CS, _SCK, _MOSI, _MISO

OBJ

    spi : "com.spi.4w"
    core: "core.con.adxl345"
    time: "time"
    io  : "io"

PUB Null{}
' This is not a top-level object

PUB Start(CS_PIN, SCL_PIN, SDA_PIN, SDO_PIN): okay
    if lookdown(CS_PIN: 0..31) and lookdown(SCL_PIN: 0..31) and{
}   lookdown(SDA_PIN: 0..31) and lookdown(SDO_PIN: 0..31)
        if okay := spi.start(core#CLK_DELAY, core#CPOL)
            time.msleep(1)
            longmove(@_CS, @CS_PIN, 4)          ' copy i/o pins to hub vars

            io.high(_CS)
            io.output(_CS)
            if deviceid{} == core#DEVID_RESP
                return okay
    return FALSE                                ' something above failed

PUB Stop{}

    spi.stop{}

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

    bits := ((curr_res & core#FULL_RES_MASK) | bits) & core#DATA_FORMAT_MASK
    writereg(core#DATA_FORMAT, 1, @bits)

PUB AccelAxisEnabled(xyz_mask)
' Dummy method

PUB Accelbias(axbias, aybias, azbias, rw)
' Read or write/manually set accelerometer calibration offset values
'   Valid values:
'       rw:
'           R (0), W (1)
'       axbias, aybias, azbias:
'           -128..127
'   NOTE: When rw is set to READ, axbias, aybias and azbias must be addresses of respective variables to hold the returned calibration offset values.
    case rw
        R:
            long[axbias] := _abiasraw[X_AXIS]
            long[aybias] := _abiasraw[Y_AXIS]
            long[azbias] := _abiasraw[Z_AXIS]

        W:
            case axbias
                -128..127:
                    _abiasraw[X_AXIS] := axbias
                other:

            case aybias
                -128..127:
                    _abiasraw[Y_AXIS] := aybias
                other:

            case azbias
                -128..127:
                    _abiasraw[Z_AXIS] := azbias
                other:


PUB AccelClearOffsets{} 'XXX axe? revisit...what was this used for and why couldn't accelbias() be used?
' Clear calibration offsets set in the accelerometer
'   NOTE: The offsets don't survive a power-loss. This is intended for when the microcontroller is warm-booted or the driver is restarted, where no power loss to the sensor has occurred.
    result := 0
    writereg(core#OFSX, 2, @result)
    writereg(core#OFSY, 2, @result)
    writereg(core#OFSZ, 2, @result)

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
'       Examples: 0_10 == 0.1rate, 12_5 == 12.5rate
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

    rate := ((curr_rate & core#RATE_MASK) | rate) & core#BW_RATE_MASK
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

    mode := ((curr_mode & core#MEAS_MASK) | mode) & core#PWR_CTL_MASK
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
            scale <<= core#RANGE
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
            return (((curr_state >> core#SELF_TEST) & %1) == 1)

    state := ((curr_state & core#SELF_TEST_MASK) | state) & core#DATA_FORMAT_MASK
    writereg(core#DATA_FORMAT, 1, @state)

PUB Calibrate{} | axis, orig_state, tmp[3], samples, scale
' Calibrate the accelerometer
'   NOTE: The accelerometer must be oriented with the package top facing up for this method to be successful
    longfill(@axis, 0, 7)                       ' initialize vars to 0
    samples := 10
    orig_state.byte[0] := acceladcres(-2)       ' save user's current settings
    orig_state.byte[1] := accelscale(-2)
    orig_state.word[1] := acceldatarate(-2)

    ' set sensor to full ADC resolution, +/-2g range, 100Hz data rate
    acceladcres(FULL)
    accelscale(2)
    acceldatarate(100)

    ' conversion scale for calibration offset regs (15.6mg per LSB / 4.3mg)
    scale := 15_6000 / 4_3

    repeat samples                              ' average 10 samples together
        acceldata(@tmp[X_AXIS], @tmp[Y_AXIS], @tmp[Z_AXIS])
        tmp[X_AXIS] += -(tmp[X_AXIS]*1_000)     ' scale up to preserve accuracy
        tmp[Y_AXIS] += -(tmp[Y_AXIS]*1_000)
        tmp[Z_AXIS] += -((tmp[Z_AXIS]*1_000)-256_000)' cancel out 1g on Z-axis

    ' write the offsets to the sensor (volatile memory)
    repeat axis from X_AXIS to Z_AXIS
        _abiasraw[axis] := tmp[AXIS] / samples
        tmp[axis] := _abiasraw[axis] / scale
        writereg(core#OFSX+axis, 2, @tmp[axis])

    acceladcres(orig_state.byte[0])             ' restore user's settings
    accelscale(orig_state.byte[1])
    acceldatarate(orig_state.word[1])

PUB CalibrateMag(samples)
' Dummy method

PUB CalibrateXLG{}
' Calibrate accelerometer and gyroscope
'   (compatibility method)
    calibrate{}

PUB DeviceID{}: id
' Read device identification
    id := 0
    readreg(core#DEVID, 1, @id)

PUB FIFOMode(mode) | curr_mode
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

    mode := ((curr_mode & core#FIFO_MODE_MASK) | mode) & core#FIFO_CTL_MASK
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

PUB Interrupt{}
' Dummy method

PUB IntMask(mask): curr_mask
' Set interrupt mask
'   Bits:   76543210
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

PRI readReg(reg_nr, nr_bytes, ptr_buff) | tmp
' Read nr_bytes from slave device into ptr_buff
    case reg_nr
        $00, $1D..$31, $38, $39:
        $32..$37:                               ' accel data regs; set the
            reg_nr |= core#MB                   '   multi-byte transaction bit
        other:
            return

    io.low(_CS)
    spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg_nr | core#R)

    repeat tmp from 0 to nr_bytes-1
        byte[ptr_buff][tmp] := spi.shiftin(_MISO, _SCK, core#MISO_BITORDER, 8)
    io.high(_CS)

PRI writeReg(reg_nr, nr_bytes, ptr_buff) | tmp
' Write nr_bytes from ptr_buff to slave device
    case reg_nr
        $1D..$2A, $2C..$2F, $31, $38:
            io.low(_CS)
            spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, reg_nr)

            repeat tmp from 0 to nr_bytes-1
                spi.shiftout(_MOSI, _SCK, core#MOSI_BITORDER, 8, byte[ptr_buff][tmp])
            io.high(_CS)
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
