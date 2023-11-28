require 'minitest/autorun'
require 'minitest/mock'
require_relative '../percy/metadata/android_metadata'
require_relative '../percy/metadata/ios_metadata'
require_relative '../percy/metadata/metadata_resolver'

class MetadataResolverTestCase < Minitest::Test
  def setup
    @mock_webdriver = Minitest::Mock.new
  end

  def test_android_resolved
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'Android' })
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'Android' })
    resolved_metadata = MetadataResolver.resolve(@mock_webdriver)

    assert_instance_of(AndroidMetadata, resolved_metadata)
    @mock_webdriver.verify
  end

  def test_ios_resolved
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'iOS' })
    resolved_metadata = MetadataResolver.resolve(@mock_webdriver)

    assert_instance_of(IOSMetadata, resolved_metadata)
    @mock_webdriver.verify
  end

  def test_unknown_platform_exception
    @mock_webdriver.expect(:capabilities, { 'platformName' => 'Something Random' })

    assert_raises(Exception) do
      MetadataResolver.resolve(@mock_webdriver)
    end

    @mock_webdriver.verify
  end
end
