# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/mock'
require_relative '../percy/metadata/android_metadata'
require_relative '../percy/metadata/ios_metadata'
require_relative '../percy/metadata/metadata_resolver'

# Test suite for the Percy::MetadataResolver class
class MetadataResolverTestCase < Minitest::Test
  def setup
    @mock_webdriver = Minitest::Mock.new
  end

  def test_android_resolved
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'Android' })
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'Android' })
    resolved_metadata = Percy::MetadataResolver.resolve(@mock_webdriver)

    assert_instance_of(Percy::AndroidMetadata, resolved_metadata)
    @mock_webdriver.verify
  end
  
  def test_android_resolved_with_PLATFORM_NAME
    @mock_webdriver.expect(:capabilities, { 'PLATFORM_NAME' => 'Android' })
    @mock_webdriver.expect(:capabilities, { 'PLATFORM_NAME' => 'Android' })
    resolved_metadata = Percy::MetadataResolver.resolve(@mock_webdriver)

    assert_instance_of(Percy::AndroidMetadata, resolved_metadata)
    @mock_webdriver.verify
  end

  def test_android_resolved_with_platform_name
    @mock_webdriver.expect(:capabilities, { 'platform_name' => 'Android' })
    @mock_webdriver.expect(:capabilities, { 'platform_name' => 'Android' })
    resolved_metadata = Percy::MetadataResolver.resolve(@mock_webdriver)

    assert_instance_of(Percy::AndroidMetadata, resolved_metadata)
    @mock_webdriver.verify
  end

  def test_ios_resolved
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'iOS' })
    resolved_metadata = Percy::MetadataResolver.resolve(@mock_webdriver)

    assert_instance_of(Percy::IOSMetadata, resolved_metadata)
    @mock_webdriver.verify
  end

  def test_ios_resolved_with_platform_name
    @mock_webdriver.expect(:capabilities, { 'platform_name' => 'iOS' })
    resolved_metadata = Percy::MetadataResolver.resolve(@mock_webdriver)

    assert_instance_of(Percy::IOSMetadata, resolved_metadata)
    @mock_webdriver.verify
  end

  def test_platformName_precedence_over_platform_name
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'Android', 'platform_name' => 'iOS' })
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'Android', 'platform_name' => 'iOS' })
    resolved_metadata = Percy::MetadataResolver.resolve(@mock_webdriver)

    assert_instance_of(Percy::AndroidMetadata, resolved_metadata)
    @mock_webdriver.verify
  end

  def test_unknown_platform_exception
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'Something Random' })

    assert_raises(Exception) do
      Percy::MetadataResolver.resolve(@mock_webdriver)
    end

    @mock_webdriver.verify
  end

  def test_unknown_platform_exception_with_platform_name
    @mock_webdriver.expect(:capabilities, { 'platform_name' => 'Something Random' })

    assert_raises(PlatformNotSupported) do
      Percy::MetadataResolver.resolve(@mock_webdriver)
    end

    @mock_webdriver.verify
  end
end
