import '../constants/company_info.dart';

class LegalSection {
  final String title;
  final String body;

  const LegalSection(this.title, this.body);
}

class LegalDocument {
  final String title;
  final String intro;
  final List<LegalSection> sections;

  const LegalDocument({
    required this.title,
    required this.intro,
    required this.sections,
  });
}

class LegalContent {
  static const about = LegalDocument(
    title: 'Hakkımızda',
    intro:
        '${CompanyInfo.brand}, Bagnu Çorakçı Satıcı tarafından sunulan, kişinin kendisiyle bağ kurmasına ve iyi oluş yolculuğuna alan açmayı amaçlayan bir uygulamadır.',
    sections: [
      LegalSection('Kurucu',
          'Bagnu Çorakçı Satıcı — Bilinçaltı Uzmanı. Deneyim: 20 yıl.'),
      LegalSection(
        'Neler sunuyoruz?',
        'Uygulamada 1’e 1 seanslar, meditasyonlar, eğitimler, atölyeler, astroloji yorumları, numeroloji yorumları ve Çin burcu yorumları sunulabilir.',
      ),
      LegalSection(
        'Kurucu hakkında',
        'Kurucunun eğitimleri, sertifikaları ve kişisel hikâyesine ilişkin nihai metin kullanıcı tarafından daha sonra sağlanmalıdır. Bu alan doğrulanmamış bilgi eklenmemesi için bilinçli olarak sınırlı tutulmuştur.',
      ),
      LegalSection(
        'Misyon',
        'Markanın nihai misyon metni kullanıcı tarafından daha sonra sağlanmalıdır. Yeniden Kendine, kullanıcıların kendileriyle bağ kurabilecekleri sade ve güvenli bir deneyim sunmayı hedefler.',
      ),
    ],
  );

  static const privacy = LegalDocument(
    title: 'Gizlilik Politikası',
    intro:
        'Bu politika, ${CompanyInfo.brand} uygulamasında kişisel verilerin hangi çerçevede işlenebileceğini sade bir dille açıklar. Ayrıntılı KVKK bilgilendirmesi için ayrıca KVKK Aydınlatma Metni’ni inceleyebilirsiniz.',
    sections: [
      LegalSection('Veri sorumlusu',
          '${CompanyInfo.operatorName} — ${CompanyInfo.brand}\n${CompanyInfo.address}\nKVKK iletişim: ${CompanyInfo.kvkkEmail}'),
      LegalSection(
        'İşlenebilecek veri kategorileri',
        'Ad ve soyad, e-posta, telefon, profil fotoğrafı ve profil bilgileri; doğum tarihi, doğum saati, doğum yeri ve kullanıcının astroloji, numeroloji veya Çin burcu yorumu için verdiği ek bilgiler; yorumlar, beğeniler, son oynatılan içerikler, uygulama kullanım geçmişi, seans ve rezervasyon bilgileri, atölye/eğitim katılım bilgileri, abonelik durumu, ödeme ile ilişkili işlem bilgileri, bildirim tercihleri ve gerekli teknik cihaz/oturum verileri işlenebilir.',
      ),
      LegalSection(
        'İşleme amaçları',
        'Üyelik ve hesap yönetimi, kimlik doğrulama, hizmetlerin sunulması, seans ve rezervasyon yönetimi, içerik erişimi, abonelik durumunun yönetilmesi, müşteri desteği, yorum ve beğeni özellikleri, güvenlik, hukuki yükümlülüklerin yerine getirilmesi ve kullanıcının talep ettiği kişisel yorumların oluşturulması amaçlarıyla işleme yapılabilir.',
      ),
      LegalSection(
        'Ödeme bilgileri',
        'Kart bilgileri Yeniden Kendine’nin kendi veritabanında saklanıyor şeklinde bir beyanda bulunulmaz. Kart ve ödeme bilgileri, ilgili ödeme platformları tarafından kendi güvenlik ve sözleşme koşulları kapsamında işlenebilir. 1’e 1 seans ödemelerinde Stripe altyapısı ve gerektiğinde ${CompanyInfo.paymentCompanyName} kullanılabilir. Dijital abonelikler Apple App Store veya Google Play üzerinden gerçekleştirilir.',
      ),
      LegalSection(
        'Hizmet sağlayıcıları',
        'Supabase; authentication, database, storage ve backend hizmetleri için kullanılabilir. OpenAI, astroloji, numeroloji ve Çin burcu yorumlarının sunucu tarafında oluşturulmasında kullanılabilir; uygulama içinde OpenAI API anahtarı tutulmaz. LiveKit, gerçek zamanlı 1’e 1 görüşme altyapısı için; Stripe, 1’e 1 seans ödeme altyapısı için kullanılabilir. Apple ve Google, giriş ve mağaza satın alma süreçlerinde kullanılabilir.',
      ),
      LegalSection(
        'Yorum verileri ve hassas bilgi uyarısı',
        'Astroloji, numeroloji ve Çin burcu yorumları tıbbi rehberlik veya profesyonel danışmanlık değildir. Bu yorumlar için verilen geçmiş en fazla 1 yıl saklanabilir. Sağlık bilgisi, teşhis, tıbbi kayıt veya diğer hassas kişisel bilgilerinizi ilgili alana yazmayınız.',
      ),
      LegalSection(
        'Saklama ve silme',
        'Veriler, amaç için gerekli olduğu veya mevzuatın zorunlu kıldığı süre boyunca saklanabilir. Hesap silme talebinde profil, beğeniler, oynatma geçmişi, yorum geçmişi ve gereksiz kullanıcı bağlantıları silinmeye veya anonimleştirilmeye çalışılır. Hukuken tutulması gereken ödeme ve seans kayıtları saklanabilir. Uygulamadaki hesap silme ekranında mevcut teknik kapsam ayrıca açıklanır.',
      ),
      LegalSection(
        'Haklarınız ve iletişim',
        'Kişisel verilerinizle ilgili taleplerinizi ${CompanyInfo.kvkkEmail} adresine iletebilirsiniz. KVKK kapsamındaki başvurularınız yürürlükteki mevzuat ve başvuru usulleri çerçevesinde değerlendirilir.',
      ),
    ],
  );

