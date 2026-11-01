# Asset temizliği ve test raporu — 2026-11-01

## Sonuç

406 dosya (200 GLB model + eski theme.wav, splash.png ve alegreya_sans_400.ttf; import eşleri dahil), toplam 5.560.260 bayt / 5,30 MiB kaldırıldı. Liste ve SHA-256 özetleri: [ASSET_CLEANUP_MANIFEST.json](ASSET_CLEANUP_MANIFEST.json). Eski dosyalar Git geçmişinden geri alınabilir; geçmiş yeniden yazılmadı.

Doğa, kasaba ve araç paketlerindeki kullanılmayan modeller ayıklandı. Kaynak kod, sahneler, dinamik model seçim listeleri, testler ve araçlar tarandı. Karakterler, hayvanların .glb.source dosyaları, bina override'ları, dokular, lisanslar, 2D alternatifin varlıkları, geliştirme galerisi ve test kaynakları korundu. Galeri kalan model envanterini otomatik listeler. Kişisel sunumlar, oyuncu kayıtları ve yerel build/download klasörleri bu temizliğin kapsamında değildir.

`tools/audit_assets.py` salt okunur, ihtiyatlı model aday taramasıdır; genel amaçlı bir erişilebilirlik ispatı değildir. Dinamik çağrılar elle incelendi. Yol kartındaki `car/cone` görsel testte doğrulanıp korundu; ilgili test tekrar geçti. Tüm font/ses/görsel ve script referanslarının ek taramasında doğrulanmış başka silme adayı kalmadı.

## Doğrulama

Godot 4.7.1.stable, Windows, NVIDIA RTX 4050. Orijinal proje dışında geçici kopyalar kullanıldı. Öncesinde ve sonrasında önbelleksiz import başarılı.

- Temizlik öncesi headless: 18 PASS, render gerektiren 13 SKIP.
- Temizlik sonrası pencereli tam paket: 30 PASS, 1 FAIL (aşağıda).
- Son düzeltmelerden sonra shots3d ve skin_compare önbelleksiz importla tekrar PASS; eksik model uyarısı yok. skin_compare olmayan isteğe bağlı Blender araçlarını açıkça OPTIONAL_MODEL_SKIP olarak raporluyor; üretimdeki prosedürel araçların varlığı equipment_motion/work_closeups ile sınanıyor.
- Tarım döngüsü seed 1, 3, 7, 31: PASS. Sera varyantı seed 3: PASS.
- Chaos bot seed 3: PASS; 12 yangın, 13 yanan bina, çökme yok (tam oyun sonuna ulaştı).
- Python araç kontrolleri: 10 PASS (9 test koşucusu + çalışma kopyasında bulunan 1 paketleme testi).
- Windows user:// izolasyonu gerçek Godot sürecinde doğrulandı. Koşucuya clean-import ve bot politika seçimi eklendi; sunum ve karşılaştırma çıktı klasörleri geçici kopyadan dışlandı.
- Tarla yakın planı ve köy görüntüsü görsel olarak incelendi. Performans sahnesi geçti; eşzamanlı testler nedeniyle bu koşunun FPS değerleri bağımsız benchmark sayılmaz.

### Açık bulgu: resume_context

İşlevsel kayıt/geri yükleme kontrolleri geçiyor. Pencereli süreç kapanışında iki OpenGL dokusu için `Texture with GL ID ... leaked 349524 bytes` hatası oluşuyor. Koşucu bunu FAIL olarak tutuyor; başarıya çevrilmedi. Aynı script/oyun koduna temizlik öncesindeki bütün asset'ler geri konduğunda da aynı hata tekrarlandı. Asset silinmesinden kaynaklanmıyor; nedeninin ayrıca araştırılması gerekiyor. Headless sürümü geçiyor. Diğer bazı sahnelerde mevcut ObjectDB/RID kaynak kapanış uyarıları da günlüklerde bulunuyor.

## Sahne sonuçları

| Sahne | Pencereli tam paket |
|---|---|
| animal_motion | PASS |
| balance_bot | PASS |
| building_rotation | PASS |
| climate_report | PASS |
| contact_regressions | PASS |
| equipment_motion | PASS |
| farm_cycle | PASS |
| farm_visual | PASS |
| garage_sequence | PASS |
| harvest_request | PASS |
| hoe_clearance | PASS |
| hoe_closeups | PASS |
| hoe_motion | PASS |
| menu_content | PASS |
| pedestrians | PASS |
| perf | PASS |
| qa_late | PASS |
| resume_context | FAIL |
| river_quest | PASS |
| roads_rocks | PASS |
| rock_closeup | PASS |
| save_test | PASS |
| screenshots | PASS |
| shots3d | PASS |
| skin_anim | PASS |
| skin_compare | PASS |
| smoke_test | PASS |
| startup | PASS |
| traffic_yield | PASS |
| tt_models | PASS |
| work_closeups | PASS |

## Tekrar çalıştırma

```powershell
python tools/run_tests.py --godot "C:\path\Godot_console.exe" --clean-import --visual --timeout 300
python tools/run_tests.py --godot "C:\path\Godot_console.exe" --bot-policy chaos --seed 3 balance_bot
python -m unittest discover -s tools -p "test_*.py"
python tools/audit_assets.py
```

Yerel kanıt klasörleri `%TEMP%` altında: `mk_tests_4t4u0qj6` (önce), `mk_tests_w2qvux6x` (tam render paketi), `mk_tests_dm7qpoei` (son görsel tekrarlar), `mk_tests_tlj5745l` (chaos), `mk_tests_5biwybp6`, `mk_tests_batotstw`, `mk_tests_esha2ita` (seed/sera/izolasyon ve aynı kod + orijinal asset karşılaştırması).

Testler başlangıçlarında alınan çalışma kopyalarına aittir. Oturumda game_state/events/game ve paketleme araçlarında eşzamanlı başka çalışmalar vardı; bunlar temizliğin parçası olarak değiştirilmedi veya commit'e eklenmedi. Yeni yerel resume_context testi bu yüzden test raporunda yer alır ama temizlik commit'inin parçası değildir.
