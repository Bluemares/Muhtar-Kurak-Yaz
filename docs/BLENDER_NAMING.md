# Blender modelleri: adlandırma ve teslim kuralları

> Tüm modellerin ve efektlerin ayrıntılı listesi: **[blender/README.md](blender/README.md)** (binalar, doğa, karakterler, efektler).

Oyun şu an Kenney (CC0) modelleriyle çalışıyor. Blender'da yapılan model **doğru klasöre, doğru adla** `.glb` olarak konunca oyun kod değişmeden onu yükler. Bu belge o kuralları anlatır.

## 1. Genel kurallar

| Konu | Kural |
|---|---|
| Biçim | glTF 2.0 Binary (`.glb`). Blender: *File → Export → glTF 2.0*, Format: **glTF Binary**. |
| Ölçek | **1 Blender birimi = 1 oyun hücresi** (yaklaşık 1 m). Export'ta *+Y Up* açık kalsın (varsayılan). |
| Orijin | Modelin **taban merkezi** (zemine oturan yüzün ortası). Model y = 0'dan yukarı uzanır. |
| Ön yüz | Binanın kapısı / aracın burnu / karakterin yüzü **+Z** yönüne (Blender'da **−Y**) bakar. |
| Malzeme | Principled BSDF: *Base Color* (düz renk ya da doku), *Roughness*. Metallic = 0. Emission yalnız ışık/ateş için. |
| Doku | Tek doku tercih: 256–1024 px PNG, `.glb` içine gömülü (*Export → Images: Automatic*). |
| Poligon | Web için hafif: bina ≤ 3.000 üçgen, ağaç/kaya ≤ 600, karakter ≤ 2.500, araç ≤ 2.000. |
| Ad | Küçük harf, Türkçe karakter yok, boşluk yok: `house.glb`, `fire_station_l1.glb`. |

## 2. Binalar → `assets/models/buildings/`

Oyun önce seviyeye özel dosyayı, yoksa genel dosyayı arar: `<tür>_l<seviye>.glb` → `<tür>.glb` → Kenney kiti.

| Tür (dosya adı) | Taban (hücre) | Seviyeler | Not |
|---|---|---|---|
| `house` | 1×1 | 1 | Beyaz badana, kiremit çatı. Kapı +Z. |
| `cop31` | 2×2 | 1–3 | `cop31_l1/l2/l3.glb`. Lv2 ikinci kat, Lv3 bayraklar. "COP31" tabelası oyunda ayrıca yazılmaz; modelde olmalı. |
| `fire_station` | 2×1 | 1 | Garaj kapısı +Z. Kırmızı-beyaz. |
| `well` | 1×1 | 1–3 | `well_l1/l2/l3.glb` ya da tek `well.glb`. |
| `field` | 2×2 | 1–3 | Yalnız toprak sıraları. Bitkiler ayrı (aşağıda). |
| `greenhouse` | 2×1 | 1 | Naylon tünel; örtü malzemesi yarı saydam (Alpha Blend). |
| `water_tower` | 1×1 | 1 | ~2.2 birim yükseklik. |
| `grove` | 1×1 | 1 | Portakal/zeytin ağaçları + sulanmış toprak. |

Taban ölçüsünü aşmayın: 1×1 bina 0.9×0.9 içinde kalsın ki komşu binalarla iç içe görünmesin.

## 3. Doğa, ekin, araç, karakter

Bunlar Kenney'deki adlarla değiştirilir (aynı klasöre aynı adla yazın):

- `assets/models/nature/` — `tree_pineTallA…D`, `tree_pineRoundA…C` (kızılçam), `tree_fat`, `tree_plateau` (zeytin), `tree_palm*`, `tree_default` (portakal), `stone_*` (kireçtaşı), `crops_leafsStageA/B` (sebze), `crops_cornStageA…D`, `crops_wheatStageA/B`, `crops_dirtRow`, `bridge_wood`, `pot_large`.
- `assets/models/car/firetruck.glb` — burnu +Z, ~3.2 birim uzunlukta (oyun 0.38 ile küçültür; aynı oranı koruyun).
- `assets/models/chars/character-male-a…f.glb`, `character-female-a…f.glb` — iskeletli. **Animasyon adları birebir şu olmalı:** `idle`, `walk`, `sprint`, `pick-up`, `interact-right`. Boy ~0.78 birim (oyun 0.62 ile küçültür).
- `assets/models/pets/animal-chick|cow|dog.glb` — animasyonlar: `idle`, `walk`, `eat`.

Ağaçlarda yaprak malzemesinin adı `leafs…` ile başlarsa oyun kurakta sararmayı otomatik uygular.

## 4. Deneme

1. `.glb` dosyasını ilgili klasöre koyun.
2. Godot'yu açın (içe aktarma kendiliğinden olur) ya da `godot --headless --path . --import`.
3. `godot --path . res://tests/shots3d.tscn` → `tests/shots/3d_*.png` görüntülerine bakın.
4. Model yanlış yöne bakıyorsa Blender'da Z ekseninde 180° döndürüp *Apply → Rotation* yapın.

Kaynak: `scripts/world3d/models.gd` (yükleme), `scripts/world3d/building_kit.gd` (`_custom()`), eşleme `docs/MODELS_3D.md`.
