# Example test class for coercion
#
# UnitOne behaves as Unit(1) when added to a Unit, and as 1 when added to anything else.
class UnitOne < Numeric
  def coerce(other)
    case other
    when Unit
      [other, Unit(1)]
    else
      [other, 1]
    end
  end

  def +(other)
    apply_through_coercion(other, __method__)
  end

  def -(other)
    apply_through_coercion(other, __method__)
  end

  def /(other)
    apply_through_coercion(other, __method__)
  end

  def *(other)
    apply_through_coercion(other, __method__)
  end

  def ==(other)
    1 == other
  end

  def eql?(other)
    1.eql?(other)
  end

  private

  def apply_through_coercion(other, operation)
    case other
    when Unit
      a, b = other.coerce(Unit(1))
    else
      a, b = other.coerce(1)
    end

    a.send(operation, b)
  end
end
