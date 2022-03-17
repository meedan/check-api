require 'active_support/concern'

# This module contains localized content. This content is not handled as any
# other localizable strings because they need to be approved by lawyers and
# by the partners.

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

  CONTENT = {
    en: %{
      Privacy and Purpose 

      Welcome to the %{team} %{channel} tipline. 

      You can use this number to submit your query for verification.

      Your data is safe. We take seriously our responsibility to safeguard your personal information and to keep %{channel} private and secure; will never share, sell, or otherwise use your personally identifiable information (PII) except to provide and improve this service.
       
      To detect viral misinformation as early as possible in the future, we may share non-PII content from this tipline with vetted researchers and fact-checking partners. 

      Please note that websites we link to will have their own privacy policy.

      If you do not want your submissions used in this work, please do not contribute to our system.
    },

    pt: %{
      Privacidade e Escopo

      Bem-vindo(a) à linha do %{channel} de %{team}. Estamos trabalhando para tornar você uma melhor fonte de informação para sua família e amigos(as) no canal %{channel}.

      Você pode usar este número para submeter sua solicitação de verificação. Não somos capazes de responder a todas as solicitações, mas seus dados estarão seguros de qualquer forma.

      Levamos a sério nossa responsabilidade de proteger suas informações pessoais e de manter este canal do %{channel} privado e seguro; nunca compartilharemos, venderemos ou usaremos suas informações pessoais identificáveis (PII), exceto para fornecer e melhorar este serviço.

      Para detectar desinformação viral o mais cedo possível no futuro, poderemos compartilhar o conteúdo não-PII deste canal com pesquisadores(as) aprovados(as) e parceiros(as) de verificação de fatos. Se você não quiser que suas solicitações sejam utilizadas para isso, por favor, não contribua para nosso sistema. Observe que os sites para os quais temos links tem sua própria política.
    },

    hi: %{
      गोपनीयता और उद्देश्य

      %{team} %{channel} टिप-लाइन पर आपका स्वागत है। हम कोशिश कर रहें हैं कि आप %{channel} पर अपने दोस्तों और परिजनों के लिये जानकारी का और बेहतर माध्यम बन पाएँ।

      आप इस नंबर का इस्तेमाल अपने सवालो को सबमिट करने के लिये कर सकते हैं। हम सभी सवालों के जवाब तो नहीं दे पाएँगे लेकिन, आपका डाटा फिर भी सुरक्षित रहेगा।

      हम आपकी व्यक्तिगत जानकारी को सुरक्षित रखने और व्हाट्सएप को निजी और सुरक्षित रखने के लिए अपनी जिम्मेदारी को गंभीरता से लेते हैं; न कभी आपकी जानकारी बाँटेंगे, ना बेचेंगे, और ना ही आपकी व्यक्तिगत पहचान की जानकारी (PII) का कोई और उपयोग करेंगे सिवाय, यह सुविधा देने और इसे बहतर बनाने के लिये। 

      भविष्य में वायरल हुइ गइ गलत जानकारी का जल्द-से-जल्द पता लगाने के लिये, हम इस टिप-लाइन से प्राप्त की गई गैर-पीआईआई (non-PII) जानकरी, हमारे शोधकर्ताओं और तथ्य-जाँच संबंधी भागीदारों के साथ साझा कर सकते हैं।

      कृपया ध्यान दें कि जिन वेबसाइटों को हम लिंक करेंगे उनकी अपनी गोपनीयता नीति है।

      यदी आप नहीं चाहते की आपका सबमिशन इस काम में इस्तेमाल हों, तो कृपया हमारे सिस्टम में योगदान न करें।
    },

    mr: %{
      गोपनीयता आणि उद्देश

      %{team} %{channel} टिपलाईनवर स्वागत आहे. %{channel} वर असलेल्या आपल्या कुटुंब आणि मित्रांसाठी आपण माहितीचा एक अधिक चांगला स्त्रोत बनावे यासाठी आम्ही कार्यरत आहोत.

      आपली सत्यापनासाठीची क्वेरी प्रविष्ट करण्यासाठी आपण हा नंबर वापरू शकता. आम्ही प्रत्येक विनंतीला प्रतिसाद देऊ शकत नाही, पण तरीही आपला डेटा सुरक्षित आहे.

      आपल्या वैयक्तिक माहितीचे रक्षण करण्याची आणि %{channel} खाजगी आणि सुरक्षित ठेवण्याची आमची जबाबदारी आम्ही गंभीरपणे घेतो; ही सेवा पुरवणे आणि सुधारणे वगळता आपली वैयक्तिकरीत्या ओळखता येणारी माहिती (PII) आम्ही कधीही सामायिक, विक्री, किंवा अन्य कारणासाठी वापरणार नाही.

      व्हायरल झालेली चुकीची माहिती लवकरात लवकर ओळखण्यासाठी, अधिकृत संशोधक आणि तथ्य-तपासणी भागीदारांसोबत या टिपलाईनवरून आम्ही विना-PII मजकूर भविष्यात सामायिक करू शकतो.

      कृपया लक्षात घ्या की आम्ही ज्या वेबसाईट लिंक करतो त्यांचे स्वतःचे गोपनीयता धोरण असतील.

      आपल्याला आपली प्रस्तुती या कार्यात वापरली जाणे नको असल्यास, कृपया आमच्या सिस्टिममध्ये सहभाग देऊ नका.
    },

    bn: %{
      গোপনীয়তা এবং উদ্দেশ্য

      %{team} হোয়াটসঅ্যাপ টিপলাইনে আপনাকে স্বাগতম। আমরা আপনাকে হোয়াটসঅ্যাপে আপনার পরিবার এবং বন্ধুদের জন্য তথ্যের আরও ভাল উৎস হিসাবে গড়ে তুলতে কাজ করছি। 

      আপনি যাচাইকরণের জন্য আপনার অনুসন্ধান জমা দিতে এই নম্বরটি ব্যবহার করতে পারেন। আমরা প্রতিটি অনুরোধের প্রতিক্রিয়া জানাতে পারছি না, তবে উভয়ক্ষেত্রে আপনার তথ্য নিরাপদ থাকবে।

      আমরা আপনার ব্যক্তিগত তথ্য সুরক্ষিত করার জন্য এবং হোয়াটসঅ্যাপকে ব্যক্তিগত এবং সুরক্ষিত রাখতে আমাদের দায়িত্ব গুরুতরভাবে গ্রহণ করি; এই পরিষেবা সরবরাহ করা এবং এটিকে উন্নত করা ব্যতীত কখনই আপনার ব্যক্তিগতভাবে সনাক্তকরণযোগ্য তথ্য (পিআইআই)  শেয়ার করা, বিক্রি করা বা অন্য উদ্দেশে ব্যবহার করা হবে না।

      ভবিষ্যতে যত তাড়াতাড়ি সম্ভব ভাইরাল ভুল তথ্য সনাক্ত করতে, আমরা এই টিপলাইন থেকে বিশ্বস্ত গবেষক এবং ফ্যাক্ট-চেকিং অংশীদারদের সাথে ব্যক্তিগতভাবে সনাক্তকরণযোগ্য নয় এমন (নন-পিআইআই) বিষয়বস্তু শেয়ার করতে পারি।

      দয়া করে মনে রাখবেন, যে ওয়েবসাইটগুলি আমরা সংযুক্ত করি তাদের নিজস্ব গোপনীয়তা নীতি রয়েছে।

      আপনি যদি এই কর্মকাণ্ডে আপনার প্রদত্তগুলি ব্যবহার করতে দিতে না চান, তবে দয়া করে আমাদের সিস্টেমে অবদান রাখবেন না।
    },

    ta: %{
      தனியுரிமை மற்றும் நோக்கம்

      %{team} வாட்ஸ்அப் உதவிக்குறிப்புக்கு வருக. உங்கள் குடும்பத்தினருக்கும் நண்பர்களுக்கும் வாட்ஸ்அப்பில் சிறந்த தகவல்களை வழங்க நாங்கள் பணியாற்றி வருகிறோம்.

      சரிபார்ப்புக்கு உங்கள் வினவலைச் சமர்ப்பிக்க இந்த எண்ணைப் பயன்படுத்தலாம். ஒவ்வொரு கோரிக்கைக்கும் எங்களால் பதிலளிக்க முடியவில்லை, ஆனால் உங்கள் தரவு எந்த வகையிலும் பாதுகாப்பாக இருக்கும்.

      உங்கள் தனிப்பட்ட தகவல்களைப் பாதுகாப்பதற்கும், வாட்ஸ்அப்பை தனிப்பட்டதாகவும் பாதுகாப்பாகவும் வைத்திருப்பதற்கான எங்கள் பொறுப்பை நாங்கள் தீவிரமாக எடுத்துக்கொள்கிறோம்; இந்த சேவையை வழங்குவதற்கும் மேம்படுத்துவதற்கும் தவிர, தனிப்பட்ட முறையில் அடையாளம் காணக்கூடிய தகவல்களை (பஅஅ) ஒருபோதும் பகிரவோ, விற்கவோ அல்லது பயன்படுத்தவோ மாட்டேன்.      

      எதிர்காலத்தில் வைரஸ் தவறான தகவலை விரைவில் கண்டறிய, இந்த உதவிக்குறிப்பிலிருந்து பஅஅ அல்லாத உள்ளடக்கத்தை சரிபார்க்கப்பட்ட ஆராய்ச்சியாளர்கள் மற்றும் உண்மைச் சரிபார்ப்பு கூட்டாளர்களுடன் பகிர்ந்து கொள்ளலாம்.
       
      நாங்கள் இணைக்கும் வலைத்தளங்களுக்கு அவற்றின் தனியுரிமைக் கொள்கை இருக்கும் என்பதை நினைவில் கொள்க.

      இந்த வேலையில் உங்கள் சமர்ப்பிப்புகள் பயன்படுத்த விரும்பவில்லை என்றால், தயவுசெய்து எங்கள் கணினியில் பங்களிக்க வேண்டாம்.
    },

    te: %{
      గోప్యత మరియు ప్రయోజనం 

      %{team} వాట్సాప్ టిప్‌లైన్‌కు స్వాగతం. వాట్సాప్‌లో మీ కుటుంబం మరియు స్నేహితుల కోసం మీకు మంచి సమాచారం అందించడానికి మేము కృషి చేస్తున్నాము.

      ధృవీకరణ కోసం మీ ప్రశ్నను సమర్పించడానికి మీరు ఈ నంబర్‌ను ఉపయోగించవచ్చు. మేము ప్రతి అభ్యర్థనకు ప్రతిస్పందించలేము, కానీ మీ డేటా ఏ విధంగానైనా సురక్షితంగా ఉంటుంది.

      మీ వ్యక్తిగత సమాచారాన్ని కాపాడటానికి మరియు వాట్సాప్‌ను ప్రైవేట్‌గా మరియు భద్రంగా ఉంచడానికి మా బాధ్యతను మేము తీవ్రంగా పరిగణిస్తాము; ఈ సేవను అందించడానికి మరియు మెరుగుపరచడానికి తప్ప మీ వ్యక్తిగతంగా గుర్తించదగిన సమాచారాన్ని (పిఐఐ) భాగస్వామ్యం చేయదు, అమ్మదు లేదా ఉపయోగించదు.     

      భవిష్యత్తులో వీలైనంత త్వరగా వైరల్ తప్పుడు సమాచారాన్ని గుర్తించడానికి, మేము ఈ టిప్‌లైన్ నుండి పిఐఐ కాని కంటెంట్‌ను పరిశీలించిన పరిశోధకులు మరియు నిజ-తనిఖీ భాగస్వాములతో పంచుకోవచ్చు.
       
      మేము లింక్ చేసే వెబ్‌సైట్‌లకు వారి స్వంత గోప్యతా విధానం ఉంటుందని దయచేసి గమనించండి.

      ఈ పనిలో మీ సమర్పణలు ఉపయోగించకూడదనుకుంటే, దయచేసి మా సిస్టమ్‌కు సహకరించవద్దు.
    },

    kn: %{
      ಗೌಪ್ಯತೆ ಮತ್ತು ಉದ್ದೇಶ

      %{team} %{channel} ಟಿಪ್‌ಲೈನ್‌ಗೆ ಸ್ವಾಗತ. %{channel} ನಲ್ಲಿ ನಿಮ್ಮ ಕುಟುಂಬ ಮತ್ತು ಸ್ನೇಹಿತರಿಗೆ ಮಾಹಿತಿಯ ಉತ್ತಮ ಮೂಲವನ್ನಾಗಿ ನಿಮ್ಮನ್ನು ರೂಪಿಸಲು ನಾವು ಶ್ರಮಿಸುತ್ತಿದ್ದೇವೆ.

      ಪರಿಶೀಲನೆಗೆ ನಿಮ್ಮ ವಿಚಾರಣೆಯನ್ನು ಸಲ್ಲಿಸಲು ಈ ಸಂಖ್ಯೆಯನ್ನು ನೀವು ಬಳಸಬಹುದು. ಪ್ರತಿ ವಿನಂತಿಗೂ ನಾವು ಪ್ರತಿಕ್ರಿಯಿಸಲಾಗದಿರಬಹುದು. ಆದರೆ, ಎಲ್ಲಾ ರೀತಿಯಲ್ಲೂ ನಿಮ್ಮ ಡೇಟಾ ಸುರಕ್ಷಿತವಾಗಿರುತ್ತದೆ.

      ನಿಮ್ಮ ವೈಯಕ್ತಿಕ ಮಾಹಿತಿಯನ್ನು ರಕ್ಷಿಸಲು ಮತ್ತು %{channel} ಅನ್ನು ಖಾಸಗಿ ಮತ್ತು ಸುರಕ್ಷಿತವಾಗಿಡುವ ನಿಟ್ಟಿನಲ್ಲಿ ಜವಾಬ್ದಾರಿಯನ್ನು ನಾವು ಗಂಭೀರವಾಗಿ ಪರಿಗಣಿಸುತ್ತೇವೆ. ಈ ಸೇವೆಯನ್ನು ಸುಧಾರಿಸುವುದು ಮತ್ತು ಒದಗಿಸುವುದನ್ನು ಹೊರತುಪಡಿಸಿ ನಿಮ್ಮನ್ನು ವೈಯಕ್ತಿಕವಾಗಿ ಗುರುತಿಸಬಹುದಾದ ಮಾಹಿತಿ (PII) ಅನ್ನು ನಾವು ಎಂದಿಗೂ ಹಂಚಿಕೊಳ್ಳುವುದಿಲ್ಲ, ಮಾರುವುದಿಲ್ಲ ಅಥವಾ ಬಳಸುವುದಿಲ್ಲ.

      ವ್ಯಾಪಕವಾಗಿ ಹರಡುವ ಸುಳ್ಳು ಸುದ್ದಿಯನ್ನು ಮುಂದಿನ ದಿನಗಳಲ್ಲಿ ಸಾಧ್ಯವಾದಷ್ಟು ಬೇಗ ಗುರುತಿಸಲು, ಪರಿಣಿತ ಸಂಶೋಧಕರು ಮತ್ತು ಸತ್ಯಶೋಧನೆ ಪಾಲುದಾರರ ಜೊತೆಗೆ ಈ ಟಿಪ್‌ಲೈನ್‌ನಿಂದ ವೈಯಕ್ತಿಕ ಮಾಹಿತಿ ಇಲ್ಲದ ಕಂಟೆಂಟ್‌ ಅನ್ನು ನಾವು ಹಂಚಿಕೊಳ್ಳಬಹುದು.

      ನಾವು ಲಿಂಕ್‌ ಮಾಡುವ ವೆಬ್‌ಸೈಟ್‌ಗಳು ತಮ್ಮದೇ ಗೌಪ್ಯತೆ ನೀತಿಯನ್ನು ಹೊಂದಿರುತ್ತವೆ ಎಂದು ದಯವಿಟ್ಟು ಗಮನದಲ್ಲಿಟ್ಟುಕೊಳ್ಳಿ.

      ಈ ಕಾರ್ಯದಲ್ಲಿ ನಿಮ್ಮ ಸಲ್ಲಿಕೆಗಳನ್ನು ಬಳಸಬಾರದು ಎಂದು ನೀವು ಬಯಸಿದರೆ, ದಯವಿಟ್ಟು ನಮ್ಮ ವ್ಯವಸ್ಥೆಗೆ ಕೊಡುಗೆ ನೀಡಬೇಡಿ.
    },

    ur: %{
      پرائیویسی اور مقصد

      %{team} کو واٹس ایپ تجاویز لائن میں خوش آمدید۔ ہم واٹس ایپ پر آپ کے دوستوں اور آپ کی فیملی کیلئے آپ ہی کو ایک بہتر معلوماتی ذریعہ بنانے پر کام کر رہے ہیں۔

      تصدیق کیلئے اپنے سوالات جمع کروانے کیلئے آپ اسی نمبر کا استعمال کر سکتے ہیں۔ اگرچہ ہم ہر درخواست کا جواب دینے کے مجاز نہیں، لیکن آپ کا ڈیٹا ہر حال میں محفوظ رہے گا۔

      آپ کی نجی معلومات کی حفاظت کرنا اور واٹس ایپ کو پرائیویٹ اور محفوظ رکھنا ہمارا نصب العین ہے؛ ہم نا تو آپ کی ذاتی معلومات کا استعمال کریں گے اور نا ہی اسے بیچیں گے اور نا ہی اسے تقسیم کریں گے۔

      مستقبل میں جتنا جلدی ممکن ہو سکا ہم وائرل ہونے والی غلط معلومات کا پتہ چلانے کیلئے اس ٹِپ لائن سے تحقیقاتی شراکت داروں اور جانچ کرنے والے محققین کیساتھ نان PII مواد شیئر کریں گے۔

      براہِ کرم اس بات کو یاد رکھئے گا کہ جن ویب سائٹس سے ہم منسلک ہوں گے ان کی شرائط و ضوابط لاگو ہوں گے۔

      اگر آپ چاہتے ہیں کہ آپ کی جمع کردہ تجاویز اور سوالات یہاں کا حصہ نا بنیں تو ازراہِ کرم ہمارے نظام میں حصہ مت ڈالیں۔
    },

    pa: %{
      ਨਿੱਜਤਾ ਅਤੇ ਉਦੇਸ਼

      %{team} %{channel} ਟਿਪਲਾਈਨ ਵਿੱਚ ਤੁਹਾਡਾ ਸੁਆਗਤ ਹੈ। ਅਸੀਂ %{channel} 'ਤੇ ਤੁਹਾਡੇ ਪਰਿਵਾਰ ਅਤੇ ਦੋਸਤਾਂ ਲਈ ਤੁਹਾਨੂੰ ਜਾਣਕਾਰੀ ਦਾ ਇੱਕ ਬਿਹਤਰ ਸਰੋਤ ਬਣਾਉਣ ਲਈ ਕੰਮ ਕਰ ਰਹੇ ਹਾਂ। 

      ਤੁਸੀਂ ਤਸਦੀਕ ਵਾਸਤੇ ਆਪਣੇ ਸਵਾਲ ਨੂੰ ਜਮ੍ਹਾ ਕਰਨ ਲਈ ਇਸ ਨੰਬਰ ਦੀ ਵਰਤੋਂ ਕਰ ਸਕਦੇ ਹੋ। ਅਸੀਂ ਹਰ ਬੇਨਤੀ ਦਾ ਜਵਾਬ ਦੇਣ ਦੇ ਯੋਗ ਨਹੀਂ ਹਾਂ, ਪਰ ਅਸੀਂ ਜਵਾਬ ਦਈਏ ਜਾਂ ਨਹੀਂ ਦਈਏ, ਤੁਹਾਡਾ ਡੇਟਾ ਦੋਨਾਂ ਮਾਮਲਿਆਂ ਵਿੱਚ ਸੁਰੱਖਿਅਤ ਰਹੇਗਾ। 

      ਅਸੀਂ ਤੁਹਾਡੀ ਨਿੱਜੀ ਜਾਣਕਾਰੀ ਨੂੰ ਸੁਰੱਖਿਅਤ ਰੱਖਣ ਅਤੇ %{channel} ਨੂੰ ਗੁਪਤ ਅਤੇ ਸੁਰੱਖਿਅਤ ਰੱਖਣ ਦੀ ਆਪਣੀ ਜਿੰਮੇਵਾਰੀ ਨੂੰ ਗੰਭੀਰਤਾ ਨਾਲ ਲੈਂਦੇ ਹਾਂ; ਅਸੀਂ ਇਹ ਸੇਵਾ ਮੁਹੱਈਆ ਕਰਨ ਅਤੇ ਇਸ ਵਿੱਚ ਸੁਧਾਰ ਕਰਨ ਤੋਂ ਅਲਾਵਾ ਕਿਸੇ ਹੋਰ ਕੰਮ ਲਈ ਕਦੇ ਵੀ ਤੁਹਾਡੀ ਨਿੱਜੀ ਪਛਾਣ ਕਰਨ ਵਾਲੀ ਜਾਣਕਾਰੀ (PII) ਨੂੰ ਸਾਂਝਾ ਨਹੀਂ ਕਰਾਂਗੇ, ਵੇਚਾਂਗੇ ਨਹੀਂ, ਜਾਂ ਕਿਸੇ ਹੋਰ ਤਰੀਕੇ ਨਾਲ ਇਸ ਦੀ ਵਰਤੋਂ ਨਹੀਂ ਕਰਾਂਗੇ।

      ਭਵਿੱਖ ਵਿੱਚ ਜਲਦੀ ਤੋਂ ਜਲਦੀ ਵਾਇਰਲ ਗਲਤ ਜਾਣਕਾਰੀ ਦੀ ਪਛਾਣ ਕਰਨ ਲਈ, ਅਸੀਂ ਧਿਆਨ ਨਾਲ ਨਿਰੀਖਣ ਕਰਨ ਵਾਲੇ ਸ਼ੋਧਕਰਤਾਵਾਂ ਅਤੇ ਤੱਥਾਂ ਦੀ ਜਾਂਚ ਕਰਨ ਵਾਲੇ ਸਾਂਝੇਦਾਰਾਂ ਦੇ ਨਾਲ ਗੁਪਤ ਸੰਚਾਰ ਤੋਂ ਪ੍ਰਾਪਤ ਹੋਈ ਗ਼ੈਰ-PII ਸਮੱਗਰੀ ਨੂੰ ਸਾਂਝਾ ਕਰ ਸਕਦੇ ਹਾਂ।
       
      ਕਿਰਪਾ ਕਰਕੇ ਧਿਆਨ ਵਿੱਚ ਰੱਖੋ ਕਿ ਅਸੀਂ ਜਿੰਨ੍ਹਾਂ ਵੈੱਬਸਾਈਟਾਂ ਦੇ ਲਿੰਕ ਦਿਆਂਗੇ, ਉਹਨਾਂ ਦੀ ਆਪਣੀ ਖੁਦ ਦੀ ਨਿੱਜਤਾ ਨੀਤੀ ਹੋਵੇਗੀ।

      ਜੇਕਰ ਤੁਸੀਂ ਚਾਹੁੰਦੇ ਹੋ ਕਿ ਤੁਹਾਡੇ ਵੱਲੋਂ ਜਮ੍ਹਾਂ ਕੀਤੀਆਂ ਚੀਜਾਂ ਦੀ ਵਰਤੋਂ ਇਸ ਕੰਮ ਵਿੱਚ ਨਾ ਕੀਤੀ ਜਾਵੇ, ਤਾਂ ਕਿਰਪਾ ਕਰਕੇ ਸਾਡੇ ਸਿਸਟਮ ਵਿੱਚ ਯੋਗਦਾਨ ਨਾ ਪਾਓ।
    },

    id: %{
      Privasi dan Tujuan

      Selamat datang di %{team} tipline WhatsApp. Kami berupaya menjadikan Anda sumber informasi yang lebih baik untuk keluarga dan teman Anda di WhatsApp.

      Anda dapat menggunakan nomor ini untuk mengirimkan pertanyaan untuk diverifikasi. Kami tidak dapat menanggapi setiap permintaan, tetapi data Anda akan tetap aman. 

      Kami menganggap serius tanggung jawab kami untuk menjaga informasi pribadi Anda dan menjaga WhatsApp tetap pribadi dan aman; tidak akan pernah membagikan, menjual, atau menggunakan informasi pengenal pribadi (PII) Anda kecuali untuk menyediakan dan meningkatkan layanan ini.
       
      Untuk mendeteksi kesalahan informasi viral sedini mungkin di masa mendatang, kami dapat membagikan konten non-PII dari tipline ini dengan peneliti dan mitra pengecek fakta yang terpilih. 

      Mohon dicatat bahwa situs web yang kami tautkan akan memiliki kebijakan privasi mereka sendiri.

      Jika Anda tidak ingin kiriman Anda digunakan dalam pekerjaan ini, mohon jangan berkontribusi pada sistem kami.
    },

    de: %{
      Datenschutzbestimmungen

      Willkommen bei der WhatsApp-Hinweisnummer von %{team}. Wir arbeiten daran, dass Sie für Ihre Familie und Freunde bei WhatsApp eine zuverlässigere Informationsquelle werden.

      Sie können diese Nummer verwenden, um uns Ihre Anfragen zu einer Wahrheitsprüfung zuzusenden. Wir können leider nicht jede Anfrage beantworten, aber Ihre Daten sind auf jeden Fall geschützt.

      Wir nehmen unsere Verantwortung zum Schutz Ihrer personenbezogenen Daten sehr ernst und wollen WhatsApp privat und sicher halten; wir werden personenbezogene Daten, mit denen Sie identifiziert werden können, niemals weitergeben, verkaufen oder anderweitig verwenden, außer um unseren Service anzubieten und zu verbessern.

      Um zukünftig virale Desinformation so schnell wie möglich erkennen zu können, geben wir nicht-personenbezogene Informationen von dieser Hinweisnummer möglicherweise an geprüfte Rechercheure und Partner weiter, die Fakten für uns überprüfen.

      Bitte beachten Sie, dass von uns verlinkte Webseiten ihre eigenen Datenschutzbestimmungen haben. \n Wenn Sie nicht wollen, dass Ihre Anfragen derartig verwendet werden, wirken Sie bei unserem System bitte einfach nicht mit.
    },

    fr: %{
      Confidentialité et objectif

      Bienvenue sur la ligne info Tipline de %{team} %{channel}. 

      Vos données seront protégées. Nous prenons au sérieux notre responsabilité de protéger vos renseignements personnels et d’assurer la sécurité et la confidentialité de %{channel} ; jamais nous ne partagerons, ne vendrons, ni n’utiliserons autrement des renseignements qui peuvent vous identifier personnellement (RIP), sauf pour fournir ce service ou l’améliorer.

      Afin de détecter la mésinformation virale le plus tôt possible à l’avenir, nous pourrions partager des contenus non-RIP de cette ligne info avec des chercheurs et des partenaires approuvés de vérification des faits.

      Veuillez prendre note que les sites Web vers lesquels nous établissons des liens ont leur propre politique de confidentialité.

      Si vous ne voulez pas que vos envois soient utilisés dans le cadre de ce travail, veuillez ne pas contribuer à notre système.
    },

    es: %{
      Privacidad y Propósito

      Bienvenida(o) a la tipline de %{team} %{channel}. 

      Puedes utilizar este número para enviar tu consulta para verificación. 

      Tus datos están seguros. Nos tomamos muy en serio nuestra responsabilidad de salvaguardar tu información personal y mantener %{channel} privado y seguro; nunca compartiremos, venderemos o usaremos tu información de identificación personal (PII) excepto para proporcionar y mejorar este servicio.

      Para detectar desinformación viral lo antes posible en el futuro, puede que compartamos contenido no PII de esta tipline con socia(o)s certificada(o)s en investigación y verificación de hechos.

      Por favor ten en cuenta que los sitios web a los que enlazamos tendrán su propia política de privacidad.

      Si no deseas que tus aportes se utilicen en este trabajo, por favor no contribuyas a nuestro sistema.
    }
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
      message = self.get_custom_message_for_language(workflow, 'content') || self.get_message_for_language(CONTENT, language)
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
