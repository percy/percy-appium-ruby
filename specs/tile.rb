# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../percy/lib/tile'

# Test suite for the Percy::Tile class.
class TileTest < Minitest::Test
  def setup
    @tile = Percy::Tile.new(20, 120, 150, 0, filepath: 'some-file-path', sha: 'some-sha')
    @hash_tile = @tile.to_h
  end

  def test_tile_hash_keys
    assert_equal @hash_tile, @tile.to_h
    assert_includes @hash_tile, 'filepath'
    assert_includes @hash_tile, 'status_bar_height'
    assert_includes @hash_tile, 'nav_bar_height'
    assert_includes @hash_tile, 'header_height'
    assert_includes @hash_tile, 'footer_height'
    assert_includes @hash_tile, 'fullscreen'
    assert_includes @hash_tile, 'sha'
  end

  def test_tile_values
    assert_equal 'some-file-path', @hash_tile['filepath']
    assert_equal 20, @hash_tile['status_bar_height']
    assert_equal 120, @hash_tile['nav_bar_height']
    assert_equal 150, @hash_tile['header_height']
    assert_equal 0, @hash_tile['footer_height']
    assert_equal 'some-sha', @hash_tile['sha']
    assert_equal false, @hash_tile['fullscreen'] # Default
  end
end
