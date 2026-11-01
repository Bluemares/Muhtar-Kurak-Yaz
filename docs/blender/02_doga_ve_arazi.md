# 02 — Doğa ve arazi

Klasör: **`assets/models/nature/`**. Bu modeller binlerce kez çoğaltılarak (MultiMesh) çizilir; **poligonu düşük tut** (ağaç ≤ 600, ekin ≤ 200 üçgen). Ağaçlarda yaprak malzemesinin adı `leafs…` ile başlarsa oyun kuraklıkta onları otomatik sarartır.

## Ağaçlar

| Dosya adı | Ne | Yükseklik ≈ | Nerede | Not |
|---|---|---|---|---|
| `tree_pineTallA.glb` … `tree_pineTallD.glb` | Kızılçam (uzun) | 1.5 (oyun 1.15–1.9 kat büyütür) | Orman hücreleri, kuzey yamaçlar | Kızıl-kahve gövde, koyu yeşil iğne yaprak |
| `tree_pineRoundA.glb` … `tree_pineRoundC.glb` | Kızılçam (yuvarlak taç) | 1.4 | Aynı | |
| `tree_fat.glb`, `tree_plateau.glb` | Zeytin ağacı | 1.15 | Güney ova (zeytinlik) | Gri-yeşil yaprak, eğri kalın gövde |
| `tree_default.glb` | Portakal ağacı | 1.2 (koruda 0.5) | Koruluk binası | Meyveleri oyun ayrı küre olarak ekliyor; modele meyve koyarsan haber ver |
| `tree_palm.glb`, `tree_palmTall.glb`, `tree_palmShort.glb`, `tree_palmBend.glb` | Palmiye | 1.35 | Akdeniz kumsalı | |

## Kaya ve süs

| Dosya adı | Ne | Boyut ≈ | Nerede |
|---|---|---|---|
| `stone_largeA.glb`, `stone_largeB.glb`, `stone_largeC.glb` | Kireçtaşı kaya (büyük) | 0.8 × 0.3 × 1.0 | Kayalık hücreler, ormanda |
| `stone_tallA.glb`, `stone_tallB.glb` | Kireçtaşı (dikine) | 0.5 × 1.0 | Kayalık |
| `grass.glb`, `grass_large.glb` | Ot öbeği | 0.4 × 0.25 | Çayırda seyrek |
| `flower_redA.glb`, `flower_yellowA.glb` | Kırmızı / sarı çiçek | 0.3 | Çayırda seyrek |
| `plant_bushSmall.glb` | Küçük çalı | 0.4 | Çayırda seyrek |
| `pot_large.glb` | Toprak küp / saksı | 0.4 (ev önünde) | Ev kapısı |
| `bridge_wood.glb` | Ahşap köprü parçası | 1 × 0.4 × 1 | Nehir üstünde 3 parça yan yana | Tek parça 3 hücrelik köprü de olabilir |
| `stump_round.glb`, `log.glb` | Kütük, odun | 0.5 | Dükkandaki "Arazi temizle" kartı |

## Ekinler (tarlanın üstüne dizilir)

Tarlada 4×4 = 16 bitki; oyuncunun seçtiği ürüne ve büyümeye göre evre değişir. Her bitki ≈ 0.4 × 0.4 tabanda, kökü y = 0'da.

| Ürün | Evreler (dosya adları, büyüme sırasıyla) | Olgun yükseklik ≈ |
|---|---|---|
| Sebze | `crops_leafsStageA` → `crops_leafsStageB` → `crop_carrot` / `crop_turnip` (karışık) | 0.3 |
| Kavun | `crops_leafsStageA` → `crops_leafsStageB` → `crop_melon` | 0.3 |
| Mısır | `crops_cornStageA` → `B` → `C` → `crops_cornStageD` | 1.0 |
| Buğday | `crops_wheatStageA` → `crops_wheatStageB` | 0.6 |
| Tarla toprağı | `crops_dirtRow` (1 × 0.62 sıra) | 0.05 |

İstek: domates, biber, karpuz gibi Antalya ürünleri için yeni evreler istersen dosya adını bildir, ürün listesine eklerim.

## Kodla üretilenler (model değil, istersen model yapılabilir)

| Ne | Şu an | Model yaparsan |
|---|---|---|
| Toros dağları | Kodla üretilmiş low-poly yükseklik haritası (etekte yeşil, ortada toprak, tepede kireçtaşı) | Büyük bir dağ silsilesi `.glb` (vadiyi kuzey/doğu/batıdan saran, ≈ 200 × 110 birim) |
| Akdeniz | Düz düzlem + dalga shader'ı | Gerek yok; kumsal kayaları/iskele eklenebilir |
| Nehir | Kıvrımlı şerit + su shader'ı | Gerek yok; kıyı taşları eklenebilir |
| Zemin, yollar | Hücre renk dokusu + shader (toprak / arnavut kaldırımı / asfalt) | Yol için tekrarlanan doku (256 px) verebilirsin |
