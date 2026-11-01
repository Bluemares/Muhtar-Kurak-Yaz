# Görev 2 — Sunum metinleri (jüri için)

## Bağlam
"MUHTAR: KURAK YAZ" — COP31 Türkiye / HP - ICPSD - UNDP Game Jam demosu. Godot 4.
Oyunu anlamak için oku (DEĞİŞTİRME): `scripts/autoload/balance.gd` (tüm sayılar), `i18n/strings.csv` (oyundaki metinler),
`scripts/game/game.gd` (akış). Tasarım özeti aşağıda.

Özet: Oyuncu, COP31'in deneme süresiyle atadığı muhtardır. Haziran-Temmuz-Ağustos (3 tur × 3 dk) boyunca köyü
kuraklığa (su tüketimi artar), böceklere (ilaçlama) ve yangınlara (itfaiye sinematiği + hortum minigame'i) karşı korur.
Ürün anında satılır, refah = (doyma + su + sağlam bina)/3. Yollar yükseldikçe işçi ve itfaiye hızlanır. İtfaiye istasyonu
taşınabilir: merkeze koymak yangına varışı kısaltır. Final ekranı "önleme harcanan vs yangın hasarı" karşılaştırması gösterir.
Mesaj: "Her derece, bir tarla daha." İklim değişikliğinde önlem, müdahaleden ucuzdur.

## Yapılacak (yalnızca `docs/` altına yeni dosyalar)
1. `docs/SUNUM.md` (Türkçe):
   - Oyun açıklaması (150 kelime), nasıl oynanır (madde madde, kontroller: sol tık seç/yerleştir, sağ tık iptal,
     sağ/orta tık sürükle kamera, tekerlek zoom, WASD/oklar kamera, Esc duraklat).
   - Jüri kriterleri eşleşmesi tablosu: Odak tema, Yaratıcılık/özgünlük, Oynanabilirlik/oyun tasarımı, Teknik işlevsellik,
     Sunum/iletişim, Zaman yönetimi/takım.
   - 60 saniyelik tanıtım videosu çekim senaryosu (sahne sahne, saniye aralıkları, ekranda ne olacak, dış ses metni).
2. `docs/PRESENTATION_EN.md`: yukarıdakinin İngilizce kısa hali (açıklama + nasıl oynanır + kriterler tablosu).

## Bitti sayılır
- İki dosya var, oyunla çelişen bilgi yok (sayıları balance.gd'den doğrula).
