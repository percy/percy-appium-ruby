# frozen_string_literal: true

# lib/region.rb
module Percy
  class Region
    attr_accessor :top, :bottom, :left, :right

    def initialize(top, bottom, left, right)
      raise ArgumentError, 'Only Positive integer is allowed!' if [top, bottom, left, right].any?(&:negative?)
      raise ArgumentError, 'Invalid ignore region parameters!' if top >= bottom || left >= right

      @top = top
      @bottom = bottom
      @left = left
      @right = right
    end

    def valid?(screen_height, screen_width)
      return false if @top >= screen_height || @bottom > screen_height || @left >= screen_width || @right > screen_width

      true
    end
  end
end
