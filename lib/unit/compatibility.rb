# Units use symbols which must be sortable (Fix for Ruby 1.8)
unless :test.respond_to? :<=>
  class Symbol
    include Comparable
    def <=>(other)
      self.to_i <=> other.to_i
    end
  end
end
