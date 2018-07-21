require 'rails_admin/config/fields/types/text'

module RailsAdmin
  module Config
    module Fields
      module Types
        class Yaml < RailsAdmin::Config::Fields::Types::Text
          RailsAdmin::Config::Fields::Types.register(self)

          register_instance_option :formatted_value do
            begin
              value = bindings[:object].send("get_#{name}")
              value.present? ? JSON.pretty_generate(value) : nil
            rescue JSON::GeneratorError
              nil
            end
          end

          def parse_value(value)
            begin
              value.present? ? YAML.load(value) : nil
            rescue Psych::SyntaxError
              value
            end
          end

          def parse_input(params)
            params[name] = parse_value(params[name]) if params[name].is_a?(::String)
          end

        end
      end
    end
  end
end
