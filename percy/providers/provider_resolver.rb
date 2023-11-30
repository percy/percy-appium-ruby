require_relative '../exceptions/exceptions'
require_relative '../metadata/metadata_resolver'
require_relative 'app_automate'
require_relative 'generic_provider'

class ProviderResolver
  def self.resolve(driver)
    metadata = MetadataResolver.resolve(driver)
    providers = [AppAutomate, GenericProvider]
    providers.each do |provider|
      return provider.new(driver, metadata) if provider.supports(metadata.remote_url)
    end
    raise UnknownProvider
  end
end