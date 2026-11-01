# Teslim Kontrol Listesi (Sürüm 4.6 — 3D Antalya Köyü)

## Build alma ve Yedekler

```
B:\Godot\godot.exe --headless --path . --export-release "Windows" build/windows/MuhtarKurakYaz.exe
B:\Godot\godot.exe --headless --path . --export-release "Web" build/web/index.html
python -I tools/package.py .
```

- **Teslimde yüklenecek ana 3D paketler:**
  - `build/MuhtarKurakYaz_web.zip` (3D WebGL build)
  - `build/MuhtarKurakYaz_windows.zip` (3D Windows tek çalıştırılabilir paket)
- **2D yedek paketler:** Sürüm 3 (2D pixel) yedek zip'leri `build/backup_2d/` klasörü altında (`MuhtarKurakYaz_web.zip`, `MuhtarKurakYaz_windows.zip`) saklanmaktadır (`Bal.RENDER_3D = false` karşılığı). **itch.io tesliminde `build/` kökündeki 3D zip'ler yüklenecektir.**

## itch.io yükleme

1. **Web (3D):** `build/MuhtarKurakYaz_web.zip` yükle → *"This file will be played in the browser"* işaretle.
   - Viewport: `1280 × 720`, *"Fullscreen button"* açık, *"Mobile friendly"* kapalı.
   - SharedArrayBuffer **gerekmez** (tek iş parçacıklı Compatibility build).
2. **Windows (3D):** `build/MuhtarKurakYaz_windows.zip` yükle → platform: Windows.
3. **Sayfa metni ve görseller:** Metinler `docs/ITCH_PAGE.md` (Görev 07 — Sürüm 4.6). Kapak ve ekran görüntüleri: `tests/shots/01_menu.png`, `3d_04b_taurus.png`, `3d_04c_sea.png`, `3d_06_buildings.png`, `3d_09_actors.png`, `3d_11_fire_bubble.png`, `3d_12_night.png`, `3d_14_shop.png`, `07_minigame.png`, `08_final_good.png`, `09_final_lost.png`.

## Otomatik testler (hepsi geçmeli)

Not: Bir script değiştikten sonra ilk çalıştırmayı tek süreçle yap (paralel Godot süreçleri önbellek yarışına giriyor).

| Test | Komut | Beklenen |
|---|---|---|
| Duman | `godot --headless --path . res://tests/smoke_test.tscn` | `TEST \| BITTI`, SCRIPT ERROR yok |
| Denge | `... res://tests/balance_bot.tscn -- smart 7` | akıllı kazanır (refah 100, 2–3 yıldız); önlemsiz başarısız (6–8 refah); pasif kayıp |
| Kaos | `... res://tests/balance_bot.tscn -- chaos 5` | 0 SCRIPT ERROR |
| Kayıt | `... res://tests/save_test.tscn` | 12 × SAVE OK |
| 3D Görseller | `godot --path . res://tests/shots3d.tscn` | `tests/shots/3d_*.png` hatasız üretilir |

## Elle oynanış (teslimden önce bir kez, ~15 dk)

- [ ] **Witcher tarzı 3D Ana Menü ve 9 Kartlı Nasıl Oynanır:** Arkada gün batımında dönen 3D Antalya köyü; solda Devam et (kayıt varsa), Yeni Oyun, Nasıl Oynanır (9 kart: *Ambar ve pazar* dahil), Ayarlar, Başarımlar, Emeği geçenler, TR/EN; Cinzel ve Alegreya Sans fontları net okunuyor.
- [ ] **3D Kamera ve Antalya Vadisi:** Sağ tık sürükle ile döndürme/eğme, `Q/E` ile döndürme, tekerlek ile yakınlaşma, `WASD`/orta tık ile kaydırma, binaya çift tıkla odaklanma; kuzeyde Toroslar, güneyde Akdeniz, gündüz ağustos böceği sesi.
- [ ] **Öğretici:** Hasan Dayı 3D portresiyle konuşuyor; kamera kontrol adımı → COP31 → tarla → ürün seçimi → kuyu → su deposu → yol şartı → taşıma → İnşa dükkanı → tarla kurma.
- [ ] **Gıda Güvenliği, Tarla/Sera Ürün Seçimi, Sıcak Stresi, Ambar ve Pazar:** Tarla ve serada *Ürün seç* (`Sebze (havuç)` / `Kavun` / `Mısır` / `Buğday` + `»` önerilen ürün ipucu); ürün çeşitliliği refah bonusu; görev panelinde *Sıcak stresi −X*; kuru tarlanın yavaş büyümesi; Ambar (+100 kapasite) ve Pazar (10'luk al/sat, kuraklıkla artan fiyat).
- [ ] **Yol Şartı, Yol Silgi Modu ve Arazi Temizleme:** **COP31 ve koruluk dışındaki her bina** yola bitişik değilse çalışmıyor ("yol yok" rozeti; koruluk yolsuz da çalışıyor); Altyapı'dan yol döşeme (10 altın), **Yol sil** butonu (sol tık silgi) veya sağ tıkla silme (+5 iade) ve kaya/ağaç temizleme (boştaki köylü baltayla gidip 4 sn'de temizliyor).
- [ ] **3D İnşa Dükkanı (B), Döndürme (R), Bina Satma ve Köy Hayatı:** 3D model önizlemeli kartlar, seçili veya yerleştirilen binayı `R` ya da *Döndür* ile çevirme, COP31/itfaiye dışındaki binaları *Sat* butonuyla onaylı yarı fiyatına kaldırma; köylülerin tarla/serada çapayla çalışması ve kuyunun dibinden kova doldurup su kulesine taşıması.
- [ ] **Ayrı Yangın Riski (F) ve Toprak Nemi (N) Haritaları:** Sağ alttaki `Risk (F)` (alev ikonu) ve `Nem (N)` (damla ikonu) butonlarıyla iki harita katmanının ayrı ayrı açılıp kapanması.
- [ ] **Yangın ve Canlı 3D Mini Oyun:** İtfaiye aracı siren ışıklarıyla yol ağını izleyerek geliyor; canlı 3D kamera görüntüsü üzerinde hortum mini oyunu (su deposundan dolum, tank boşalınca uyarı).
- [ ] **Gece, Karar Kartları ve COP31 Politikaları:** Gece ev pencereleri ve sokak lambaları yanıyor; 6 karakterin karar kartları ve ay sonu 3'ten 1 COP31 politika seçimi çalışıyor.
- [ ] **Final Ekranı ve Yıldız Şartları:** 1–3 yıldız (3 yıldız = 3 görev + zamanın ≥%90'ında tok + ≤2 yanık bina; 2 yıldız = ≥2 görev ve %80+ refah), puan, rekor, başarımlar, *"Gıda güvenliği: köylüler zamanın %X'inde tok"* ve *"Önleme harcanan vs Yangın hasarı"* karşılaştırması.
- [ ] **Web 3D Build:** itch.io üzerinde tarayıcıda açıp kamera döndürme, bina seçimi ve bir ay oynanışı doğrula (`F9` ile FPS kontrolü).

## Bilinen sınırlar

- Windows exe dosya ikonu Godot varsayılanı (pencere ve görev çubuğu ikonu oyunun kendi ikonu).
- Debug tuşları (`F1–F7`) sadece editör çalıştırmasında; release build'de kapalıdır (`F9` FPS sayacı açıktır).
