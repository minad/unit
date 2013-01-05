README
======

Units introduces computation with units to ruby.

[![Build Status](https://secure.travis-ci.org/minad/unit.png?branch=master)](http://travis-ci.org/minad/unit)[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/minad/unit)

Usage
-----

    require 'unit'
    puts 1.meter.in_kilometer
    puts 1.MeV.in_joule
    puts 10.KiB / 1.second
    puts 10.KiB_per_second
    puts Unit('1 m/s^2')

See the test cases for more examples.

Authors
-------

Daniel Mendler
