module CheckChannels
  class ChannelCodes
    def self.all_channels
      {
        "MANUAL" => MANUAL,
        "FETCH" => FETCH,
        "BROWSER_EXTENSION" => BROWSER_EXTENSION,
        "API" => API,
        "ZAPIER" => ZAPIER,
        "TIPLINE" => {
          "WHATSAPP" => WHATSAPP,
          "MESSENGER" => MESSENGER,
          "TWITTER" => TWITTER,
          "TELEGRAM" => TELEGRAM,
          "VIBER" => VIBER,
          "LINE" => LINE,
        },
        "WEB_FORM" => WEB_FORM,
        "SHARED_DATABASE" => SHARED_DATABASE
      }
    end
    MANUAL = 0 # items submitted via app
    FETCH = 1 # items submitted via Fetch bot
    BROWSER_EXTENSION = 2 # items submitted via check-mark extension
    API = 3 # items via API
    ZAPIER = 4
    WHATSAPP = 5
    MESSENGER = 6
    TWITTER = 7
    TELEGRAM = 8
    VIBER = 9
    LINE = 10
    TIPLINE = [WHATSAPP, MESSENGER, TWITTER, TELEGRAM, VIBER, LINE]
    WEB_FORM = 11
    SHARED_DATABASE = 12
    ALL = [MANUAL, FETCH, BROWSER_EXTENSION, API, ZAPIER, WEB_FORM, SHARED_DATABASE] + TIPLINE
  end
end
