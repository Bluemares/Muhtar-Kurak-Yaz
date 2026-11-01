# Açılış ve FPS kontrolü — 1 Kasım 2026

Kahverengi motor açılış zemini ve ana menünün koyu fade-in katmanı kaldırıldı.
Windows başlangıç penceresi şeffaf, çerçevesiz 1 piksel olarak tutuluyor; ilk
menü karesi çizildikten sonra kayıtlı pencere/tam ekran ayarı uygulanıyor.
Yükleme süresi yok edilmedi: bu makinede ana menü yaklaşık 3 saniyede hazır.
Normal oyun sırasında şeffaflık kapalı; uygulama simgesi korunuyor.

Yöntem: [Godot: Hiding the window during the splash screen](https://docs.godotengine.org/en/latest/tutorials/ui/creating_applications.html#hiding-the-window-during-the-splash-screen).
Godot 4.5.1 pencereli ve 4.7.1 tam ekran başlangıç testleri geçti; ilk görünür
menü kareleri incelendi. Son dağıtım EXE'si mevcut tam ekran ayarıyla açılıp
kapandı, çalışma zamanı hata kaydı boş. Windows ve web çıktıları güncellendi.

## Windows release ölçümü

- GPU: NVIDIA GeForce RTX 4050 Laptop GPU, OpenGL Compatibility.
- CPU: Intel Core i7-13620H.
- Godot/export şablonu: 4.5.1 release. VSync kapalı, FPS sınırı yok.
- Gerçek çizilmiş karelerin duvar saati aralıkları ölçüldü; zaman hızlandırılmadı.
- Sahne yükleme/ısınma ölçüm dışı. Normal sahnelerde 8, itfaiye çıkışında 6,
  mini oyunda 5 saniye örnek alındı. Tek makinedeki kısa örneklerdir; tüm
  cihazlar, uzun oyun seansları veya tarayıcı performansı için garanti değildir.
- Oyuncunun kayıtları kullanılmadı; test ayrı geçici proje ve EXE klasöründe.

| Sahne | Çözünürlük | Ortalama FPS | %95 kare süresi | %99 kare süresi |
|---|---|---:|---:|---:|
| Ana menü | 1280×720 | 134.0 | 8.93 ms | 11.38 ms |
| Başlangıç köyü, 6 bina / 4 köylü | 1280×720 | 182.3 | 6.76 ms | 8.02 ms |
| Başlangıç köyü, 6 bina / 4 köylü | 1920×1080 | 146.7 | 8.32 ms | 10.16 ms |
| Yoğunluk senaryosu, 18 bina / 16 köylü | 1920×1080 | 72.7 | 16.02 ms | 24.27 ms |
| İtfaiye çıkışı / sinematik | 1920×1080 | 127.8 | 10.70 ms | 11.73 ms |
| Yangın mini oyunu | 1920×1080 | 84.5 | 13.59 ms | 15.28 ms |

Bu örneklerde 50 ms üstü kare yok. Yoğun köyde yaklaşık 4424 çizim çağrısı,
başlangıç köyünde yaklaşık 1821 çağrı ölçüldü. Yoğunluk arttığında belirgin
performans düşüşü var; kalıcı 60 FPS altı durum bu testte görülmedi, ancak her
karenin 60 FPS bütçesine sığdığı söylenemez. Sonraki optimizasyon için statik
bina/ürün parçalarının çizimlerini birleştirmek ve köylü hareket/çarpışma
hesaplarını profillemek uygun adaylar. Bu turda görsel kalite veya animasyon
basitleştirmesi yapılmadı.

Normal oyunda F9 mevcut FPS göstergesini açar/kapatır. VSync açık olduğunda
değer ekranın yenileme hızıyla sınırlanabilir.

Tekrarlanabilir test: `tools/run_tests.py perf --visual --godot <godot.exe>`.
Release testinde aynı sahne ayrı bir geçici EXE'ye paketlendi. Ölçüm kodu
`tests/perf.gd`; testler ve geliştirme galerisi dağıtım dışı kalmaya devam ediyor.
