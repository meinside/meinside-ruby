# coding: UTF-8

# lib/my_gpio.rb
# 
# wrapper class for WiringPi::GPIO
# (https://github.com/WiringPi/WiringPi-Ruby/blob/master/lib/wiringpi.rb)
# 
# created on : 2012.09.03
# last update: 2013.08.23
# 
# by meinside@gmail.com

require 'wiringpi'

# GPIO helper class for Raspberry Pi
class MyGPIO

  # default gap between loops
  DEFAULT_LOOP_GAP = 0.1

  # @param mode [WPI_MODE_PINS, WPI_MODE_GPIO, WPI_MODE_SYS] pin mode
  def initialize(mode = WPI_MODE_PINS)
    @gpio = WiringPi::GPIO.new(mode)

    yield self if block_given?
  end

  # call WiringPi::GPIO's methods directly
  def method_missing(method, *args, &block)
    @gpio.send(method, *args, &block)
  end

  # loop with given block and gap
  # @param proc [Proc] 
  # @param gap [Fixnum] 
  # @note Usage:
  #  MyGPIO.new.loop(lambda{|io|
  #   # do something constantly with @io
  #  })
  def loop(proc, gap = DEFAULT_LOOP_GAP)
    while true
      proc.call(@gpio)
      sleep gap
    end
  end

end

