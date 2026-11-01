# 01 — Binalar

Klasör: **`assets/models/buildings/`**. Oyun önce seviyeye özel dosyayı (`<tür>_l<seviye>.glb`), yoksa genel dosyayı (`<tür>.glb`), o da yoksa Kenney parçalarından kurduğu modeli kullanır (`scripts/world3d/building_kit.gd`).

Taban ölçüsü hücre cinsinden; modelin ayak izi bu alanın **%90'ını** geçmesin (komşu binalarla iç içe görünmesin). Yükseklikler şu anki modelin yaklaşık değeri, aynısı olmak zorunda değil.

| Dosya adı | Bina | Taban (en × derinlik) | Yükseklik ≈ | Seviyeler | Şu an neyden yapılı | Notlar / istek |
|---|---|---|---|---|---|---|
| `house.glb` | Ev | 1 × 1 | 1.35 | 1 | Kenney duvar + kapı + panjurlu pencere, kırma kiremit çatı, saksı, bazen baca | Beyaz badana, kiremit kırma çatı, kapı +Z'de, kapı önünde saksı/begonvil |
| `cop31_l1.glb` | COP31 Binası (köy merkezi) | 2 × 2 | 1.7 | 1 | Taş sütunlu tek katlı belediye, kemerli kapı, kiremit çatı | Ön cephede "COP31" tabelası **modelde** olmalı (özel model gelince oyun yazıyı eklemez) |
| `cop31_l2.glb` | COP31 Lv2 | 2 × 2 | 2.7 | 2 | İkinci kat + bayrak direği | |
| `cop31_l3.glb` | COP31 Lv3 | 2 × 2 | 2.7 | 3 | Lv2 + ön cephede yeşil sancaklar | Daha görkemli: saat kulesi, iklim temalı süs |
| `fire_station.glb` | İtfaiye | 2 × 1 | 1.3 | 1 | Kırmızı sıvalı geniş garaj, düz çatı, siren direği, "İTFAİYE 112" yazısı | Garaj kapısı +Z'de; yazı modelde olmalı |
| `well_l1.glb` … `well_l3.glb` (ya da `well.glb`) | Kuyu | 1 × 1 | 1.15 | 1–3 | Taş bilezik + iki direk + kiremit şapka; Lv2 fener, Lv3 kova | |
| `field.glb` | Tarla (sebze bahçesi) | 2 × 2 | 0.05 | 1–3 | 4 sıra toprak sırası | **Sadece toprak.** Bitkiler ayrı modeller (02_doga'daki `crop_*` / `crops_*`), oyun büyüme evresine göre üstüne dizer |
| `greenhouse.glb` | Sera | 2 × 1 | 0.8 | 1 | Naylon tünel (yarı saydam, köylünün içine sığacağı yükseklikte), 5 kaburga, toprak taban | **Bitki koyma**: oyun seçilen ürünü (sebze/kavun/mısır/buğday) 2 sıra × 4 bitki olarak içine dizer ve büyütür. Örtü yarı saydam (Alpha Blend, alpha ≈ 0.45); içi görünsün, tünel içi ≈ 0.75 yüksek (köylü çapalarken sığsın) |
| `water_tower.glb` | Su deposu | 1 × 1 | 2.15 | 1 | 4 ahşap ayak, beyaz tank, mavi şerit, kiremit kapak | Antalya'daki çatı tankları gibi de olabilir |
| `grove.glb` | Koruluk (portakal bahçesi) | 1 × 1 | 0.8 | 1 | Sulanmış koyu toprak + 3 küçük portakallı ağaç | Turuncu meyveler görünsün (yangını kesen sulanan ağaçlar) |
| `granary.glb` | Ambar (yiyecek deposu) | 2 × 1 | 1.5 | 1 | Ahşap duvarlı depo, kiremit kırma çatı, kapı önünde çuvallar | Antalya serendere/ambar: taş temel, ahşap gövde; çuval, küp, sepet |
| `lamp.glb` | Sokak lambası | 1 × 1 | 1.4 | 1 | Taş kaide, ahşap direk, fener | Fener camı ≈ 1.2 yükseklikte olsun; oyun ışığı ve parlayan küreyi oraya koyar |

## Durumlar (modellemen gerekmez)

- **Yanıyor:** oyun binanın üstüne turuncu titreşen bir katman + alev/duman parçacıkları ekler.
- **Harap:** binayı koyulaştırır ve yüksekliğini %55'e basar, duman tüter. İstersen ayrıca `<tür>_ruined.glb` hazırlayabilirsin (henüz kodda yok, eklenebilir).
- **İnşa ediliyor:** yanıp sönen açık bir katman.
- **Döndürme:** oyuncu binayı 90° (dikdörtgen binalarda 180°) döndürebilir; modelin her yüzü güzel görünsün.

## Binadaki işler (karakter animasyonları için bkz. 03)

- **Tarla / sera:** köylü bitki sıraları arasında çapa vurur (`hoe`), olgun ürünü toplar (`harvest`).
- **Kuyu:** köylü kovayı ipe bağlayıp çeker (`draw-water`), su kulesine taşır (`carry`).
- **Arazi temizliği:** köylü ağaca/kayaya balta vurur (`chop`).
- **Ambar:** çuval/sepet taşıma (`carry`).

## Bina üstü bilgiler

Seviye yıldızları, işçi rozeti, hasat balonu, risk yüzdesi, "yol yok" uyarısı arayüzde çizilir; modelde olmasın.
