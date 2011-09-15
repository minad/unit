require 'units'

class Object
  def to_si
    to_unit(Unit::System::SI)
  end

  def si(s)
    unit(s, Unit::System::SI)
  end
end

def SI(*args)
  Unit(*args)
end
