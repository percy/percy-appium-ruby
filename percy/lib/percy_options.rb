class PercyOptions
  IGNORE_ERRORS = 'ignoreErrors'
  ENABLED = 'enabled'
  PERCY_OPTIONS = ['percy:options', 'percyOptions']

  def initialize(capabilities)
    @capabilities = capabilities
    @percy_options = _parse_percy_options || {}
  end

  def _parse_percy_options
    options = PERCY_OPTIONS.map { |key| @capabilities.fetch(key, nil) }
    options = options[0] || options[1] if options.any?

    if options
      options[IGNORE_ERRORS] = @capabilities.fetch("percy.#{IGNORE_ERRORS}", true) unless options.key?(IGNORE_ERRORS)
      options[ENABLED] = @capabilities.fetch("percy.#{ENABLED}", true) unless options.key?(ENABLED)
    end

    options
  end

  def ignore_errors
    @percy_options.fetch(IGNORE_ERRORS, true)
  end

  def enabled
    @percy_options.fetch(ENABLED, true)
  end
end

