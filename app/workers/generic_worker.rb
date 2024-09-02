class GenericWorker

  include Sidekiq::Worker

  def perform(klass_name, klass_method, *method_args)
    klass = klass_name.constantize
    options = method_args.extract_options!
    if options
      klass.public_send(klass_method, **options)
    else
      klass.public_send(klass_method)
    end
  end
end
