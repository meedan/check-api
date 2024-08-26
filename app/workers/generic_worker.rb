class GenericWorker

  include Sidekiq::Worker

  def perform(klass_name, *args)
    # require 'byebug'
    # byebug
    klass = klass_name.constantize
    options = args.extract_options!(args)
    if options
      klass.public_send(*args, **options)
    else
      klass.public_send(*args)
    end
  end
end
