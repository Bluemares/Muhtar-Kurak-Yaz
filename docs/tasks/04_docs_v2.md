# Görev 04 — Sunum metinlerini Sürüm 2'ye göre güncelle

**Amaç:** Oyun büyük ölçüde değişti. Jüri ve itch.io metinleri eski sürümü anlatıyor. Bu görevde üç dosyayı güncelle. Kod yok.

## Güncellenecek dosyalar
- `docs/SUNUM.md`
- `docs/PRESENTATION_EN.md`
- `docs/ITCH_PAGE.md`

## Kaynak (doğru bilgi buradan)
- `docs/ROADMAP.md` → "Sürüm 2" tablosu ve "Yapılanlar günlüğü" (V1–V10 maddeleri).
- `scripts/autoload/balance.gd` → sayılar (ay süresi 270 sn, fiyatlar, bina maliyetleri).
- `i18n/strings.csv` → oyun içi adlar (politika, başarım, bina adları).
- Ekran görüntüleri: `tests/shots/` (01_menu, 11_august, 13_night, 15_decision, 16_rain, 17_policy, 08_final_good, 18_achievements, 12_valley).

## Eklenmesi gerekenler (her üç dosyada, uygun bölümlere)
1. **Oyun süresi:** 3 ay × 4,5 dk ≈ 14 dk.
2. **Büyük harita:** 32×22 vadi, nehir + köprü, orman/kayalık; COP31 seviyesiyle iki kez genişler. Nehir kuraklıkla kurur; nehir kenarı kuyular bonus su verir.
3. **Yeni binalar:** su kulesi, sera, koruluk (açıklamalarıyla).
4. **Gündüz-gece:** ay başına 3 gün; gece serin → yangın riski düşük; akşam pencereler yanar.
5. **Olaylar ve kararlar:** 6 köylü kartı (anız yakma dahil) + sıcak hava dalgası (erken uyarı) + yağmur.
6. **COP31 politika kartları:** 9 politika, ay sonunda 3'ten 1.
7. **Yan görevler:** her ay 3 tane.
8. **Puan, yıldız, başarımlar:** 9 başarım, en iyi skor.
9. **Kayıt:** otomatik kayıt + "Devam et".
10. **Pixel arayüz:** Kenney Pixel UI Pack + Kenney Pixel font; Türkçe harfler projede üretildi.
11. **Jüri kriterleri tablosu:** yeni mekaniklerle güncelle (özellikle "Odak tema": anız yakma, erken uyarı, Kayıp ve Zarar Fonu, damla sulama, nehrin kuruması).
12. **Emeği geçenler:** Kenney Tiny Town, Tiny Farm, Pixel UI Pack, Kenney Fonts, Interface/Impact/RPG Audio (hepsi CC0); müzik/döngü sesleri projede üretildi; Godot 4 (MIT). Ekip: Erdem Sosar, Berke Buyruk.
13. **Ekran görüntüsü alt yazıları** (ITCH_PAGE): yukarıdaki yeni görüntüler için.
14. **60 sn video senaryosu** (SUNUM): `docs/VIDEO_SHOTLIST.md` ile uyumlu olsun; gece ve karar kartı planı ekle.

## Kurallar
- Sayıları uydurma; sadece kaynak dosyalardaki değerleri kullan.
- Gerçek dünya iklim istatistiği yazma.
- Başka dosyaya dokunma. Bitince `docs/tasks/README.md` tablosuna 04 satırını "tamam" olarak ekle.
