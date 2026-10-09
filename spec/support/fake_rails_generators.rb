# frozen_string_literal: true

# A stand-in for the part of Rails::Generators::Base the skills generator uses, so the generator can be
# exercised without depending on Rails. Loaded only by the generator spec.
unless defined?(Rails::Generators::Base)
  module Rails
    module Generators
      class Base
        class << self
          def desc(text = nil) = (@desc = text if text) || @desc

          def class_option(name, **config) = (options_config[name] = config)

          def options_config = (@options_config ||= {})
        end

        attr_reader :destination_root, :options, :statuses

        def initialize(destination_root:, **options)
          @destination_root = destination_root
          @options = self.class.options_config.transform_values { |c| c[:default] }.merge(options)
          @statuses = []
        end

        def say_status(status, message, color = nil) = @statuses << [status.to_s, message, color]

        def invoke_all = self.class.instance_methods(false).each { |m| public_send(m) }
      end
    end
  end

  $LOADED_FEATURES << "rails/generators.rb"
end
