# -*- coding: utf-8 -*-
class Unit < Numeric
  attr_reader :value, :normalized, :unit, :system

  class ParseError < ArgumentError; end
  class IncompatibleUnitError < TypeError; end

  def initialize(value, unit, system)
    @system = system
    @value = value
    @unit = unit.dup
    @normalized = nil
    reduce!
  end

  # Numeric and its subclasses are treated as immutable value objects, so
  # Ruby's Numeric#dup/#clone return self. Unit mutates @value and @unit in
  # place (see #normalize! and #reduce!), so it needs genuine copies; allocate
  # a fresh instance and copy state into it explicitly.
  def dup
    self.class.allocate.tap { |copy| copy.send(:initialize_copy, self) }
  end

  def initialize_copy(other)
    @system = other.system
    @value = other.value
    @unit = other.unit.map(&:dup)
    @normalized = other.normalized
  end

  # Pre-populate +@normalized+ before locking the object.
  #
  # +Unit+ is a +Numeric+ subclass, so Ruby treats it as an immutable value
  # object. The lazy +@normalized ||=+ in +normalize+ would raise +FrozenError+
  # on the first comparison call if the instance were frozen first; calling
  # +normalize+ here ensures the ivar is already set when +super+ seals it.
  def freeze
    normalize
    super
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

  # Returns +false+ if the value is a +Complex+ with a non-zero imaginary
  # part, +true+ otherwise. Overrides +Numeric#real?+ which unconditionally
  # returns +true+.
  def real?
    value.real?
  end

  # Returns the real part of +self+ as a +Unit+. For real-valued units
  # returns +self+; for complex-valued units returns a new unit wrapping
  # the real component.
  def real
    return self if value.real?
    Unit.new(value.real, unit, system)
  end

  # Returns the imaginary part of +self+ as a +Unit+. For real-valued
  # units returns +0+ (matching +Numeric#imag+); for complex-valued units
  # returns a new unit wrapping the imaginary component.
  def imag
    return 0 if value.real?
    Unit.new(value.imag, unit, system)
  end
  alias imaginary imag

  # Returns the complex conjugate of +self+ with the unit preserved. For
  # real-valued units returns +self+ (matching +Numeric#conj+); for
  # complex-valued units negates the imaginary part.
  def conj
    return self if value.real?
    Unit.new(value.conj, unit, system)
  end
  alias conjugate conj

  # Returns a two-element array <tt>[real, imaginary]</tt> with the unit
  # preserved on each component. For real-valued units returns
  # <tt>[self, 0]</tt> (matching +Numeric#rect+).
  def rect
    [real, imag]
  end
  alias rectangular rect

  def zero?
    value.zero?
  end

  # Returns the float-valued quotient of +self+ and +other+, with the unit
  # dimension preserved (for compatible units, the result is dimensionless).
  # Unlike +Numeric#fdiv+, this does not strip the unit from +self+ before
  # dividing.
  def fdiv(other)
    (self / other).approx
  end

  # Returns the remainder after dividing +self+ by +other+. The result has
  # the same sign as +self+ (the dividend). Contrast with +modulo+/+%+,
  # whose result has the same sign as +other+ (the divisor).
  def remainder(other)
    self - (self / other).truncate * other
  end

  # Converts +self+ to a +Rational+. Raises +RangeError+ for dimensional
  # units (e.g. metres), following the same precedent as +Complex#to_r+
  # which raises when the imaginary part is non-zero. Use +value.to_r+ to
  # extract the bare rational without a dimension check.
  #
  # Defining +to_r+ gives +numerator+ and +denominator+ for free via
  # +Numeric#numerator+ / +Numeric#denominator+, which are both
  # implemented as <tt>self.to_r.numerator</tt> etc.
  def to_r
    raise RangeError, "can't convert #{self} into Rational" unless unit.empty?
    @value.to_r
  end

  # Returns +true+ if +self+ is greater than 0, +false+ otherwise.
  def positive?
    value.positive?
  end

  # Returns +true+ if +self+ is less than 0, +false+ otherwise.
  def negative?
    value.negative?
  end

  # Returns +true+ if +self+ is not +Infinity+, +-Infinity+, or +NaN+,
  # +false+ otherwise. Integer and Rational values are always finite.
  def finite?
    value.respond_to?(:finite?) ? value.finite? : true
  end

  # Returns +1+ if +self+ is +Infinity+, +-1+ if +-Infinity+, or +nil+
  # otherwise. Integer and Rational values are never infinite.
  def infinite?
    value.respond_to?(:infinite?) ? value.infinite? : nil
  end

  # Returns +false+ for any object that is neither +Numeric+ nor coerceable,
  # rather than raising. This keeps mixed-type equality checks safe (e.g.
  # comparing against +nil+, strings, or arbitrary objects).
  def ==(other)
    if Numeric === other
      other = coerce_numeric(other)
      a, b = self.normalize, other.normalize
      a.value == b.value && a.unit == b.unit
    elsif other.respond_to?(:coerce)
      apply_through_coercion(other, __method__)
    else
      false
    end
  end

  def eql?(other)
    Unit === other && value.eql?(other.value) && unit == other.unit
  end

  def hash
    [self.class, value, unit].hash
  end

  # Raises +ArgumentError+ when both operands are +Numeric+ but have
  # incompatible dimensions (e.g. metres vs seconds); returns +nil+ for
  # non-+Numeric+, non-coerceable objects. This split honours Ruby's +<=>+
  # contract (return +nil+ for incomparable types) while still surfacing
  # dimension mismatches loudly through every comparison operator.
  def <=>(other)
    if Numeric === other
      coerced = coerce_numeric(other)
      unless compatible?(coerced)
        raise ArgumentError,
          "comparison of #{comparison_label(self)} with #{comparison_label(other)} failed"
      end
      a, b = self.normalize, coerced.normalize
      a.value <=> b.value
    elsif other.respond_to?(:coerce)
      apply_through_coercion(other, __method__)
    else
      nil
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

  # Converts +self+ to +unit+ and returns the bare numeric value, dropping
  # the dimension. Builds on +#in!+, so a dimensionally incompatible +unit+
  # raises +TypeError+ rather than returning a coerced number with residual
  # units.
  #
  #   Unit(1, "kilometer").value_in("meter")  # => 1000
  #   Unit(1, "meter").value_in("volt")       # raises TypeError
  def value_in(unit)
    in!(unit).value
  end

  def inspect
    unit.empty? ? %{Unit("#{value}")} : %{Unit("#{value_string} #{unit_string('.')}")}
  end

  def to_s
    unit.empty? ? value.to_s : "#{value_string} #{unit_string}"
  end

  def to_tex
    unit.empty? ? value.to_s : "\SI{#{value}}{#{unit_string('.')}}"
  end

  # Returns the value as an Integer. Raises +RangeError+ if +self+ has a
  # physical dimension (e.g. metres), mirroring the behaviour of
  # <tt>Complex#to_i</tt> when the imaginary part is non-zero.
  # Use <tt>value.to_i</tt> to extract the bare number without the check.
  def to_i
    raise RangeError, "can't convert #{self} into Integer" unless unit.empty?
    @value.to_i
  end

  # Returns the value as a Float. Raises +RangeError+ if +self+ has a
  # physical dimension (e.g. metres), mirroring the behaviour of
  # <tt>Complex#to_f</tt> when the imaginary part is non-zero.
  # Use <tt>value.to_f</tt> to extract the bare number without the check.
  def to_f
    raise RangeError, "can't convert #{self} into Float" unless unit.empty?
    @value.to_f
  end

  # Returns a new Unit with the value approximated as a +Float+, preserving
  # the unit dimension. Useful for displaying Rational-valued units as decimals.
  def approx
    Unit.new(@value.to_f, unit, system)
  end

  # Returns a Unit that is a "ceiling" value for +self+, as specified by
  # +ndigits+. When +ndigits+ is positive, the result has +ndigits+ decimal
  # digits after the decimal point; when negative, the result has at least
  # <tt>ndigits.abs</tt> trailing zeros. The unit dimension is preserved.
  def ceil(ndigits = 0)
    Unit.new(value.ceil(ndigits), unit, system)
  end

  # Returns a Unit that is a "floor" value for +self+, as specified by
  # +ndigits+. When +ndigits+ is positive, the result has +ndigits+ decimal
  # digits after the decimal point; when negative, the result has at least
  # <tt>ndigits.abs</tt> trailing zeros. The unit dimension is preserved.
  def floor(ndigits = 0)
    Unit.new(value.floor(ndigits), unit, system)
  end

  # Returns +self+ truncated (toward zero) to a precision of +ndigits+
  # decimal digits. When +ndigits+ is positive, the result has +ndigits+
  # digits after the decimal point; when negative, the result has at least
  # <tt>ndigits.abs</tt> trailing zeros. The unit dimension is preserved.
  def truncate(ndigits = 0)
    Unit.new(value.truncate(ndigits), unit, system)
  end

  # Returns +self+ rounded to the nearest value with a precision of +ndigits+
  # decimal digits (default: 0). When +ndigits+ is negative, the result has
  # at least <tt>ndigits.abs</tt> trailing zeros. The unit dimension is
  # preserved. If the value is equidistant from the two candidates, the
  # +half:+ keyword controls rounding: <tt>:up</tt> (default, rounds away
  # from zero), <tt>:down</tt> (toward zero), or <tt>:even</tt>
  # (banker's rounding).
  def round(ndigits = 0, **opts)
    Unit.new(value.round(ndigits, **opts), unit, system)
  end

  def coerce(other)
    [coerce_numeric(other), self]
  end

  def value_string
    if Rational === value
      if value.denominator == 1
        value.numerator.to_s
      else
        value.inspect
      end
    else
      value.to_s
    end
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

  # Label an operand for a failed-comparison message. A dimensional unit keeps
  # its informative #inspect (Unit("1 m")); a dimensionless unit is just a
  # number — and a coerced bare numeric arrives wrapped as one — so it is
  # reported by its underlying numeric class, matching how core Ruby names the
  # operands of a failed comparison (and avoiding splatting an arbitrary
  # #inspect into the message).
  def comparison_label(operand)
    return operand.inspect if Unit === operand && !operand.unit.empty?
    operand = operand.value if Unit === operand
    operand.class
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
