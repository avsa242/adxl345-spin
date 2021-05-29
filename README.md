# adxl345-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Analog Devices ADXL345 3DoF accelerometer.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection at up to 400kHz, SPI connection (4-wire) at up to 1MHz (P1), ~5MHz (P2)
* Read raw accelerometer data, or data in micro-g's
* Change operating mode (standby, measure)
* Data ready and overrun flags
* 10-bit and 'full' sensor ADC resolution supported
* Set interrupt mask
* Set output data rate
* Set full-scale range

## Requirements

P1/SPIN1:
* spin-standard-library
* 1 extra core/cog for the PASM SPI engine

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FlexSpin (tested with 5.5.0)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction, or outright fail to build
* SPI mode only supports 4-wire SPI connected chips

## TODO

- [x] Add calibration/offset support
- [ ] Add explicit sleep and auto-sleep support
- [ ] Add low-power mode support
- [ ] Add 3-wire SPI support
- [x] Add I2C support
- [ ] Expand FIFO support (currently, FIFO modes can be enabled, but no specific FIFO handling exists)
- [x] Add support for tap and double-tap detection
- [ ] Add support for free-fall detection
- [ ] Add support activity and inactivity detection
