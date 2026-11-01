# Görev 07 — Sunum metinlerini Sürüm 4.6'ya güncelle

**Amaç:** Görev 06'dan sonra oyunda birkaç kural ve kontrol değişti. Belgelerde eskimiş yerler var. Kod yok.

## Güncellenecek dosyalar
- `docs/SUNUM.md`
- `docs/PRESENTATION_EN.md`
- `docs/ITCH_PAGE.md`
- `docs/VIDEO_SHOTLIST.md`
- `docs/RELEASE_CHECKLIST.md`

## Kaynak
- `docs/ROADMAP.md` → günlükteki "Sürüm 4.6" maddesi.
- `scripts/autoload/balance.gd` → `NO_ROAD_NEEDED`, `SELL_REFUND`, `HEAT_STRESS`, `MOIST_GROWTH_MIN`, `FOOD_PER_WORKER`.
- `scripts/game/progress.gd` → `stars()` (yıldız şartları).
- `i18n/strings.csv` → `HOW_*`, `BTN_SELL`, `BTN_ROAD_ERASE`, `HEAT_STRESS`, `MOIST_BTN`, `RISK_BTN`.

## Düzeltilecekler (bulduğum eski yerler)
1. **Haritalar artık iki ayrı butonda ve iki ayrı tuşta:** **F = Yangın riski** (alev ikonlu buton), **N = Toprak nemi** (damla ikonlu buton). "F ile risk → nem arasında geçiş" yazan her yeri düzelt:
   - `SUNUM.md` satır ~37 ve ~47, video tablosu satır ~74
   - `PRESENTATION_EN.md` satır ~36 ve ~46
   - `ITCH_PAGE.md` satır ~20, ~32, ~73, ~85
   - `VIDEO_SHOTLIST.md` satır ~26 ve ~41
   - `RELEASE_CHECKLIST.md` satır ~44
2. **Yol şartı:** "COP31 dışında her bina" → **"COP31 ve koruluk dışında her bina"** (koruluk yolsuz da çalışır). `PRESENTATION_EN.md` ~27, `ITCH_PAGE.md` ~19 ve ~72, `RELEASE_CHECKLIST.md` ~42.

## Eklenecekler (her belgede uygun bölüme)
3. **Bina satma:** COP31 ve itfaiye dışındaki binalar "Sat" butonuyla, onay sorularak yarı fiyatına kaldırılır.
4. **Yol silme:** yol modunda "Yol sil" butonu sol tıkı silgiye çevirir (sağ tık da siler).
5. **Döndürme:** seçili binayı **R** tuşu ya da "Döndür" butonu döndürür; yerleştirirken de R.
6. **Sera:** serada da ürün seçilir, bitkiler seçilen ürüne göre büyür.
7. **Zorluk / denge:**
   - köylüler daha çok yer (`FOOD_PER_WORKER`);
   - **sıcak stresi** kuraklıkla refahı düşürür, dolu su deposu ve koruluklar hafifletir (görev panelinde "Sıcak stresi −X");
   - kuru tarla yavaş büyür (nem haritası artık oynanışı etkiler).
8. **Yıldızlar:** 3 yıldız = 3 görev + köylüler zamanın en az %90'ında tok + en fazla 2 yanan bina. 2 yıldız = en az 2 görev.
9. **Köy hayatı:**
   - boştaki köylüler kuyunun dibinden kova doldurup su kulesine taşır (+su);
   - tarlada/serada çapa, arazi temizlerken balta ile çalışır.
10. **Nasıl Oynanır** ekranı: 9 kart (Ambar ve pazar kartı eklendi).
11. **Jüri tablosu (SUNUM, PRESENTATION_EN):** "Oynanabilirlik" satırına zorluk dengesini ekle: pasif / önlemsiz oyun kaybeder ya da başarısız olur, akıllı oyun kazanır. ROADMAP'teki bot sonuçlarını kullan.

## Kurallar
- Sayıları uydurma; yalnız kaynak dosyalardaki değerleri kullan. Video planındaki örnek sayılar (ör. "%96 tok") yerine "zamanın %X'inde tok" yaz.
- Ekip: Erdem Sosar, Berke Buyruk.
- Başka dosyaya dokunma. Bitince `docs/tasks/README.md` tablosuna 07 satırını "tamam" olarak ekle.