  static const kvkk = LegalDocument(
    title: 'KVKK Aydınlatma Metni',
    intro:
        'Bu Aydınlatma Metni, 6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında kişisel verilerinizin işlenmesine ilişkin bilgilendirme amacıyla hazırlanmıştır. Aydınlatma metni, açık rıza metni değildir.',
    sections: [
      LegalSection('Veri sorumlusu',
          '${CompanyInfo.operatorName}\nMarka: ${CompanyInfo.brand}\n${CompanyInfo.address}\nKVKK e-posta: ${CompanyInfo.kvkkEmail}'),
      LegalSection(
        'İşleme amaçları',
        'Üyelik ve hesap oluşturma, kimlik doğrulama, hizmetlerin sunulması, seans ve rezervasyon yönetimi, içerik erişiminin sağlanması, abonelik durumunun yönetilmesi, müşteri desteği, yorum ve beğeni özellikleri, güvenlik, hukuki yükümlülüklerin yerine getirilmesi ve kullanıcının istediği astroloji, numeroloji veya Çin burcu yorumlarının oluşturulması.',
      ),
      LegalSection(
        'İşlenebilecek veri grupları',
        'Kimlik ve iletişim bilgileri, profil bilgileri, doğum bilgileri ve kullanıcı tarafından yorum talebi sırasında sağlanan ek bilgiler, kullanım ve işlem bilgileri, rezervasyon/seans ve abonelik bilgileri, yorum ve beğeni verileri, bildirim tercihleri ve gerekli teknik kayıtlar işlenebilir.',
      ),
      LegalSection(
        'Aktarım ve hizmet sağlayıcıları',
        'Hizmetin teknik olarak sunulması için Supabase, LiveKit, Stripe, Apple, Google ve sunucu tarafında kullanılan AI sağlayıcıları gibi hizmet sağlayıcılarından yararlanılabilir. Aktarımın kapsamı, ilgili hizmetin gerektirdiği ölçüyle sınırlıdır.',
      ),
      LegalSection(
        'Açık rıza ve pazarlama',
        'Bu metni okumak, tek başına açık rıza verilmesi anlamına gelmez. Kampanya ve fırsat bildirimleri gelecekte sunulursa, hizmet bildirimlerinden ayrı ve isteğe bağlı olarak yönetilmelidir. Pazarlama tercihi zorunlu tutulmamalı ve sonradan kapatılabilmelidir.',
      ),
      LegalSection(
        'Başvuru',
        'Kişisel verilerinizle ilgili KVKK kapsamındaki başvurularınızı ${CompanyInfo.kvkkEmail} adresine veya yukarıdaki adrese iletebilirsiniz.',
      ),
    ],
  );

