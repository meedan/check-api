require 'rails_admin/config/fields/types/text'

module RailsAdmin
  module Config
    module Fields
      module Types
        class Yaml < RailsAdmin::Config::Fields::Types::Text
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :formatted_value do
            value.present? ? YAML.load(value) : nil
          end

          def parse_value(value)
            value.present? ? YAML.load(value) : nil
          end

          def parse_input(params)
            params[name] = parse_value(params[name]) if params[name].is_a?(::String)
          end

        end
      end
    end
  end
end
