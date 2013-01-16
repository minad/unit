# -*- coding: utf-8 -*-
class Unit < Numeric
  attr_reader :value, :normalized, :unit, :system

  class IncompatibleUnitError < TypeError; end

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
    if Numeric === other
      other = coerce_numeric(other)
      Unit.new(other.value * self.value, other.unit + self.unit, system)
    else
      apply_through_coercion(other, __method__)
    end
  end

  def /(other)
    if Numeric === other
      other = coerce_numeric(other)
      result = if Integer === value && Integer === other.value
                 other.value == 1 ? value : Rational(value, other.value)
               else
                 value / other.value
               end
      Unit.new(result, unit + Unit.power_unit(other.unit, -1), system)
    else
      apply_through_coercion(other, __method__)
    end
  end

  def +(other)
    if Numeric === other
      other = coerce_numeric_compatible(other)
      a, b = self.normalize, other.normalize
      Unit.new(a.value + b.value, b.unit, system).in(self)
    else
      apply_through_coercion(other, __method__)
    end
  end

  def **(exp)
    raise TypeError if Unit === exp
    Unit.new(value ** exp, Unit.power_unit(unit, exp), system)
  end

  def -(other)
    if Numeric === other
      other = coerce_numeric_compatible(other)
      a, b = self.normalize, other.normalize
      Unit.new(a.value - b.value, b.unit, system).in(self)
    else
      apply_through_coercion(other, __method__)
    end
  end

  def -@
    Unit.new(-value, unit, system)
  end

  def abs
    Unit.new(value.abs, unit, system)
  end

  def zero?
    value.zero?
  end

  def ==(other)
    if Numeric === other
      other = coerce_numeric(other)
      a, b = self.normalize, other.normalize
      a.value == b.value && a.unit == b.unit
    else
      apply_through_coercion(other, __method__)
    end
  end

  def eql?(other)
    Unit === other && value.eql?(other.value) && unit == other.unit
  end

  def <=>(other)
    if Numeric === other
      other = coerce_numeric_compatible(other)
      a, b = self.normalize, other.normalize
      a.value <=> b.value
    else
      apply_through_coercion(other, __method__)
    end
  end

  # Number without dimension
  def dimensionless?
    normalize.unit.empty?
  end

  alias_method :unitless?, :dimensionless?

  # Compatible units can be added
  def compatible?(other)
    self.normalize.unit == Unit.to_unit(other, system).normalize.unit
  end

  alias_method :compatible_with?, :compatible?

  # Convert to other unit
  def in(unit)
    conversion = Unit.new(1, Unit.to_unit(unit, system).unit, system)
    (self / conversion).normalize * conversion
  end

  def in!(unit)
    unit = coerce_object(unit)
    result = self.in(unit)
    unless result.unit == unit.unit
      raise TypeError, "Unexpected #{result.inspect}, expected to be in #{unit.unit_string}"
    end
    result
  end

  def inspect
    unit.empty? ? %{Unit("#{value}")} : %{Unit("#{value} #{unit_string('.')}")}
  end

  def to_s
    unit.empty? ? value.to_s : "#{value} #{unit_string}"
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
    Unit.new(self.to_f, unit, system)
  end

  def round(precision = 0)
    Unit.new(value.round(precision), unit, system)
  end

  def coerce(other)
    [coerce_numeric(other), self]
  end

  def unit_string(sep = '·')
    (unit_list(@unit.select {|factor, name, exp| exp >= 0 }) +
     unit_list(@unit.select {|factor, name, exp| exp < 0 })).join(sep)
  end

  private

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
    @unit.each_with_index do |(factor1, _, exp1), k|
      if exp1 > 0
        @unit.each_with_index do |(factor2, _, exp2), j|
          if exp2 == -exp1
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
    end

    self
  end

  # Given another object and an operator, use the other object's #coerce method
  # to perform the operation.
  #
  # Based on Matrix#apply_through_coercion
  def apply_through_coercion(obj, oper)
    coercion = obj.coerce(self)
    raise TypeError unless coercion.is_a?(Array) && coercion.length == 2
    first, last = coercion
    first.send(oper, last)
  rescue
    raise TypeError, "#{obj.class} can't be coerced into #{self.class}"
  end

  def coerce_numeric_compatible(object)
    object = coerce_numeric(object)
    raise IncompatibleUnitError, "#{inspect} and #{object.inspect} are incompatible" if !compatible?(object)
    object
  end

  def coerce_numeric(object)
    Unit.numeric_to_unit(object, system)
  end

  def coerce_object(object)
    Unit.to_unit(object, system)
  end

  class << self
    attr_accessor :default_system

    def power_unit(unit, pow)
      unit.map {|factor, name, exp| [factor, name, exp * pow] }
    end

    def numeric_to_unit(object, system = nil)
      system ||= Unit.default_system
      case object
      when Unit
        raise IncompatibleUnitError, "Unit system of #{object.inspect} is incompatible with #{system.name}" if object.system != system
        object
      when Numeric
        Unit.new(object, [], system)
      else
        raise TypeError, "#{object.class} can't be coerced into Unit"
      end
    end

    def to_unit(object, system = nil)
      system ||= Unit.default_system
      case object
      when String, Symbol
        unit = system.parse_unit(object.to_s)
        system.validate_unit(unit)
        Unit.new(1, unit, system)
      when Array
        system.validate_unit(object)
        Unit.new(1, object, system)
      else
        numeric_to_unit(object, system)
      end
    end
  end
end