  static const terms = LegalDocument(
    title: 'Kullanım Koşulları',
    intro:
        '${CompanyInfo.brand} uygulamasını kullanarak aşağıdaki kullanım çerçevesini kabul etmiş olursunuz. Bu metin, zorunlu tüketici haklarını ortadan kaldıracak şekilde yorumlanamaz.',
    sections: [
      LegalSection('Hesap ve doğru bilgi',
          'Hesap oluştururken doğru ve güncel bilgi sağlamak, hesap güvenliğini korumak ve hesap üzerinden yapılan işlemlerden sorumlu olmak kullanıcının yükümlülüğüdür.'),
      LegalSection('Uygun kullanım',
          'Spam, taciz, tehdit, nefret söylemi, kopya içerik, hukuka aykırı kullanım ve başkalarının güvenliğini veya mahremiyetini zedeleyen davranışlar yasaktır. Gerekli durumlarda içerik moderasyonu yapılabilir ve hesap askıya alınabilir.'),
      LegalSection('İçerik ve fikri mülkiyet',
          'Uygulamadaki metin, ses, video, görsel, marka ve yazılım unsurları ilgili hak sahiplerine aittir. İçerikler yalnızca sunulan hizmet kapsamında ve kişisel kullanım için kullanılabilir.'),
      LegalSection('Ücretli hizmetler',
          'Plus aboneliği Apple App Store veya Google Play üzerinden; 1’e 1 seans ödemeleri Stripe altyapısı üzerinden sunulabilir. Ayrıntılı abonelik ve seans koşulları ilgili sayfalarda yer alır.'),
      LegalSection('18 yaş altı kullanıcılar',
          'Ücretsiz içerikler yaş sınırlaması olmadan sunulabilir. 18 yaş altındaki kişilerin hesap oluşturması ve kişisel veri kullanımı veli veya yasal temsilci sorumluluğunda; ücretli abonelik ve 1’e 1 seans kullanımı ise yasal temsilci izniyle gerçekleştirilmelidir.'),
      LegalSection('AI destekli yorumlar',
          'Astroloji, numeroloji ve Çin burcu yorumları tıbbi tavsiye, psikolojik tedavi, hukuki tavsiye, finansal tavsiye veya kesin gelecek tahmini değildir. Önemli yaşam kararları yalnızca bu içeriklere dayandırılmamalıdır.'),
      LegalSection('Meditasyon ve iyi oluş uyarısı',
          'Meditasyonlar sağlık hizmeti, tıbbi tanı, psikolojik tedavi veya terapi yerine geçen hizmet değildir. Acil sağlık veya psikolojik kriz durumlarında uygulama acil yardım hizmeti değildir; uygun acil yardım ve profesyonel destek kanallarına başvurulmalıdır.'),
      LegalSection('Hizmet değişiklikleri ve hukuk',
          'Hizmetler, içerikler ve teknik özellikler güvenlik, mevzuat veya ürün gereksinimleri nedeniyle değiştirilebilir. Bu koşullar Türkiye’de yürürlükteki hukuk çerçevesinde uygulanır.'),
    ],
  );

