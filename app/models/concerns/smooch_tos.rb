require 'active_support/concern'

module SmoochTos
  extend ActiveSupport::Concern

  GREETING = {
    en: 'We will never share your personally identifiable information. Reply 9 to read our Privacy and Purpose statement.',
    pt: 'Nós nunca compartilhamos suas informações de identificação pessoal (PII). Responda com o dígito 9 para ler a nossa Declaração de Privacidade e Escopo.',
    hi: 'हम कभी भी आपकी व्यक्तिगत पहचान की जानकारी किसी से साझा नहीं करेंगे। हमारा गोपनीयता और उद्देश्य विवरण पढने के लिये 9 दबाएँ।',
    mr: 'आम्ही आपली वैयक्तिकरीत्या ओळखता येणारी माहिती कधीही सामायिक करणार नाही. आमचा गोपनीयता आणि उद्देश विधान वाचण्यासाठी 9 लिहून उत्तर द्या.',
    bn: 'আমরা আপনার ব্যক্তিগতভাবে সনাক্তযোগ্য তথ্য কখনই শেয়ার করব না। আমাদের গোপনীয়তা এবং উদ্দেশ্য বিবৃতি পড়তে ৯-তে প্রতিউত্তর দিন।',
    ta: 'உங்கள் தனிப்பட்ட முறையில் அடையாளம் காணக்கூடிய தகவலை நாங்கள் ஒருபோதும் பகிர மாட்டோம். எங்கள் தனியுரிமை மற்றும் நோக்கம் அறிக்கையைப் படிக்க 9 க்கு பதிலளிக்கவும்.',
    te: 'మీ వ్యక్తిగతంగా గుర్తించదగిన సమాచారాన్ని మేము ఎప్పటికీ భాగస్వామ్యం చేయము. మా గోప్యత మరియు పర్పస్ స్టేట్మెంట్ చదవడానికి 9 ప్రత్యుత్తరం ఇవ్వండి.',
    kn: 'ನಾವು ಎಂದಿಗೂ ನಿಮ್ಮ ವೈಯಕ್ತಿಕವಾಗಿ ಗುರುತಿಸಬಹುದಾದ ಮಾಹಿತಿಯನ್ನು ಹಂಚಿಕೊಳ್ಳುವುದಿಲ್ಲ. ನಮ್ಮ ಗೌಪ್ಯತೆ ಮತ್ತು ಉದ್ದೇಶ ಹೇಳಿಕೆಯನ್ನು ಓದಲು 9 ಎಂದು ಪ್ರತಿಕ್ರಿಯಿಸಿ.',
    ur: 'ہم آپ کی ذاتی شناخت والی معلومات کبھی بھی شیئر نہیں کریں گے۔ ہماری پرائیویسی اور مقصد والے بیان کے مطالعہ کیلئے جواب 9 میں دیجئے۔',
    pa: 'ਅਸੀਂ ਕਦੇ ਵੀ ਤੁਹਾਡੀ ਨਿੱਜੀ ਪਛਾਣ ਕਰਨ ਵਾਲੀ ਜਾਣਕਾਰੀ ਨੂੰ ਸਾਂਝਾ ਨਹੀਂ ਕਰਾਂਗੇ। ਸਾਡੇ ਗੋਪਨੀਯਤਾ ਅਤੇ ਉਦੇਸ਼ ਕਥਨ ਨੂੰ ਪੜ੍ਹਨ ਲਈ ਜਵਾਬ ਵਿੱਚ 9 ਭੇਜੋ।',
    id: 'Kami tidak akan pernah membagikan informasi pengenal pribadi Anda. Balas dengan angka 9 untuk membaca pernyataan Privasi dan Tujuan kami.',
    de: 'Wir werden Daten, mit denen Sie identifiziert werden können, niemals weitergeben. Drücken Sie 9, um unsere Datenschutzbestimmungen zu lesen.',
    fr: "Nous ne partagerons jamais vos informations personnellement identifiables. Répondez 9 pour lire notre déclaration de confidentialité et d'objectif.",
    es: ''
  }

  module ClassMethods
    def get_message_for_language(messages, language)
      team = Team.find(self.config['team_id'].to_i)
      locale = language.to_s.downcase.gsub(/[_-].*$/, '').to_sym
      default_locale = team.default_language.to_s.downcase.gsub(/[_-].*$/, '').to_sym
      messages[locale] || messages[default_locale] || messages[:en]
    end

    def get_custom_message_for_language(workflow, key)
      message = workflow.dig('smooch_message_smooch_bot_tos', key)
      message.blank? ? nil : message
    end

    def tos_message(workflow, language)
      self.get_custom_message_for_language(workflow, 'greeting') || self.get_message_for_language(GREETING, language)
    end

    def send_tos_to_user(workflow, uid, language, platform = '')
      team = Team.find(self.config['team_id'].to_i)
      message = self.get_custom_message_for_language(workflow, 'content') || self.get_string('privacy_and_purpose', language)
      message = message.gsub(/^[ ]+/, '')
      message = message.gsub('%{team}', team.name)
      message = message.gsub('%{channel}', platform)
      self.send_final_message_to_user(uid, message, workflow, language)
    end

    def should_send_tos?(state, typed)
      state == 'main' && typed == '9'
    end
  end
end
