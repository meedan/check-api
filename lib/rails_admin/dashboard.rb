require 'pry'

module RailsAdmin
  module Config
    module Actions
      class Dashboard < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :root? do
          true
        end

        register_instance_option :breadcrumb_parent do
          nil
        end

        register_instance_option :controller do
          proc do

              @history = @auditing_adapter && @auditing_adapter.latest || []
              if @action.statistics?
                @abstract_models = RailsAdmin::Config.visible_models(controller: self).collect(&:abstract_model)

                @most_recent_created = {}
                @count = {}
                @max = 0
                @abstract_models.each do |t|
                  scope = @authorization_adapter && @authorization_adapter.query(:index, t)
                  current_count = t.count({}, scope)
                  @max = current_count > @max ? current_count : @max
                  @count[t.model.name] = current_count
                  next unless t.properties.detect { |c| c.name == :created_at }
                  @most_recent_created[t.model.name] = t.model.last.try(:created_at)
                end
              end

            #You can specify flash messages
            # flash.now[:success] = "Welcome back!"

            #After you're done processing everything, render the new dashboard
            render @action.template_name, status: 200
          end
        end

        register_instance_option :route_fragment do
          ''
        end

        register_instance_option :link_icon do
          'icon-home'
        end

        register_instance_option :statistics? do
          true
        end
      end
    end
  end
end