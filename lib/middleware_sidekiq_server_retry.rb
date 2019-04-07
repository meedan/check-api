# :nocov:
module Middleware
  module Sidekiq
    module Server
      class Retry
        EXCEPTIONS_TO_STOP = [
          Pusher::HTTPError,
          Pusher::Error,
          PG::UniqueViolation,
          ArgumentError,
          ActiveRecord::RecordNotFound,
          NoMethodError,
          TypeError,
          ActiveRecord::UnknownAttributeError,
          Psych::SyntaxError,
          JSON::ParserError,
          PG::ForeignKeyViolation,
          PG::NotNullViolation,
          Net::HTTPClientError
        ]

        def call(_worker, msg, _queue)
          begin
            yield
          rescue *EXCEPTIONS_TO_STOP => e
            msg['retry'] = 0
            raise e
          end
        end
      end
    end
  end
end
# :nocov:
