# adxl345-spin 
--------------

This is a P8X32A/Propeller, P2X8C4M64P/Propeller 2 driver object for the Analog Devices ADXL345 3DoF accelerometer.

## Salient Features

* SPI connection at up to 1MHz (P1), 5MHz (P2)

## Requirements

* P1/SPIN1: 1 extra core/cog for the PASM SPI driver
* P2/SPIN2: N/A

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.0-beta)

## Limitations

* Very early in development - may malfunction, or outright fail to build

## TODO

- [ ] Task item 1
- [ ] Task item 2