  static const subscriptionTerms = LegalDocument(
    title: 'Plus Abonelik Koşulları',
    intro:
        'Plus, uygulamadaki seçili içerik ve özelliklere erişim sağlayan dijital abonelik planıdır. Satın alma, kullanıcının cihazına göre ilgili mağaza üzerinden tamamlanır.',
    sections: [
      LegalSection('Planlar',
          'Aylık plan: 500 TL. Yıllık plan: 4.500 TL. Mağazada gösterilen gerçek ve yerelleştirilmiş fiyat, bu bilgilendirmedeki örnek fiyatlardan farklıysa satın alma anındaki mağaza fiyatı geçerlidir.'),
      LegalSection('Satın alma ve yönetim',
          'iOS satın almaları Apple App Store, Android satın almaları Google Play üzerinden gerçekleşir. Kullanıcı aboneliğini ilgili Apple veya Google hesabının mağaza ayarlarından yönetebilir.'),
      LegalSection('Yenileme ve iptal',
          'Ürün mağazada otomatik yenilenen abonelik olarak sunuluyorsa, kullanıcı ilgili mağaza üzerinden iptal etmediği sürece abonelik dönem sonunda yenilenebilir. İptal, mevcut ödenmiş dönem sonuna kadar Plus erişimini kendiliğinden sona erdirmez.'),
      LegalSection('Erişim ve Plus etiketi',
          'Plus etiketi bulunan içerikler abonelik durumuna göre erişilebilir. Mağaza doğrulaması veya bağlantı sorunlarında erişim durumu kısa süreli olarak güncellenemeyebilir.'),
      LegalSection('Satıcı ayrımı',
          'Dijital Plus aboneliğinin satıcısı olarak MIRACLETI LTD gösterilmez. Bu abonelikler Apple App Store veya Google Play üzerinden gerçekleşir; MIRACLETI LTD bilgisi yalnızca 1’e 1 seans ödeme açıklamalarında kullanılır.'),
    ],
  );

  static const refundPolicy = LegalDocument(
    title: 'Seans / İptal / İade Koşulları',
    intro:
        'Bu sayfa yalnızca gerçek zamanlı 1’e 1 öğretmen–öğrenci seansları için geçerli işletme politikasını açıklar.',
    sections: [
      LegalSection('Ödeme altyapısı',
          '1’e 1 seans ödemeleri Stripe altyapısı üzerinden işlenebilir. Ödeme tarafında ${CompanyInfo.paymentCompanyName}, şirket numarası ${CompanyInfo.paymentCompanyNumber}, kayıtlı ofis: ${CompanyInfo.paymentCompanyAddress} bilgileri ilgili ödeme açıklamalarında kullanılabilir.'),
      LegalSection('24 saat kuralı',
          'Seans başlangıcından en az 24 saat önce yapılan kullanıcı iptalinde tam iade yapılır. Öğretmenin seansı iptal etmesi halinde tam iade yapılır.'),
      LegalSection('Geç iptal ve katılmama',
          'Kullanıcının seans başlangıcından önceki son 24 saat içinde iptal etmesi veya seansa katılmaması (no-show) halinde kural olarak iade yapılmaz.'),
      LegalSection('Teknik ve olağanüstü durumlar',
          'Teknik sorunlar veya olağanüstü durumlar destek ekibi tarafından olay bazında değerlendirilebilir. Destek için ${CompanyInfo.supportEmail} adresine başvurabilirsiniz.'),
      LegalSection('Zorunlu yasal haklar',
          'Bu işletme politikası, tüketicinin yürürlükteki mevzuattan doğan zorunlu haklarını ortadan kaldırmaz veya sınırlandırmaz. Emredici mevzuat hükümleri saklıdır.'),
    ],
  );

  static const minorPolicy = LegalDocument(
    title: '18 Yaş Altı Kullanıcılar Hakkında',
    intro:
        'Yeniden Kendine’de ücretsiz içeriklere erişim ile hesap, kişisel veri ve ücretli hizmet kullanımı ayrı değerlendirilir.',
    sections: [
      LegalSection('Ücretsiz içerikler',
          'Ücretsiz içerikler yaş sınırlaması olmadan erişilebilir olabilir.'),
      LegalSection('Hesap ve kişisel veriler',
          '18 yaş altındaki kişilerin hesap oluşturması ve kişisel veri kullanımı veli veya yasal temsilci sorumluluğunda gerçekleştirilmelidir.'),
      LegalSection('Ücretli hizmetler',
          'Ücretli Plus aboneliği ve 1’e 1 seanslar 18 yaş altındaki kullanıcılar tarafından yasal temsilcilerinin izniyle gerçekleştirilmelidir.'),
      LegalSection('Teknik doğrulama',
          'Uygulamada şu anda zorunlu teknik parental consent verification sistemi oluşturulmamıştır. Veli veya yasal temsilci gerekli izin ve gözetimi sağlamalıdır.'),
    ],
  );

  const LegalContent._();
}
