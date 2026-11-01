# Görev 06 — Sunum metinlerini Sürüm 4'e (3D Antalya köyü) güncelle

**Amaç:** Oyun pixel 2D'den 3D Antalya köyüne geçti. Jüri, itch.io, video ve teslim belgeleri hâlâ pixel sürümü anlatıyor. Kod yok.

## Güncellenecek dosyalar
- `docs/SUNUM.md`
- `docs/PRESENTATION_EN.md`
- `docs/ITCH_PAGE.md`
- `docs/VIDEO_SHOTLIST.md`
- `docs/RELEASE_CHECKLIST.md`

## Kaynak
- `docs/ROADMAP.md` → "Sürüm 4" tablosu (X1–X10) ve günlükteki "1 Kasım — X…" maddeleri.
- `docs/MODELS_3D.md`, `docs/BLENDER_NAMING.md`.
- Ekran görüntüleri: `tests/shots/01_menu.png`, `3d_04b_taurus.png`, `3d_04c_sea.png`, `3d_06_buildings.png`, `3d_09_actors.png`, `3d_11_fire_bubble.png`, `3d_12_night.png`, `3d_14_shop.png`, `07_minigame.png`, `08_final_good.png`, `09_final_lost.png`.

## Değiştirilecekler (her dosyada uygun bölüme)
1. "Pixel art" geçen tanımları kaldır: oyun artık **3D, serbest dönen diorama kameralı** bir köy yönetim oyunu. Sahne: **Antalya'da bir köy** (Toros dağları, Akdeniz kıyısı, kızılçam, zeytinlik, portakal bahçesi, naylon seralar, badanalı kiremit çatılı evler, ağustos böceği sesi).
2. **Kontroller** bölümünü yenile: sol tık seç/inşa/hasat; **sağ tık sürükle → kamerayı döndür ve eğ**; **Q / E → döndür**; orta tık sürükle veya WASD → kaydır; tekerlek → yakınlaş; B → İnşa dükkanı; Esc → seçim iptali / duraklat. Sağ tık yol modunda yolu siler, inşa modunda iptal eder.
3. **Görsel öğeler**: Witcher tarzı solda dikey ana menü (arkada gün batımında dönen köy), animasyonlu köylüler, itfaiye aracı (siren ışığı), civciv/inek/köpek, alev-duman-kıvılcım, gece pencere ışıkları, yağmur, kurakta sararan ağaçlar ve daralan nehir, 3D dükkan kartları ve karakter portreleri.
4. **Jüri kriterleri tablosu**: "Teknik uygulama" satırına 3D'ye geçişi (Godot 4 Compatibility, web'de çalışır, 2D mantık + 3D görüntü katmanı, MultiMesh, CPU parçacıkları) ve "Sunum" satırına yukarıdaki görsel öğeleri işle. "Zaman yönetimi" satırına Sürüm 4'ü ekle.
5. **Künye**: Kenney paketlerine *Nature Kit, Fantasy Town Kit, Car Kit, Mini Characters, Cube Pets* ekle (hepsi CC0). Fontlar: *Cinzel* ve *Alegreya Sans* (Google Fonts, SIL Open Font License). Pixel paketleri (Tiny Town, Tiny Farm, Pixel UI) yedek 2D sürüm için kalabilir, "yedek sürüm" diye belirt.
6. **VIDEO_SHOTLIST**: 60 sn planı 3D'ye göre yeniden yaz: menü (dönen köy) → kamerayı döndürerek köyü tanıtma → dükkandan bina + düşüş → dokunarak hasat → gün batımı/gece → yangın + itfaiye aracı + mini oyun → Ağustos (sararan ağaçlar) → final ekranı.
7. **ITCH_PAGE**: yukarıdaki görüntüler için birer cümlelik alt yazı; kısa açıklamanın ilk cümlesi "Antalya'da kuraklıkla boğuşan bir köyün muhtarısın." gibi 3D ve Antalya'yı öne çıkarsın.
8. **RELEASE_CHECKLIST**: 2D yedek zip'lerin `build/backup_2d/` altında olduğunu ve teslimde **3D zip'lerin** (`build/MuhtarKurakYaz_web.zip`, `MuhtarKurakYaz_windows.zip`) yükleneceğini yaz.

9. **Ana tema gıda güvenliği** (yarışmanın teması): tüm metinlerde oyunu önce "kuraklıkta köyü doyurmak" olarak anlat; yangın kuraklığın bir sonucu, ikinci planda. Yeni gıda sistemleri: ambar (kapasite) ve pazar (kuraklıkla fiyat artar, al/sat), gıda güvenliği göstergesi (kaç günlük yiyecek), ürün seçimi (sebze/kavun/mısır/buğday; buğday kurakta dayanıklı) ve "önerilen ürün", ürün çeşitliliği refah bonusu, toprak nemi haritası. Görevler: Haziran "Köyü doyur", Temmuz "Ambarı doldur" (2 günlük yiyecek), Ağustos "Kuraklıkta sofra" (3 çeşit ürün, açlık yok). Final ekranında "Gıda güvenliği: köylüler zamanın %X'inde tok".

## Kurallar
- Sayıları uydurma; yalnız kaynak dosyalardaki değerleri kullan. Gerçek dünya istatistiği ekleme.
- Ekip: Erdem Sosar, Berke Buyruk.
- Başka dosyaya dokunma. Bitince `docs/tasks/README.md` tablosuna 06 satırını "tamam" olarak ekle.
