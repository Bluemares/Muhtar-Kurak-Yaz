# Görev 05 — Sunum metinlerine Sürüm 3 yeniliklerini ekle

**Amaç:** Oyuna Sürüm 3'te yeni sistemler geldi. Jüri ve itch.io metinleri bunları anlatmıyor. Kod yok.

## Güncellenecek dosyalar
- `docs/SUNUM.md`
- `docs/PRESENTATION_EN.md`
- `docs/ITCH_PAGE.md`

## Kaynak
- `docs/ROADMAP.md` → "Sürüm 3" tablosu (W1–W11) ve günlükteki W maddeleri.
- `scripts/autoload/balance.gd` → `ROAD_TILE_COST`, `ROAD_YIELD_MULT`, `AUTO_HARVEST_DELAY`, `TAP_HARVEST_BONUS`.
- `i18n/strings.csv` → `NAME_*` (karakter adları), `TAB_*`, `SHOP_*`.
- Yeni ekran görüntüleri: `tests/shots/19_roads.png`, `20_shop.png`, `21_shop_water.png`, `22_actions.png`, `23_harvest.png`, `15_decision.png`, `03_mission_card.png`.

## Eklenmesi gerekenler (her üç dosyada uygun bölümlere)
1. **İnşa dükkanı:** sağ altta İnşa butonu (B tuşu), Tarım / Su / Yerleşim / Altyapı sekmeleri, fiyat etiketli kartlar.
2. **Bina üstü butonlar:** binaya tıklayınca altında Yükselt / İlaçla / Damla sulama / Onar / Taşı.
3. **Yol döşeme:** hücre başı 10, sağ tık siler; yola bitişik tarla/sera +%15 verim; köylüler yolda hızlı yürür, binaların etrafından dolaşır.
4. **Dokunarak hasat:** olgun üründe balon, tıklayınca +%15; 4 sn sonra kendiliğinden toplanır. Altın ve ürün ikonları üst çubuğa uçar.
5. **Rol karakterleri:** Hasan Dayı (rehber), Elif (COP31 iklim görevlisi), Murat (itfaiye şefi), Zeynep Öğretmen, Fatma Teyze (çiftçi), Kerem (gazeteci) — hangi kartta kim konuşuyor.
6. **Bina görünümleri:** taş COP31 belediyesi (tabela, bayraklar), kemerli itfaiye garajı (park etmiş araç), pixel art kuyu.
7. **Okunaklılık:** başlıklar pixel, metinler net font.
8. **Jüri kriterleri tablosu:** "Oynanabilirlik" ve "Sunum" satırlarına yukarıdakileri işle.
9. **60 sn video senaryosu (SUNUM):** dükkandan inşa + düşen bina + dokunarak hasat + karar kartı planı ekle.
10. **Ekran görüntüsü alt yazıları (ITCH_PAGE):** yeni görüntüler için birer cümle.

## Kurallar
- Sayıları uydurma; sadece kaynak dosyalardaki değerleri kullan. Gerçek dünya istatistiği yazma.
- Başka dosyaya dokunma. Bitince `docs/tasks/README.md` tablosuna 05 satırını "tamam" olarak ekle.
