require 'set'

class SortedPairSet
  include Enumerable

  def initialize
    @pairs = []
  end

  def add(pair)
    @pairs << pair
    @pairs.sort_by! { |p| p[:index] }
  end

  def each(&block)
    @pairs.each(&block)
  end

  def to_a
    @pairs
  end
end
