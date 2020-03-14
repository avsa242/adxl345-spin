{
    --------------------------------------------
    Filename: core.con.adxl345.spin
    Author: Jesse Burt
    Description: Low-level constants
    Copyright (c) 2020
    Started Mar 14, 2020
    Updated Mar 14, 2020
    See end of file for terms of use.
    --------------------------------------------
}

CON

' SPI Configuration
    CPOL                        = 1
    CLK_DELAY                   = 10
    MOSI_BITORDER               = 5             'MSBFIRST
    MISO_BITORDER               = 2             'MSBPOST
    SCK_MAX_FREQ                = 5_000_000

' I2C Configuration
    SLAVE_ADDR                  = $1D << 7
    I2C_MAX_FREQ                = 400_000

    W                           = 0
    R                           = 1 << 7

' Register definitions
    DEVID                       = $00
        DEVID_RESP              = $E5

    THRESH_TAP                  = $1D
    OFSX                        = $1E
    OFSY                        = $1F
    OFSZ                        = $20
    DUR                         = $21
    LATENT                      = $22
    WINDOW                      = $23
    THRESH_ACT                  = $24
    THRESH_INACT                = $25
    TIME_INACT                  = $26
    ACT_INACT_CTL               = $27
    THRESH_FF                   = $28
    TAP_AXES                    = $2A
    ACT_TAP_STATUS              = $2B
    BW_RATE                     = $2C
    POWER_CTL                   = $2D
    INT_ENABLE                  = $2E
    INT_MAP                     = $2F
    INT_SOURCE                  = $30
    DATA_FORMAT                 = $31
    DATAX0                      = $32
    DATAX1                      = $33
    DATAY0                      = $34
    DATAY1                      = $35
    DATAZ0                      = $36
    DATAZ1                      = $37
    FIFO_CTL                    = $38
    FIFO_STATUS                 = $39


PUB Null
' This is not a top-level object
