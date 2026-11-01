# Görev 03 — itch.io sayfa metni ve ekran görüntüsü açıklamaları

**Amaç:** Jüri ve oyuncuların göreceği itch.io sayfası için hazır metin. Kod yok, sadece yeni bir dosya.

## Okunacak kaynaklar
- `docs/SUNUM.md`, `docs/PRESENTATION_EN.md` (oyun açıklaması, kurallar)
- `docs/ROADMAP.md` (son eklenen mekanikler)
- `tests/shots/*.png` (ekran görüntüleri: 01_menu, 04_playing_selected, 06_cinematic, 07b_minigame_late, 08_final_good)

## Yazılacak dosya
`docs/ITCH_PAGE.md` — iki bölüm: **Türkçe** ve **English**. Her bölümde:

1. **Kısa slogan** (tek cümle, en fazla 90 karakter).
2. **Açıklama** (120–160 kelime): oyuncu kimdir, 3 ay kuraklık, yangın/su/böcek, "önlem müdahaleden ucuzdur" mesajı.
3. **Öne çıkanlar** (5 madde):
   - kuru toprak daha kolay yanar (su deposu doluysa risk düşer),
   - COP31 Kayıp ve Zarar Fonu acil yardımı,
   - itfaiye aracı sinematiği + hortum mini oyunu,
   - taşınabilir binalar ve yol altyapısı,
   - iki dil (TR/EN).
4. **Kontroller** tablosu (SUNUM.md'deki ile aynı).
5. **Ekran görüntüsü alt yazıları**: yukarıdaki 5 görüntü için birer cümle.
6. **Emeği geçenler:** "Grafik ve efekt sesleri: Kenney (kenney.nl), CC0. Müzik ve döngü sesleri: proje içinde üretildi (tools/synth_audio.py). Motor: Godot 4." Ekip: Erdem Sosar, Berke Buyruk.
7. **Etiketler:** 8 etiket (ör. climate, strategy, management, simulation, pixel-art, godot, turkish, game-jam).

## Kurallar
- Sayıları uydurma; sadece kaynak dosyalardaki değerleri kullan.
- Gerçek dünya iklim istatistiği yazma (kaynak gösteremeyeceğimiz sayı yok).
- Başka dosyaya dokunma. İş bitince `docs/tasks/README.md` tablosunda 03'ü "tamam" yap.
