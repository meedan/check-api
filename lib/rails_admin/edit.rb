module RailsAdmin
  module Config
    module Actions
      class Edit < RailsAdmin::Config::Actions::Base
        RailsAdmin::Config::Actions.register(self)

        register_instance_option :member do
          true
        end

        register_instance_option :http_methods do
          [:get, :put]
        end

        register_instance_option :controller do
          proc do
            RailsAdmin::MainController.class_eval { respond_to :html, :js }
            if request.get? # EDIT
              respond_with(@object)
            elsif request.put? # UPDATE
              RequestStore.store[:ability] = :admin
              sanitize_params_for!(request.xhr? ? :modal : :update)

              skippable_fields = []
              skippable_fields = @object.skippable_fields(params[@abstract_model.param_key]) if @object.respond_to?(:skippable_fields, true)
              fields = params[@abstract_model.param_key]
              skippable_fields.each do |skip|
                fields.reject! { |key, value| key == skip.to_s}
              end

              @object.set_attributes(fields)
              @authorization_adapter && @authorization_adapter.attributes_for(:update, @abstract_model).each { |name, value| @object.send("#{name}=", value) }
              changes = @object.changes
              if @object.save
                @auditing_adapter && @auditing_adapter.update_object(@object, @abstract_model, _current_user, changes)
                respond_to do |format|
                  format.html { redirect_to_on_success }
                  format.js { render json: {id: @object.id.to_s, label: @model_config.with(object: @object).object_label} }
                end
              else
                handle_save_error :edit
              end

            end
          end
        end

        register_instance_option :link_icon do
          'icon-pencil'
        end
      end
    end
  end
end
