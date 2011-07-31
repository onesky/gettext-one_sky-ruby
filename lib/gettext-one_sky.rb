require 'gettext'
require 'one_sky'
require 'gettext-one_sky/rails/railtie.rb' if defined? Rails

module GetText
  module OneSky
    autoload :SimpleClient, 'gettext-one_sky/simple_client'
    class DefaultLocaleMismatchError < StandardError; end
  end
end
