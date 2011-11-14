# -*- coding: utf-8 -*-
class Unit < Numeric
  attr_reader :value, :normalized, :unit, :system

  def initialize(value, unit, system)
    @system = system
    @value = value
    @unit = unit.dup
    @normalized = nil
    reduce!
  end

  def initialize_copy(other)
    @system = other.system
    @value = other.value
    @unit = other.unit.dup
    @normalized = other.normalized
  end

  # Converts to base units
  def normalize
    @normalized ||= dup.normalize!
  end

  # Converts to base units
  def normalize!
    if @normalized != self
      begin
        last_unit = @unit
        @unit = []
        last_unit.each do |factor, unit, exp|
          @value *= @system.factor[factor][:value] ** exp if factor != :one
          if Numeric === unit
            @unit << [:one, unit, exp]
          else
            @unit += Unit.power_unit(@system.unit[unit][:def], exp)
          end
        end
      end while last_unit != @unit
      reduce!
      @normalized = self
    end
    self
  end

  def *(other)
    a, b = coerce(other)
    Unit.new(a.value * b.value, a.unit + b.unit, system)
  end

  def /(other)
    a, b = coerce(other)
    Unit.new(Integer === a.value && Integer === b.value ? Rational(a.value, b.value) : a.value / b.value,
             a.unit + Unit.power_unit(b.unit, -1), system)
  end

  def +(other)
    raise TypeError, "Incompatible units: #{self.inspect} and #{other.inspect}" if !compatible?(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    Unit.new(a.value + b.value, a.unit, system).in(self)
  end

  def **(exp)
    raise TypeError if Unit === exp
    Unit.new(value ** exp, Unit.power_unit(unit, exp), system)
  end

  def -(other)
    self + (-other)
  end

  def -@
    Unit.new(-value, unit, system)
  end

  def ==(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    a.value == b.value && a.unit == b.unit
  end

  def <=>(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    a.value <=> b.value if a.unit == b.unit
  end

  # Number without dimension
  def dimensionless?
    normalize.unit.empty?
  end

  alias unitless? dimensionless?

  # Compatible units can be added
  def compatible?(other)
    a, b = coerce(other)
    a, b = a.normalize, b.normalize
    a.unit == b.unit
  end

  alias compatible_with? compatible?

  # Convert to other unit
  def in(unit)
    a, b = coerce(unit)
    conversion = Unit.new(1, b.unit, system)
    (a / conversion).normalize * conversion
  end

  def inspect
    unit.empty? ? %{Unit("#{value}")} : %{Unit("#{value} #{unit_string('.')}")}
  end

  def to_s
    unit.empty? ? value.to_s : "#{value} #{unit_string('·')}"
  end

  def to_tex
    unit.empty? ? value.to_s : "\SI{#{value}}{#{unit_string('.')}}"
  end

  def to_i
    @value.to_i
  end

  def to_f
    @value.to_f
  end

  def approx
    to_f.unit(unit)
  end

  def coerce(val)
    [self, Unit.to_unit(val, system)]
  end

  def self.to_unit(object, system = nil)
    system ||= Unit.default_system
    case object
    when Unit
      raise TypeError, 'Different unit system' if object.system != system
      object
    when Array
      system.validate_unit(object)
      Unit.new(1, object, system)
    when String, Symbol
      unit = system.parse_unit(object.to_s)
      system.validate_unit(unit)
      Unit.new(1, unit, system)
    when Numeric
      Unit.new(object, [], system)
    else
      raise TypeError, "#{object.class} has no unit support"
    end
  end

  private

  def unit_string(sep)
    (unit_list(@unit.select {|factor, name, exp| exp >= 0 }) +
     unit_list(@unit.select {|factor, name, exp| exp < 0 })).join(sep)
  end

  def unit_list(list)
    units = []
    list.each do |factor, name, exp|
      unit = ''
      unit << @system.factor[factor][:symbol] if factor != :one
      unit << @system.unit[name][:symbol]
      unit << '^' << exp.to_s if exp != 1
      units << unit
    end
    units.sort
  end

  def self.power_unit(unit, pow)
    unit.map {|factor, name, exp| [factor, name, exp * pow] }
  end

  # Reduce units and factors
  def reduce!
    # Remove numbers from units
    numbers = @unit.select {|factor, unit, exp| Numeric === unit }
    @unit -= numbers
    numbers.each do |factor, number, exp|
       raise RuntimeError, 'Numeric unit with factor' if factor != :one
       @value *= number ** exp
    end

    # Reduce units
    @unit.sort!
    i, current = 1, 0
    while i < @unit.size do
      while i < @unit.size && @unit[current][0] == @unit[i][0] && @unit[current][1] == @unit[i][1]
        @unit[current] = @unit[current].dup
        @unit[current][2] += @unit[i][2]
        i += 1
      end
      if @unit[current][2] == 0
        @unit.slice!(current, i - current)
      else
        @unit.slice!(current + 1, i - current - 1)
        current += 1
      end
      i = current + 1
    end

    # Reduce factors
    @unit.each_with_index do |(factor1, unit1, exp1), k|
      next if exp1 < 0
      @unit.each_with_index do |(factor2, unit2, exp2), j|
        if exp2 < 0 && exp2 == -exp1
          q, r = @system.factor[factor1][:value].divmod @system.factor[factor2][:value]
          if r == 0 && new_factor = @system.factor_value[q]
            @unit[k] = @unit[k].dup
            @unit[j] = @unit[j].dup
            @unit[k][0] = new_factor
            @unit[j][0] = :one
          end
        end
      end
    end

    self
  end

  class<< self
    attr_accessor :default_system
  end
end
