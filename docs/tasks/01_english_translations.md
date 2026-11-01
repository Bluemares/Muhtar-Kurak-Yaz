# Görev 1 — İngilizce çeviriler

## Bağlam
Godot 4 oyunu "MUHTAR: KURAK YAZ" (iklim temalı köy yönetimi, COP31 game jam). Tüm metinler
`i18n/strings.csv` dosyasında: `keys,tr,en`. `en` sütunu şu an boş.

## Yapılacak
1. `i18n/strings.csv` dosyasındaki HER satırın `en` sütununu doldur. Türkçe metnin doğal, kısa, oyun dili İngilizcesi.
2. Kurallar:
   - `keys` ve `tr` sütunlarına DOKUNMA. Satır ekleme/silme/sıralama yapma.
   - Biçim belirteçlerini aynen koru, aynı sırada: `%d`, `%s`, `%.1f`, `%%`. Örn. `"Yangın riski: %%%d / dk"` → `"Fire risk: %d%% / min"` (İngilizcede yüzde işareti sayıdan sonra: `%d%%`). Belirteç SAYISI ve SIRASI aynı kalmalı.
   - Her metni çift tırnak içine al. Metin içinde çift tırnak varsa `""` olarak yaz (CSV kuralı).
   - "Muhtar" kelimesini "Muhtar (village head)" diye ilk geçtiği INTRO_1'de açıkla, sonra sadece "Muhtar".
   - "COP31" aynen kalır. "Rehber Hasan Dayı" → "Uncle Hasan, your guide".
   - Buton metinleri kısa kalsın (buton genişliği ~150 px).
3. Kaydettikten sonra `B:\Godot\godot.exe --headless --path . --import` çalıştır. `i18n/strings.en.translation` oluşmalı.
4. `project.godot` dosyasında şu satırı:
   `locale/translations=PackedStringArray("res://i18n/strings.tr.translation")`
   şununla değiştir:
   `locale/translations=PackedStringArray("res://i18n/strings.tr.translation", "res://i18n/strings.en.translation")`
   (Dosyayı UTF-8 olarak kaydet; başka satıra dokunma.)

## Bitti sayılır
- CSV'de boş `en` hücresi kalmadı, import uyarısız.
- `i18n/strings.en.translation` var ve project.godot'ta kayıtlı.
