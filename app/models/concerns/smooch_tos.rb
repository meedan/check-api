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
    es: '',
    be: ''
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
  
      %{team} %{channel} टिपलाइन में आपका स्वागत है।
  
      सत्यापन के लिए अपनी क्वेरी सबमिट करने के लिए आप इस नंबर का उपयोग कर सकते हैं।
  
      आपका डेटा सुरक्षित है। हम आपकी व्यक्तिगत जानकारी को सुरक्षित रखने और %{channel} को निजी और सुरक्षित रखने के लिए अपनी ज़िम्मेदारी को गंभीरता से लेते हैं; इस सेवा को प्रदान करने और इसमें सुधार करने के अलावा आपकी व्यक्तिगत रूप से पहचान कराने योग्य जानकारी (PII) को हम कभी साझा नहीं करेंगे, बेचेंगे नहीं, या अन्यथा उपयोग नहीं करेंगे।
       
      भविष्य में जितनी जल्दी हो सके वायरल हुई गलत जानकारी का पता लगाने के लिए, हम इस टिपलाइन से नॉन-PII कॉन्टेंट को पुनरीक्षित शोधकर्ताओं और तथ्य-जांच भागीदारों के साथ साझा कर सकते हैं।
  
      कृपया ध्यान दें कि जिन वेबसाइटों का हम लिंक प्रदान करते हैं, उनकी अपनी गोपनीयता नीति होगी।
  
      यदि आप नहीं चाहते कि आपकी प्रस्तुतियाँ इस कार्य में प्रयुक्त हों, तो कृपया हमारे सिस्टम में योगदान न करें।
    },

    mr: %{
      गोपनीयता आणि उद्देश 

      %{team} %{channel} tipline मध्ये आपले स्वागत आहे. 

      आपण सत्यापन करण्यासाठी आपले प्रश्न सादर करण्याकरिता हा नंबर वापरू शकता.

      आपला डेटा सुरक्षित आहे. आम्ही आपल्या वैयक्तिक माहितीचे रक्षण करण्यासाठी आणि %{channel} गोपनीय आणि सुरक्षित ठेवण्याची आमची जबाबदारी गंभीरपणे घेतो; आम्ही ही सेवा देण्याच्या आणि त्यात सुधारणा करण्याच्या व्यतिरिक्त आपली वैयक्तिकपणे ओळख करणारी माहिती (PII) कधीही सामायिक करणार नाही, विक्री करणार नाही किंवा तीचा अन्यथा वापर करणार नाही.
       
      भविष्यात व्हायरल चुकीची माहिती शक्य तितक्या लवकर शोधण्यासाठी, आम्ही तपासलेल्या संशोधक आणि तथ्ये तपासणाऱ्या भागीदारांसोबत या tipline कडून गैर—PII मजकूर सामायिक करू शकतो.

      कृपया नोंद घ्या की आम्ही ज्या वेबसाईटशी लिंक करतो त्यांचे स्वतःचे गोपनीयता धोरण असेल.

      जर आपल्याला आपले सादरीकरण या कामात वापरायचे नसेल, तर कृपया आमच्या सिस्टीमवर योगदान देऊ नये.
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
  
      %{team} %{channel} டிப் லைனை வரவேற்கிறோம்.
  
      உங்கள் வினவலை, சரிபார்ப்பிற்கு சமர்ப்பிக்க இந்த எண்ணை பயன்படுத்தலாம்.
  
      உங்கள் தரவு பாதுகாப்பாக இருக்கிறது. உங்களுடைய தனிப்பட்ட தகவல் மற்றும் %{channel}-ஐ இரகசியமாக மற்றும் பாதுகாப்பாக வைக்கும் பொறுப்பை சிரத்தையுடன் எடுத்து செய்கிறோம்;
      உங்களை அடையாளங் காட்டக்கூடிய  தனிப்பட்ட தகவலை (PII) உங்களுக்கு சேவை செய்ய மற்றும் வழங்க மட்டுமே தவிர நாங்கள் யாரிடமும் பகிரவோ, விற்கவோ அல்லது வேறு 
      ஏதாவது செய்யவோ மாட்டோம்.
  
      வருங்காலத்தில் வைரஸ் பற்றிய தவறான தகவலை முன்கூட்டியே தெரிந்துகொள்ள, இந்த டிப் லைனில் உள்ள PII அல்லாத உள்ளடக்கங்களை நம்பகமான ஆராய்ச்சியாளர்கள் 
      மற்றும் தகவல் சரிபார்ப்பு கூட்டாளிகளுடன் நாங்கள் பகிரலாம்.
  
      நாங்கள் இணையும் இணைப்புகள் தங்களுக்கென தனிப்பட்ட தனியுரிமை கொள்கைகளை கொண்டிருக்கும் என்பதை கவனத்தில் கொள்ளுங்கள்.
  
      இந்த பணிக்கு நீங்கள் உங்களுடைய சமர்ப்பிப்புகள் பயன்படுத்தப்படுவதை விரும்பவில்லை என்றால், எங்கள் அமைப்பிற்கு எதையும் வழங்க வேண்டாம்.
    },

    te: %{
      గౌప్యత మరియు ప్రయోజనం 
  
      %{team}వారి %{channel} టిప్ లైనుకు మీకు సుస్వాగతం. 
  
      మీరు మీ విచారణను పరిశీలనకు సమర్పించడానికి ఈ నెంబరును వాడుకోవచ్చు.
  
      మీ సమాచారం సురక్షితంగా ఉంది. మీ వ్యక్తిగతంగా సమాచారాన్ని రక్షించడం మరియు %{channel}ని గౌప్యంగా మరియు సురక్షితంగా ఉంచే బాధ్యతను మేము చాలా సీరియస్ గా తీసుకుంటాం; ఎటువంటి పరిస్థితిలోనూ వైయక్తికంగా మిమ్మల్ని గుర్తించడానికి సహాయపడే సమాచారాన్ని(PII) మేము ఇతరులతో పంచుకోము, మీకు ఈ సేవను అందించడం మరియు దానిని మెరుగుపరుచే ఉద్దేశానికి తప్ప, వేరు కారణాలకు ఈ సమాచారాన్ని వాడటం కానీ ఇతరులకు అమ్మడం కానీ జరుగదు.
  
      భవిష్యత్తులో వచ్చే తప్పుడు సమాచారాన్ని కుదిరినంత తొందరగా గుర్తించడానికి సహాయపడటం కోసం, మీకు వైయక్తికంగా సంబంధించని సమాచారాలను మాత్రమే పరిశోధించబడ్డ పరిశోధకులతో మరియు మా వాస్తవ తనిఖీ భాగస్వాములతో పంచుకోవడం మాత్రమే జరుగుతుంది.
  
      మేము లింక్ చేసే వెబ్ సైట్లు వారి సొంత గోప్యతా నియమాలను కలిగి ఉంటాయని గమనించగలరు.
  
      మీరు అందించిన సమాచారం మా ఈ పనిలో వాడటం మీకు నచ్చని పక్షాన, దయచేసి మా వ్యవస్థకు సమాచారాన్ని అందివ్వకండి.
    },

    kn: %{
      ಗೌಪ್ಯತೆ
      ಗೌಪ್ಯತೆ ಹಾಗೂ ಉದ್ದೇಶ 

      %{team}ನ %{channel} ಸಹಾಯವಾಣಿಗೆ ನಿಮಗೆ ಸುಸ್ವಾಗತ. 

      ನೀವು ನಿಮ್ಮ ವಿಚಾರಣೆಯನ್ನು ಪರಿಶೀಲನೆಗೆ ಸಲ್ಲಿಸಲು ಈ ಸಂಖ್ಯೆಯನ್ನು ಬಳಸಬಹುದು.

      ನಿಮ್ಮ ಮಾಹಿತಿ ಸುರಕ್ಷಿತವಾಗಿದೆ. ನಿಮ್ಮ ವೈಯುಕ್ತಿಕ ಮಾಹಿತಿಯನ್ನು ರಕ್ಷಿಸುವ ಹಾಗೂ %{channel}ನ ಖಾಸಗಿ ಹಾಗೂ ಸುರಕ್ಷಿತವಾಗಿ ಇರಿಸುವ ಜವಾಬ್ದಾರಿಯನ್ನು ನಾವು ಗಂಭೀರವಾಗಿ ಪರಿಗಣಿಸುತ್ತೇವೆ; ನಾವು ಯಾವುದೇ ಕಾರಣಕ್ಕೆ ನಿಮ್ಮನ್ನು ವೈಯುಕ್ತಿಕವಾಗಿ ಗುರುತಿಸಲು ಸಹಾಯ ಮಾಡುವ ಮಾಹಿತಿಯನ್ನು (PII), ಈ ಸೇವೆಯನ್ನು ನೀಡಲು ಹಾಗೂ ಇದನ್ನು ಉತ್ತಮಗೊಳಿಸುವ ಉದ್ದೇಶವನ್ನು ಹೊರತುಪಡಿಸಿ, ಬೇರೆ ಕಾರಣಗಳಿಗೆ ಬಳಸುವುದಾಗಲಿ ಅಥವಾ ಮಾರುವುದಾಗಲಿ ಮಾಡುವುದಿಲ್ಲ.
       
      ಭವಿಷ್ಯದಲ್ಲಿ ವೈರಲ್ ಆಗುವ ತಪ್ಪು ಮಾಹಿತಿಯನ್ನು ಸಾಧ್ಯವಾದಷ್ಟು ಬೇಗನೆ ಗುರುತಿಸುವಲ್ಲಿ ಸಹಾಯವಾಗಲೆಂದು, ಈ ಸಹಾಯವಾಣಿಯ ಮೂಲಕ ಪಡೆದುಕೊಳ್ಳಲಾದ, ವೈಯುಕ್ತಿಕವಾಗಿ ಗುರುತಿಸಲಾಗದ ಮಾಹಿತಿಯನ್ನು ಪ್ರಮಾಣೀಕೃತ ಸಂಶೋಧಕರು ಹಾಗೂ ನೈಜತೆ ವಿಚಾರಣಾ ಭಾಗಸ್ವಾಮಿಗಳೊಂದಿಗೆ ಹಂಚಿಕೊಳ್ಳಲಾಗುತ್ತದೆ.

      ನಾವು ಲಿಂಕ್ ಮಾಡುವ ವೆಬ್ ಸೈಟುಗಳು ತಮ್ಮದೇ ಆದ ಗೌಪ್ಯತಾ ನಿಯಮವನ್ನು ಹೊಂದಿರುತ್ತದೆ ಎಂಬುದನ್ನು ಗಮನಿಸಿ.

      ನೀವು ನೀಡಿದ ಮಾಹಿತಿಯನ್ನು ಈ ಕೆಲಸದಲ್ಲಿ ಬಳಸಬಾರದು ಎಂದು ನೀವು ಬಯಸಿದಲ್ಲಿ, ದಯವಿಟ್ಟು ನಮ್ಮ ವ್ಯವಸ್ಥೆಗೆ ಮಾಹಿತಿಯನ್ನು ನೀಡಬೇಡಿ.
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
      ਪਰਦੇਦਾਰੀ ਅਤੇ ਉਦੇਸ਼

      %{team} %{channel} ਟਿਪਲਾਈਨ ਵਿੱਚ ਤੁਹਾਡਾ ਸੁਆਗਤ ਹੈ।

      ਤੁਸੀਂ ਤਸਦੀਕ ਲਈ ਆਪਣੀ ਪੁੱਛਗਿੱਛ ਜਮ੍ਹਾਂ ਕਰਨ ਲਈ ਇਸ ਨੰਬਰ ਦੀ ਵਰਤੋਂ ਕਰ ਸਕਦੇ ਹੋ।

      ਤੁਹਾਡਾ ਡੇਟਾ ਸੁਰੱਖਿਅਤ ਹੈ। ਅਸੀਂ ਤੁਹਾਡੀ ਨਿੱਜੀ ਜਾਣਕਾਰੀ ਨੂੰ ਸੁਰੱਖਿਅਤ ਰੱਖਣ ਅਤੇ %{channel} ਨੂੰ ਨਿੱਜੀ ਅਤੇ ਸੁਰੱਖਿਅਤ ਰੱਖਣ ਦੀ ਆਪਣੀ ਜ਼ਿੰਮੇਵਾਰੀ ਨੂੰ ਗੰਭੀਰਤਾ ਨਾਲ ਲੈਂਦੇ ਹਾਂ; ਇਸ ਸੇਵਾ ਨੂੰ ਪ੍ਰਦਾਨ ਕਰਨ ਅਤੇ ਇਸ ਵਿੱਚ ਸੁਧਾਰ ਕਰਨ ਤੋਂ ਇਲਾਵਾ ਅਸੀਂ ਤੁਹਾਡੀ ਨਿੱਜੀ ਤੌਰ 'ਤੇ ਪਛਾਣ ਕਰਾਉਣ ਯੋਗ ਜਾਣਕਾਰੀ (PII) ਨੂੰ ਕਦੇ ਵੀ ਸਾਂਝਾ ਨਹੀਂ ਕਰਾਂਗੇ, ਵੇਚਾਂਗੇ ਨਹੀਂ, ਜਾਂ ਇਸਦੀ ਵਰਤੋਂ ਨਹੀਂ ਕਰਾਂਗੇ।
       
      ਭਵਿੱਖ ਵਿੱਚ ਜਿੰਨੀ ਜਲਦੀ ਸੰਭਵ ਹੋ ਸਕੇ ਵਾਇਰਲ ਗਲਤ ਜਾਣਕਾਰੀ ਦਾ ਪਤਾ ਲਗਾਉਣ ਲਈ, ਅਸੀਂ ਜਾਂਚ ਕੀਤੇ ਖੋਜਕਰਤਾਵਾਂ ਅਤੇ ਤੱਥ-ਜਾਂਚ ਕਰਨ ਵਾਲੇ ਭਾਈਵਾਲਾਂ ਨਾਲ ਇਸ ਟਿਪਲਾਈਨ ਤੋਂ ਗੈਰ-PII ਸਮੱਗਰੀ ਨੂੰ ਸਾਂਝਾ ਕਰ ਸਕਦੇ ਹਾਂ।

      ਕਿਰਪਾ ਕਰਕੇ ਨੋਟ ਕਰੋ ਕਿ ਜਿਨ੍ਹਾਂ ਵੈੱਬਸਾਈਟਾਂ ਦੇ ਅਸੀਂ ਲਿੰਕ ਦਿੰਦੇ ਹਾਂ, ਉਨ੍ਹਾਂ ਦੀ ਆਪਣੀ ਪਰਦੇਦਾਰੀ ਨੀਤੀ ਹੋਵੇਗੀ।

      ਜੇਕਰ ਤੁਸੀਂ ਨਹੀਂ ਚਾਹੁੰਦੇ ਕਿ ਤੁਹਾਡੀਆਂ ਪ੍ਰਸਤੁਤੀਆਂ ਨੂੰ ਇਸ ਕੰਮ ਵਿੱਚ ਵਰਤਿਆ ਜਾਵੇ, ਤਾਂ ਕਿਰਪਾ ਕਰਕੇ ਸਾਡੇ ਸਿਸਟਮ ਵਿੱਚ ਯੋਗਦਾਨ ਨਾ ਦਿਓ।
    },

    id: %{
      Privasi dan Tujuan

      Selamat datang di tipline %{team} %{channel}.

      Anda dapat menggunakan nomor ini untuk mengirimkan pertanyaan Anda untuk diverifikasi.

      Data Anda aman. Kami menganggap serius tanggung jawab kami untuk menjaga informasi pribadi Anda dan menjaga %{channel} tetap privat dan aman; tidak akan pernah membagikan, menjual, atau menggunakan informasi pengenal pribadi (PII) Anda kecuali untuk menyediakan dan meningkatkan layanan ini.
       
      Untuk mendeteksi kesalahan informasi viral sedini mungkin di masa mendatang, kami dapat membagikan konten non-PII dari tipline ini dengan peneliti dan mitra pengecek fakta yang terpilih.

      Harap dicatat bahwa situs web yang kami tautkan akan memiliki kebijakan privasi mereka sendiri.

      Jika Anda tidak ingin kiriman Anda digunakan dalam karya ini, mohon jangan berkontribusi pada sistem kami.
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

      Bienvenue sur la ligne info Tipline %{channel} de %{team}. 

      Vous pouvez utiliser ce numéro pour envoyer votre demande de vérification.

      Vos données sont protégées. Nous prenons au sérieux notre responsabilité de protéger vos renseignements personnels et d’assurer la sécurité et la confidentialité de %{channel} ; jamais nous ne partagerons, ne vendrons, ni n’utiliserons autrement des renseignements qui peuvent vous identifier personnellement (RIP), sauf pour fournir ce service ou l’améliorer.

      Afin de détecter la mésinformation virale le plus tôt possible à l’avenir, nous pourrions partager le contenu non-RIP de cette ligne info avec des chercheurs et des partenaires approuvés de vérification des faits.

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
    },

    be: %{
      গোপনীয়তা এবং উদ্দেশ্য
      
      %{team} %{channel} টিপলাইনে স্বাগতম।
      
      যাচাইকরণের জন্য আপনার জিজ্ঞাসা জমা দিতে আপনি এই নম্বরটি ব্যবহার করতে পারেন।
      
      আপনার ডেটা নিরাপদ থাকে। আপনার ব্যক্তিগত তথ্য সুরক্ষিত রাখতে এবং %{channel} ব্যক্তিগত ও সুরক্ষিত রাখার জন্য আমরা আমাদের দায়িত্বকে গুরুত্বসহকারে গ্রহণ করি; এই পরিষেবাটি প্রদান এবং উন্নত করা ব্যতীত আপনার ব্যক্তিগতভাবে সনাক্তকরণযোগ্য তথ্য (PII) শেয়ার, বিক্রয় বা অন্যথায় ব্যবহার করব না।
       
      ভবিষ্যতে যত তাড়াতাড়ি সম্ভব ভাইরাল হওয়া ভুল তথ্য সনাক্ত করার জন্য, আমরা এই টিপলাইন থেকে অ- PII সামগ্রীটি পরীক্ষিত গবেষক এবং সত্য-যাচাইয়ের অংশীদারদের সাথে শেয়ার করতে পারি।
      
      অনুগ্রহ করে মনে রাখবেন যে আমরা যে ওয়েবসাইটগুলির সাথে লিঙ্ক করি সেগুলির নিজস্ব গোপনীয়তা নীতি থাকবে।
      
      আপনি যদি না চান যে এই কাজে আপনার সাবমিশনগুলি ব্যবহার হক তবে দয়া করে আমাদের সিস্টেমে অবদান করবেন না।
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
