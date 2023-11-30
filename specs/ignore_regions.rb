require 'minitest/autorun'
require_relative '../percy/lib/ignore_region'

class TestIgnoreRegion < Minitest::Test
  def test_ignore_region_valid_input
    top = 10
    bottom = 20
    left = 30
    right = 40
    ignore_region = IgnoreRegion.new(top, bottom, left, right)

    assert_equal ignore_region.top, top
    assert_equal ignore_region.bottom, bottom
    assert_equal ignore_region.left, left
    assert_equal ignore_region.right, right
  end

  def test_ignore_region_negative_input
    assert_raises(ArgumentError) { IgnoreRegion.new(-10, 20, 30, 40) }
    assert_raises(ArgumentError) { IgnoreRegion.new(10, 20, -30, 40) }
    assert_raises(ArgumentError) { IgnoreRegion.new(10, 20, 30, -40) }
    assert_raises(ArgumentError) { IgnoreRegion.new(-10, -20, -30, -40) }
  end

  def test_ignore_region_invalid_input
    assert_raises(ArgumentError) { IgnoreRegion.new(20, 10, 30, 40) } # bottom < top
    assert_raises(ArgumentError) { IgnoreRegion.new(10, 20, 40, 30) } # right < left
  end

  def test_ignore_region_is_valid
    ignore_region = IgnoreRegion.new(10, 20, 30, 40)
    screen_height = 100
    screen_width = 200
    assert_equal true, ignore_region.valid?(screen_height, screen_width)

    ignore_region = IgnoreRegion.new(10, 200, 30, 400)
    height = 100
    width = 200
    assert_equal false, ignore_region.valid?(height, width)

    ignore_region = IgnoreRegion.new(10, 20, 30, 40)
    screen_height = 5
    screen_width = 10
    assert_equal false, ignore_region.valid?(screen_height, screen_width)
  end
end
