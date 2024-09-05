class GenericWorker

  include Sidekiq::Worker

  def perform(klass_name, klass_method, *method_args)
    klass = klass_name.constantize
    options = method_args.extract_options!.with_indifferent_access
    if options
      if options.key?(:user_id)
        user_id = options.delete(:user_id)
        User.current = User.find_by_id(user_id)
      end
      klass.public_send(klass_method, **options)
      User.current = nil
    else
      klass.public_send(klass_method)
    end
  end
end
