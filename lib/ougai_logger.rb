module OugaiLogger
  class Logger < Ougai::Logger
    include ActiveSupport::LoggerThreadSafeLevel
    include LoggerSilence

    def initialize(*args)
      super
      after_initialize if respond_to? :after_initialize
    end

    def create_formatter
      (Rails.env.development? || Rails.env.test?) ? Ougai::Formatters::Readable.new : Ougai::Formatters::Bunyan.new
    end
  end
end
