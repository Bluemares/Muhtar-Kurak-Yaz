# MUHTAR: KURAK YAZ (Sürüm 4.6 — 3D Antalya Köyü) — Jüri Sunum Dosyası

## Oyun Açıklaması (~150 Kelime)

**MUHTAR: KURAK YAZ**, COP31 Türkiye Game Jam'in **gıda güvenliği** ve iklim direnci teması için Godot 4 ile geliştirilmiş, **3D serbest dönen diorama kameralı** bir köy yönetimi ve strateji oyunudur. Oyuncu, kuzeyinde Toros dağları ve kızılçam ormanları, güneyinde Akdeniz kıyısı, zeytinlikler, portakal bahçeleri ve naylon seralar bulunan **Antalya'da bir köye** COP31 tarafından deneme süresiyle atanan muhtardır.

Temel hedef, Haziran (31°C, %20 kuraklık), Temmuz (36°C, %50 kuraklık) ve Ağustos (42°C, %90 kuraklık) olmak üzere 4,5 dakikalık (270 sn) üç yaz ayı boyunca (toplam ~14 dk) **kuraklıkta köyü doyurmak ve gıda güvenliğini sağlamaktır**. Kuraklık arttıkça nehir daralır, sıcak stresi refahı zorlar, kuru tarlalar yavaş büyür ve yangınlar başlar. Muhtar; tarla ve seralarda kuraklığa uygun ürün seçer (sebze/havuç, kavun, mısır, kuraklığa dayanıklı buğday), ambar kurup erzak depolar, damla sulama ve koruluklarla toprağı nemli tutar. Finalde gıda güvenliği oranı ve "önleme harcanan bütçe vs yangın hasarı" karşılaştırılarak ana mesaj vurgulanır: **"Her derece, bir tarla daha." İklim değişikliğinde önlem, müdahaleden ucuzdur.**

---

## Nasıl Oynanır?

### Gıda Güvenliği ve Sürüm 4.6 (3D Antalya Köyü) Sistemleri
- **Ana Hedef — Kuraklıkta Gıda Güvenliği ve Yıldız Şartları:** Oyunun merkezinde üç kurak yaz ayı boyunca köylüleri aç bırakmamak yer alır (köylü başına tüketim `0,1` birim/sn):
  - **Haziran Görevi ("Köyü doyur"):** Ay sonunda en az 2 sağlam tarlan olsun ve köylüler aç kalmasın.
  - **Temmuz Görevi ("Ambarı doldur"):** Ay sonunda ambarda en az **2 günlük yiyecek** bulunsun ve köylüler aç kalmasın.
  - **Ağustos Görevi ("Kuraklıkta sofra"):** Ay sonunda en az **3 çeşit ürün** yetişsin (sebze, kavun, mısır, buğday, sera) ve köylüler aç kalmasın.
  - **Gıda Güvenliği Göstergesi ve 1–3 Yıldız:** Görev panelinde ambardaki erzakın kaç gün yeteceği canlı gösterilir; final ekranında *"Gıda güvenliği: köylüler zamanın %X'inde tok"* istatistiği yer alır. **3 yıldız** için 3 ana görevin tamamlanması, köylülerin **zamanın en az %90'ında tok** olması ve en fazla **2 yanan bina** şarttır (**2 yıldız** için %80+ refah ve en az 2 görev; **1 yıldız** için %60+ refah).
- **Tarla ve Serada Ürün Seçimi & Ürün Çeşitliliği Bonusu:** Her **tarlaya veya seraya** tıklandığında **Ürün seç** butonuyla o ayın iklimine göre ekin belirlenir, 3D bitkiler seçilen ürüne göre büyür ve oyun kuraklık/su durumuna göre **önerilen ürünü (`»`)** işaretler:
  - **Sebze (havuç):** Su ihtiyacı %100 · Verim %100 · Süre ×1,0 (dengeli başlangıç ürünü).
  - **Kavun:** Su ihtiyacı %135 · Verim %140 · Süre ×1,15 (su bolken en yüksek verim).
  - **Mısır:** Su ihtiyacı %115 · Verim %120 · Süre ×1,05 (iyi verim).
  - **Buğday:** Su ihtiyacı %55 · Verim %80 · Süre ×1,0 (**kuraklığa dayanıklı**, az su ister).
  - **Ürün Çeşitliliği:** Köyde aynı anda 2 / 3 / 4 farklı ürün türü yetiştirmek refah hedefini **+3 / +6 / +10 puan** artırır.
