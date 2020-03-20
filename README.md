# adxl345-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Analog Devices ADXL345 3DoF accelerometer.

## Salient Features

* SPI connection (4-wire) at up to 1MHz (P1), ~600kHz (P2)
* Read Device ID
* Read raw accelerometer data, or data in micro-g's
* Change operating mode (standby, measure)
* Data ready and overrun flags
* 10-bit and 'full' sensor ADC resolution supported
* Set interrupt mask
* Set output data rate
* Set full-scale range

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM SPI driver
* P2/SPIN2: N/A

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.4-beta; some earlier versions do not work correctly)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* Only supports 4-wire SPI connected chips
* P2 driver limited in bus speed due to difficulties with available SPI engines

## TODO

- [x] Add calibration/offset support
- [ ] Add explicit sleep and auto-sleep support
- [ ] Add low-power mode support
- [ ] Add 3-wire SPI driver variant
- [ ] Add I2C driver variant
- [ ] Expand FIFO support (currently, FIFO modes can be enabled, but no specific FIFO handling exists)
- [ ] Add support for tap and double-tap detection
- [ ] Add support activity and inactivity detection
