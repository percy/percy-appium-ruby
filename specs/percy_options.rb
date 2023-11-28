require 'minitest/autorun'
require 'minitest/mock'
require_relative '../percy/lib/percy_options'

class TestPercyOptions < Minitest::Test
  def test_percy_options_not_provided # Defaults
    capabilities = {}
    percy_options = PercyOptions.new(capabilities)
    assert_equal true, percy_options.enabled
    assert_equal true, percy_options.ignore_errors
  end

  def test_percy_options_w3c_enabled
    capabilities = { 'percy:options' => { 'enabled' => true } }
    percy_options = PercyOptions.new(capabilities)
    assert_equal true, percy_options.enabled
    assert_equal true, percy_options.ignore_errors
  end

  def test_percy_options_json_wire_enabled
    capabilities = { 'percy.enabled' => true }
    percy_options = PercyOptions.new(capabilities)
    assert_equal true, percy_options.enabled
    assert_equal true, percy_options.ignore_errors
  end

  def test_percy_options_w3c_not_enabled
    capabilities = { 'percy:options' => { 'enabled' => false } }
    percy_options = PercyOptions.new(capabilities)
    assert_equal false, percy_options.enabled
    assert_equal true, percy_options.ignore_errors
  end

  def test_percy_options_json_wire_not_enabled
    capabilities = { 'percy.enabled' => false }
    percy_options = PercyOptions.new(capabilities)
    assert_equal false, percy_options.enabled
    assert_equal true, percy_options.ignore_errors
  end

  def test_percy_options_w3c_ignore_errors
    capabilities = { 'percy:options' => { 'ignoreErrors' => true } }
    percy_options = PercyOptions.new(capabilities)
    assert_equal true, percy_options.ignore_errors
    assert_equal true, percy_options.enabled
  end

  def test_percy_options_json_wire_ignore_errors
    capabilities = { 'percy.ignoreErrors' => true }
    percy_options = PercyOptions.new(capabilities)
    assert_equal true, percy_options.ignore_errors
    assert_equal true, percy_options.enabled
  end

  def test_percy_options_w3c_not_ignore_errors
    capabilities = { 'percy:options' => { 'ignoreErrors' => false } }
    percy_options = PercyOptions.new(capabilities)
    assert_equal false, percy_options.ignore_errors
    assert_equal true, percy_options.enabled
  end

  def test_percy_options_json_wire_not_ignore_errors
    capabilities = { 'percy.ignoreErrors' => false }
    percy_options = PercyOptions.new(capabilities)
    assert_equal false, percy_options.ignore_errors
    assert_equal true, percy_options.enabled
  end

  def test_percy_options_w3c_all_options_false
    capabilities = { 'percy:options' => { 'ignoreErrors' => false, 'enabled' => false } }
    percy_options = PercyOptions.new(capabilities)
    assert_equal false, percy_options.ignore_errors
    assert_equal false, percy_options.enabled
  end

  def test_percy_options_json_wire_all_options_false
    capabilities = { 'percy.ignoreErrors' => false, 'percy.enabled' => false }
    percy_options = PercyOptions.new(capabilities)
    assert_equal false, percy_options.ignore_errors
    # assert_equal false, percy_options.enabled
  end

  def test_percy_options_w3c_all_options_true
    capabilities = { 'percy:options' => { 'ignoreErrors' => true, 'enabled' => true } }
    percy_options = PercyOptions.new(capabilities)
    assert_equal true, percy_options.ignore_errors
    assert_equal true, percy_options.enabled
  end

  def test_percy_options_json_wire_all_options_true
    capabilities = { 'percy.ignoreErrors' => true, 'percy.enabled' => true }
    percy_options = PercyOptions.new(capabilities)
    assert_equal true, percy_options.ignore_errors
    assert_equal true, percy_options.enabled
  end

  def test_percy_options_json_wire_and_w3c_case_1
    capabilities = { 'percy.ignoreErrors' => false, 'percy:options' => { 'enabled' => false } }
    percy_options = PercyOptions.new(capabilities)
    assert_equal false, percy_options.ignore_errors
    assert_equal false, percy_options.enabled
  end

  def test_percy_options_json_wire_and_w3c_case_2
    capabilities = { 'percy.enabled' => false, 'percy:options' => { 'ignoreErrors' => false } }
    percy_options = PercyOptions.new(capabilities)
    assert_equal false, percy_options.ignore_errors
    assert_equal false, percy_options.enabled
  end
end
