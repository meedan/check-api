module LapisConstants
  class ErrorCodes
    UNAUTHORIZED = 1
    MISSING_PARAMETERS = 2
    ID_NOT_FOUND = 3
    INVALID_VALUE = 4
    UNKNOWN = 5
    AUTH = 6
    WARNING = 7
    MISSING_OBJECT = 8
    DUPLICATED = 9
    LOGIN_2FA_REQUIRED = 10
    CONFLICT = 11
    PUBLISHED_REPORT = 12
    OBJECT_NOT_READY = 13

    def self.all
      self.constants
    end
  end
end
