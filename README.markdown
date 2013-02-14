README
===
**Unit** introduces computational units to Ruby. It offers built-in support for binary, mathematical, SI, imperial, scientific and temporal units, and a simple interface for adding your own, custom units.

[![Gem Version](https://badge.fury.io/rb/unit.png)](http://badge.fury.io/rb/unit) [![Dependency Status](https://gemnasium.com/minad/unit.png)](https://gemnasium.com/minad/unit) [![Build Status](https://secure.travis-ci.org/minad/unit.png?branch=master)](http://travis-ci.org/minad/unit) [![Code Climate](https://codeclimate.com/github/minad/unit.png)](https://codeclimate.com/github/minad/unit)

- Define units for operands to avoid the inevitable mistakes that plague unit-less operations.
- Perform complex mathematical operations while respecting the units of each operand.
- Get meaningful errors when units aren't compatible.
- Convert values between different systems of units with ease.

Examples
===
### General Usage

    require 'unit'
    puts 1.meter.in_kilometer
    puts 1.MeV.in_joule
    puts 10.KiB / 1.second
    puts 10.KiB_per_second
    puts Unit('1 m/s^2')

### Mathematics

    Unit(1, 'km') + Unit(500, 'm') == Unit(1.5, 'km')
    Unit(1, 'kg') - Unit(500, 'g') == Unit(0.5, 'kg')
    Unit(100, 'miles/hour') * Unit(0.5, 'hours') == Unit('50 mi')
    Unit(5.5, 'feet') / 2 == Unit(2.75, 'feet')
    Unit(2, 'm') ** 2 == Unit(4, 'm^2')

### Conversions

    Unit(1, 'mile').in('km') == Unit(1.609344,  'km')
    (Unit(10, 'A') * Unit(0.1, 'volt')).in('watts') == Unit(1, 'watt')

See the test cases for many more examples.

Maintainers
---
Daniel Mendler and [Chris Cashwell](https://github.com/ccashwell)