- **Ambar ve Pazar Ekonomisi:** Hasat edilen ürünler önce **Ambara** (COP31 kileri 40 kapasite + her **Ambar** binası +100 kapasite) girer; ambar dolduğunda taşan ürün kendiliğinden satılır. Üst çubuktaki yiyecek ikonuna, COP31 binasına veya ambara tıklayarak **Pazar** açılır (10'luk paketlerle ürün al/sat). Kuraklık arttıkça ürün satış fiyatı `1,5 × (1 + kuraklık × 0,8)` formülüyle yükselir; ancak kıtlıkta pazardan ürün satın almak satmaktan **1,6 kat pahalıdır** — ambarı erken doldurmak kıtlığa karşı en önemli sigortadır.
- **Sıcak Stresi ve Kuru Toprak Etkisi:** Kuraklık arttıkça **sıcak stresi** refah hedefini düşürür (en fazla `kuraklık × 22` puan; görev panelinde *"Sıcak stresi −X"* olarak görünür). Su deposunu dolu tutmak ve koruluklar dikmek sıcak stresini hafifletir. Ayrıca **kuru tarla yavaş büyür** (kupkuru toprakta büyüme hızı `%35`'e kadar düşer, `MOIST_GROWTH_MIN = 0,35`).
- **3D Antalya Vadisi (32×22) ve Canlı Köy Hayatı:** Kuzey, doğu ve batıda kireçtaşı kayalıkları ve kızılçam ormanlarıyla çevrili **Toros dağları**, güneyde kumsalı ve palmiyeleriyle **Akdeniz kıyısı**, vadiyi bölen nehir ve gündüzleri sıcakla yükselen **ağustos böceği korosu** yer alır. COP31 binası yükseltildikçe (Sv.1: 14×10 ve 6 köylü, Sv.2 [350 altın]: 22×16 ve 10 köylü, Sv.3 [600 altın]: tüm 32×22 vadi ve 14 köylü) açık alan genişler. Köylüler tarlada ve serada **çapa** ile çalışır, arazi temizlerken **balta** kullanır, boşta kaldıklarında ise **kuyunun dibinden kova doldurup su kulesine** (su kulesi yoksa COP31'e) su taşır (+4 su).
- **Yol Şartı, Yol Silme ve Arazi Temizleme:** **COP31 binası ve koruluk dışındaki her bina yola bitişik olmalıdır**, aksi halde çalışmaz (koruluk yolsuz da çalışır). İnşa → Altyapı sekmesinden hücre başı **10 altına** sürükleyerek yol döşenir; yol modundaki **Yol sil** butonu sol tıkı silgiye çevirir (sağ tık da siler, +5 altın iade). Yolları yükseltmek (Sv.2: 100, Sv.3: 200 altın) köylüleri ve yol ağını izleyen itfaiye aracını hızlandırır. **Arazi temizle** ile kayalar (40 altın) veya ağaçlar (25 altın, orman kesmek refahı 1,5 düşürür) boştaki bir köylü tarafından 4 saniyede temizlenir.
- **3D Binalar, Döndürme (R) ve Bina Satma:** Sağ alttaki **İnşa** butonundan (**Tarım / Su / Yerleşim / Altyapı** sekmeleri, 3D bina önizlemeli kartlar) seçilen binalar yerleştirilirken veya seçildikten sonra **R** tuşu ya da **Döndür** butonuyla döndürülebilir. **COP31 ve itfaiye dışındaki binalar**, bina üstü **Sat** butonuyla onay sorularak **yarı fiyatına (%50 altın iadesi)** kaldırılabilir:
  - **Tarla (150 altın, 2×2, 1 işçi):** Seviyesine göre 16/13/10 sn'de 12/15/19 temel ürün verir. **Damla Sulama (60 altın)** su tüketimini %40 azaltır.
  - **Sera (260 altın, 2×1, 1 işçi):** Antalya tipi örtü altı naylon tünel; içinde seçilen ürüne göre 2×4 bitki büyür, tarlanın %40'ı kadar (0,32/sn) su içer, 14 sn'de 11 ürün verir, kuraklık, böcek ve yangından etkilenmez.
  - **Ambar (160 altın, 2×1):** Yiyecek depolama kapasitesini +100 artırır.
  - **Kuyu (200 altın, 1×1):** Kiremit şapkalı taş kuyu; saniyede 2,2 / 3,4 / 5,0 su üretir (nehir kenarında +%50 bonus), su deposunu (+30/sv) ve yangın hortumu tankını (150 / 210 / 280) büyütür.
  - **Su Kulesi (180 altın, 1×1):** Su deposunu +100, yangında hortum tankını +40 büyütür; köylüler kuyudan çektiği kovaları buraya taşır.
  - **Koruluk (40 altın, 1×1):** Yol şartı aranmaz; sulanan portakal/zeytin ağaçları yanındaki binaların yangın riskini %40, komşu tarlaların su tüketimini %10 azaltır ve sıcak stresini hafifletir.
  - **Ev (120 altın, 1×1) ve Sokak Lambası (30 altın, 1×1):** Beyaz badanalı Antalya evi (2 köylü) ve geceleri 5,5 birim çevresini aydınlatan sokak lambası.
- **Ayrı Yangın Riski (F) ve Toprak Nemi (N) Haritaları:** Sağ altta iki ayrı buton ve kısayol bulunur: **F (Risk — alev ikonu)** yanabilir binaların dakikada tutuşma olasılığını (Düşük/Orta/Yüksek), **N (Nem — damla ikonu)** ise tarlaların toprak nemini (Nemli/Orta/Kuru) gösterir. Yangın çıktığında siren ışıklı 3D itfaiye aracı yol ağını izleyerek olay yerine ulaşır ve canlı 3D kamera görüntüsü üzerinde 25 saniyelik **hortum mini oyunu** başlar (hortum köyün su deposundan dolar).
- **Gündüz-Gece, 6 Rol Karakteri, COP31 Politikaları ve 9 Kartlı Nasıl Oynanır:** 3D portreli **6 köy karakteri** (Rehber Hasan Dayı, Elif — COP31 iklim görevlisi, Murat — İtfaiye şefi, Zeynep Öğretmen, Fatma Teyze — çiftçi, Kerem — gazeteci) karar ve görev kartlarını sunar. Ana menü ve duraklatma menüsünde **9 kartlı Nasıl Oynanır** rehberi (*Hedef, Üret, Ambar ve pazar, Yol şart, Ürün seç, Yangın, Önlem al, COP31, Kontroller*), 9 **COP31 politikası**, 9 **yan görev**, **9 başarım** ve **otomatik kayıt** (*"Devam et"*) bulunur.

### Kontroller
- **Sol Tık:** Bina seçme, bina üstü yuvarlak butonları kullanma (*Yükselt, Ürün seç, Damla sulama, İlaçla, Onar, Taşı, Döndür, Sat, Pazar*), olgun üründe hasat balonuna tıklama (+%15 bonus), sürükleyerek yol döşeme (veya *Yol sil* modunda silme); yangın mini oyununda su sıkma. (Binaya **çift tık** kamerayı o binaya odaklar.)
- **Sağ Tık Sürükle:** 3D diorama kamerayı serbestçe **döndürme ve eğme (tilt)**.
- **Q / E:** Kamerayı sola / sağa döndürme.
- **Orta Tık Sürükle veya WASD / Yön Tuşları:** Kamerayı harita üzerinde kaydırma.
- **Fare Tekerleği (Scroll):** Kamerayı yakınlaştırma / uzaklaştırma.
- **B Tuşu:** Sağ alttaki kategorili **İnşa** dükkanını açma / kapatma.
- **F Tuşu:** **Yangın riski** haritasını açma / kapatma (alev ikonlu buton).
- **N Tuşu:** **Toprak nemi** haritasını açma / kapatma (damla ikonlu buton).
- **R Tuşu:** Seçili binayı veya yerleştirilmekte olan binayı 90° döndürme.
- **Sağ Tık (Tek):** İnşa/taşıma modunu iptal etme; yol döşeme modunda yol hücresini silme (+5 altın iade).
- **Esc:** Seçili binayı/modu bırakma veya oyunu duraklatma (duraklatma menüsünde **9 kartlı Nasıl Oynanır** rehberi ve TR/EN dil seçimi yer alır).

---

## Jüri Kriterleri Eşleşmesi

| Kriter | Oyundaki Karşılığı ve Tasarım Çözümü |
|---|---|
| **Odak Tema (Gıda Güvenliği, İklim Direnci & COP31)** | Yarışmanın **gıda güvenliği** teması oyunun merkezindedir: tarla ve seralarda iklime göre ürün seçimi (su isteyen kavun vs. kuraklığa dayanıklı buğday), ürün çeşitliliği refah bonusu, ambar depolama kapasitesi, kuraklıkla fiyatların arttığı pazar mekaniği, sıcak stresi, kuru toprağın yavaş büyümesi, toprak nemi (`N`) ve yangın riski (`F`) haritaları, damla sulama (-%40 su), COP31 yerel iklim politikaları ve COP27/COP31 Kayıp ve Zarar Fonu (+120 acil yardım) doğrudan oynanışa dönüştürüldü. Finalde hem *"Köylüler zamanın %X'inde tok"* hem de *"Önlem vs Hasar"* karnesi sunulur. |
| **Yaratıcılık ve Özgünlük** | Toros dağları, Akdeniz kıyısı, naylon seraları, portakal/zeytin bahçeleri ve ağustos böceği sesleriyle yaşayan **3D Antalya köyü**; yerel "Muhtar" kimliği, 6 özgün karakterin sunduğu ikilem kartları (anız yakma, su paylaşımı vb.), yol bağlantısı lojistiği ve canlı 3D kamera üstünde oynanan yangın söndürme mini oyunuyla özgün bir strateji deneyimi sunar. |
| **Oynanabilirlik ve Oyun Tasarımı** | 3 ay × 4,5 dk (~14 dk) akış; 3D kamera ve ürün seçimi öğreticisi, kategorili 3D **İnşa dükkanı**, **bina üstü yuvarlak işlem butonları** (döndürme ve yarı fiyatına bina satma dahil), yol silgi modu, **dokunarak +%15 bonuslu hasat** ve **9 kartlı Nasıl Oynanır** ekranı ile erişilebilirdir. **Zorluk dengesi** otomatik botlarla doğrulanmıştır: pasif oyun kaybeder (refah 0), önlemsiz/açgözlü oyun sıcak stresi ve kuraklık karşısında başarısız olur (6–8 refah), akıllı ve önlem alan oyun ise 100 refah ve 2–3 yıldızla kazanır. |
| **Teknik İşlevsellik** | **2D simülasyon mantığı + 3D görüntü katmanı (`WorldView3D`)** mimarisiyle Godot 4.7 GL Compatibility modunda (masaüstü ve WebGL uyumlu) geliştirildi. MultiMesh ile binlerce kızılçam/zeytin ağacı ve kaya, web uyumlu `CPUParticles3D` efektleri, AStarGrid2D işçi ve itfaiye yol bulma, SubViewport ile üretilen 3D dükkan/portre önizlemeleri (`Thumbs`), modüler Blender `.glb` otomatik yükleme sistemi (`docs/BLENDER_NAMING.md`) ve çok tohumlu denge/kaos botlarıyla 0 hata ve ~200 FPS masaüstü performansı doğrulandı. |
| **Sunum ve İletişim** | Arkada gün batımında yaşayan ve yavaşça dönen 3D köy üzerinde **Witcher tarzı solda dikey ana menü**, Google Fonts *Cinzel* ve *Alegreya Sans* tipografisi, elinde çapa/balta/kova ile çalışan animasyonlu 3D köylüler (kuyudan su kulesine kova taşıma dahil), civciv/inek/köpek, gece pencere ve sokak lambası ışıkları, kurakta sararan ağaçlar ve daralan nehir ile güçlü bir görsel atmosfer oluşturuldu. |
| **Zaman Yönetimi ve Takım** | Sürüm 1'den Sürüm 4.6'ya kadar tüm aşamalar (2D temel → 32×22 vadi → oyun hissi → **Sürüm 4 tam 3D Antalya köyü, gıda güvenliği ve zorluk cilası**) eksiksiz tamamlandı; 2D yedek paketler (`build/backup_2d/`) korunarak ana 3D Windows ve Web paketleri teslimata hazırlandı. |

---

## 60 Saniyelik Tanıtım Videosu Çekim Senaryosu (`docs/VIDEO_SHOTLIST.md` ile Uyumlu)

| # | Süre | Ekranda Ne Olacak? (3D Görsel Akış) | Dış Ses Metni (Voiceover) |
|---|---|---|---|
| **1** | **00:00 – 00:06** | Witcher tarzı solda dikey ana menü; arkada gün batımı ışığında yavaşça dönen 3D Antalya köyü, badanalı evler, seralar ve yürüyen köylüler. | *"Antalya'da kuraklıkla boğuşan bir köyün muhtarısın. COP31 seni üç sıcak yaz ayı boyunca köyü doyurmak ve ayakta tutmakla görevlendirdi."* |
| **2** | **00:06 – 00:14** | Kamera sağ tıkla döndürülerek kuzeydeki Toros dağları, kızılçam ormanları ve güneydeki Akdeniz kıyısı gösterilir; Rehber Hasan Dayı ve Elif'in Haziran görev kartı ekrana gelir. | *"Toroslar'dan Akdeniz'e uzanan bu vadide her derece sıcak, toprağın suyunu biraz daha tüketiyor."* |
| **3** | **00:14 – 00:24** | Sağ alttaki **İnşa** dükkanı açılır; 3D önizlemeli kartlardan **Ambar**, **Sera** ve **Tarla** seçilip yola bitişik yerleştirilir (`R` ile döndürülür), binalar gökyüzünden toz kaldırarak düşer; tarla ve serada **Ürün seç** ile kuraklığa dayanıklı **Buğday** seçilir. | *"Köyü doyurmak için ambar kur, ürünleri çeşitlendir ve kuraklık arttıkça az su isteyen buğdaya ve örtü altı seralara yönel."* |
| **4** | **00:24 – 00:32** | Köylüler çapayla çalışır ve kuyudan su kulesine kova taşır; olgun tarlada **hasat balonuna dokunulur** (+%15 bonus), altın/ürün ikonları üst çubuğa uçar; **Pazar** penceresi ile **N (Toprak nemi)** ve **F (Yangın riski)** haritaları gösterilir. | *"Hasadı zamanında topla, ambarı doldur ve toprak nemi haritasıyla damla sulamayı ihmal etme."* |
| **5** | **00:32 – 00:40** | Gün batımı ve gece geçişi: evlerin pencereleri ve **sokak lambaları** yanar; gündüz olduğunda Fatma Teyze'nin **"Anız yakma izni"** karar kartı çıkar ve reddedilir. | *"Gece serinliği köye nefes aldırırken, gündüz vereceğin her karar köyün geleceğini belirler."* |
| **6** | **00:40 – 00:52** | Ağustos sıcağında sararan ağaçlar, sıcak stresi ve daralan nehir; bir tarlada alev ve kara duman yükselir! Siren ışıklı **3D itfaiye aracı** yol ağından hızla ulaşır ve **hortum mini oyununda** alevler söndürülür. | *"Kuruyan toprakta yangın çıktığında, kurduğun yollar ve dolu su depon itfaiyenin en büyük gücü olacak!"* |
| **7** | **00:52 – 01:00** | 3 yıldızlı final ekranı: arka planda gündüz konfetileri, *"Köyün örnek oldu!"*, *"Gıda güvenliği: köylüler zamanın %X'inde tok"* ve Önlem vs Hasar çubukları. | *"Unutma: Her derece, bir tarla daha. İklim değişikliğinde önlem almak, sonradan müdahale etmekten hep daha ucuzdur!"* |

---

## Emeği Geçenler (Künye)

- **Tasarım ve Geliştirme:** Erdem Sosar, Berke Buyruk
- **3D Modeller ve Ses Efektleri:** Kenney (`kenney.nl`) — *Nature Kit, Fantasy Town Kit, Car Kit, Mini Characters, Cube Pets, Interface / Impact / RPG Audio* (tümü CC0 lisansı; Antalya renk paleti uyarlaması proje içinde yapıldı). *(Pixel paketleri: Tiny Town, Tiny Farm, Pixel UI Pack — `build/backup_2d/` altındaki yedek 2D sürüm için kullanılmıştır, CC0).*
- **Fontlar:** *Cinzel* ve *Alegreya Sans* (Google Fonts, SIL Open Font License).
- **Müzik ve Döngü Sesleri:** Proje içinde prosedürel olarak üretildi (`tools/synth_audio.py` — Hicaz makamı tema müziği ve ağustos böceği korosu).
- **Oyun Motoru:** Godot Engine 4 (MIT lisansı)
