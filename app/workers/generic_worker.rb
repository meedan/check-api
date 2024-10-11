class GenericWorker

  include Sidekiq::Worker

  sidekiq_options retry: 3
  sidekiq_retry_in { |_count, _exception| 3 }

  def perform(klass_name, klass_method, *method_args)
    klass = klass_name.constantize
    options = method_args.extract_options!.with_indifferent_access
    unless options.blank?
      user_id = options.delete(:user_id) if options.key?(:user_id)
      current_user = User.current
      User.current = User.find_by_id(user_id)
      klass.public_send(klass_method, *method_args, **options)
      User.current = current_user
    else
      klass.public_send(klass_method)
    end
  end
end
