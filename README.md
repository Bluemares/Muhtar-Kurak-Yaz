# MUHTAR: KURAK YAZ

COP31 temalı, üç boyutlu köy yönetimi ve kaynak yönetimi odaklı strateji oyunu.
Oyuncu, desteğe ihtiyacı olan bir köye COP31 tarafından üç aylık deneme
süresiyle atanan bir muhtar adayını yönetir. Haziran, temmuz ve ağustos boyunca
köyün su, gıda ve bütçe ihtiyaçlarını karşılayarak halkın refahını korumaya çalışır.

## Oynanış

- Tarım alanları kurma, ürün seçimi ve işçi görevlendirme
- Kuyu, su deposu, damla sulama ve toprak nemi yönetimi
- Ambar ve pazarda gıda kaynaklarını yönetme
- Köyü geliştirme, yol düzenleme ve yangınlara müdahale
- Türkçe ve İngilizce arayüz

## Geliştirme ortamı

1. Godot **4.7.1 Standard** sürümünü kurun. Proje GDScript kullanır, .NET gerekmez.
2. Bu depoyu klonlayın ve Godot proje yöneticisinden `project.godot` dosyasını içe aktarın.
3. İlk varlık içe aktarımı tamamlandıktan sonra **F5** ile ana projeyi çalıştırın.

```sh
git clone https://github.com/Bluemares/Muhtar-Kurak-Yaz.git
cd Muhtar-Kurak-Yaz
godot --editor --path .
```

## Testler

Python 3 ile izole test koşucusu:

```sh
python tools/run_tests.py --godot /path/to/godot contact_regressions farm_cycle pedestrians
python tools/run_tests.py --godot /path/to/godot --visual animal_motion river_quest
python tools/test_run_tests.py
```

Koşucu geçici proje kopyası kullanır ve kişisel oyun kaydını korur.
Görsel testler render destekli ortam gerektirir. Ayrıntılar: [tests/README.md](tests/README.md).

## Dışa aktarma

Windows ve Web ön ayarları `export_presets.cfg` içindedir. Mevcut ayarlar yerel
`_templates/` klasöründeki özel export şablonlarına referans verir. Bu şablonlar
depoya dahil değildir. Başka bir bilgisayarda dışa aktarmadan önce kullanılan
Godot sürümünün export şablonlarını kurun ve ön ayarlardaki **Custom Template**
alanlarını uygun şablonlara yönlendirin veya standart şablon için boş bırakın.
Çıktılar `build/` altına yazılır ve Git'e eklenmez.

## Dosya yapısı

- `scripts/`, `scenes/`, `shaders/`: oyun kodu ve sahneler
- `assets/`, `tt_models/`: görsel, ses ve model kaynakları
- `i18n/`: çeviri kaynakları
- `tests/`, `tools/`: testler ve geliştirme araçları
- `docs/`: tasarım ve geliştirme notları
- `dev_gallery/`: geliştirici görsel galerisi

## Ekip ve varlıklar

BBES ekibi: Berke Buyruk ve Erdem Sosar.
Üçüncü taraf varlıkların lisansları ilgili `assets/` alt klasörlerinde
`LICENSE_*` dosyaları olarak bulunur. Bu depo oyun kodu için ayrıca bir açık
kaynak lisansı tanımlamaz.
