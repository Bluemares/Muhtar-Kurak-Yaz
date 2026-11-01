# Blender modelleme paketi — MUHTAR: KURAK YAZ

Oyunun şu anki görselleri Kenney'nin ücretsiz (CC0) 3D paketlerinden ve kodla üretilmiş efektlerden oluşuyor. Bu klasör, hepsini kendi modellerinle değiştirebilmen için **neyin, nerede, hangi boyutta** kullanıldığını listeler.

## Dosyalar

| Dosya | İçerik |
|---|---|
| [01_binalar.md](01_binalar.md) | Oyuncunun kurduğu 10 bina (ev, COP31, itfaiye, kuyu, tarla, sera, su deposu, koruluk, ambar, sokak lambası) |
| [02_doga_ve_arazi.md](02_doga_ve_arazi.md) | Ağaçlar, kayalar, ekinler, köprü, çiçek/çalı, dağlar, deniz, zemin |
| [03_karakter_hayvan_arac.md](03_karakter_hayvan_arac.md) | 12 köylü, 6 rol portresi, hayvanlar, itfaiye aracı |
| [04_efektler.md](04_efektler.md) | Alev, duman, su, ışıklar, gökyüzü, arayüz efektleri (modelleme değil, doku/öneri) |

## Altın kurallar (ayrıntı: [../BLENDER_NAMING.md](../BLENDER_NAMING.md))

- **Biçim:** glTF Binary `.glb` (Blender → File → Export → glTF 2.0 → Format: glTF Binary).
- **Ölçek:** 1 Blender birimi = 1 oyun hücresi (≈ 1 m). Duvar yüksekliği ≈ 1, kapı ≈ 0.7.
- **Orijin:** Modelin taban ortası; model y = 0'dan yukarı.
- **Ön yüz:** Kapı / aracın burnu / karakterin yüzü oyunda **+Z** yönüne bakar (Blender'da **−Y**).
- **Malzeme:** Principled BSDF, Metallic = 0. Düz renk ya da tek bir küçük doku (256–1024 px), dosyaya gömülü.
- **Poligon (web için):** bina ≤ 3.000 üçgen, ağaç/kaya ≤ 600, karakter ≤ 2.500, araç ≤ 2.000.
- **Ad:** Aşağıdaki tablolardaki **dosya adını aynen** kullan (küçük harf, boşluksuz). Doğru klasöre aynı adla koyunca oyun **kod değişmeden** onu yükler.
- **Stil:** Antalya köyü: kireç badana beyaz duvarlar, kiremit (turuncu-kırmızı) çatılar, kızılçam, zeytin, portakal, naylon sera, Toroslar, Akdeniz. Low-poly, düz renkli, sıcak yaz ışığı.

## Renk paleti (oyunun şu anki tonları)

Kendi modellerin köyle uyumlu dursun diye şu tonlara yakın kal (hex):

| Ne | Renk |
|---|---|
| Kireç badana duvar | `#F7F2E6` |
| Kiremit çatı | `#D2643A` – `#B9532F` |
| Ahşap (açık / koyu) | `#B07D4F` / `#6B4429` |
| Kızılçam gövde (kızıl kahve) | `#7A3F2A` |
| Kızılçam iğne yaprak | `#3E5F2A` |
| Yaprak (açık yeşil) / zeytin | `#5F8A34` / gri-yeşil `#7D8F5A` |
| Kireçtaşı kaya | `#B3AB9C` / koyu `#8F887C` |
| Çimen (yaz) / kurak | `#80893F` / `#A8945A` |
| Toprak, tarla sırası | `#A07A52` / `#7A5A3C` |
| İtfaiye kırmızısı | `#C0392B` |
| COP31 mavisi (tabela) | `#3373D9` |
| Portakal | `#FF8C14` |

## Ölçü ve yön referansı

Paketteki `referans_modeller/` klasöründe oyunun şu an kullandığı bütün `.glb` modeller var (Kenney, CC0). Blender'da *File → Import → glTF 2.0* ile aç:
- Ölçü ve yön için şablon olarak kullan: kendi modelini onların yanına koy, aynı boyda ve aynı yöne baksın.
- Bina parçaları (`town/`) tek tek parçalar; bir evin nasıl dizildiğini görmek için `ekran_goruntuleri/` klasörüne bak.
- Karakterlerin (`chars/`) iskeleti ve animasyon adları da bu dosyalarda; kendi karakterini aynı iskelet yapısıyla kurarsan animasyonlar daha kolay aktarılır.

## Teslim ve deneme

Godot kurulu değilse dosyaları Berke'ye gönder, o koyar. Godot varsa:

1. `.glb` dosyasını tablodaki klasöre koy (ör. `assets/models/buildings/house.glb`).
2. Godot'yu aç (otomatik içe aktarır) ya da `B:\Godot\godot.exe --headless --path . --import`.
3. `B:\Godot\godot.exe --path . res://tests/shots3d.tscn` → `tests/shots/3d_*.png` görüntülerine bak.
4. Yanlış yöne bakıyorsa Blender'da Z ekseninde 180° döndür, *Object → Apply → Rotation*.

## Paketin içeriği

| Klasör | İçerik |
|---|---|
| `belgeler/` | Bu dosya + 01–04 + adlandırma kuralları + model eşleme |
| `referans_modeller/` | Oyunun kullandığı tüm `.glb` modeller ve dokuları (`town`, `nature`, `car`, `chars`, `pets`) |
| `ekran_goruntuleri/` | Oyunun şu anki görünümü (binalar, köylüler, gece, yangın, menü) |

## Öncelik önerisi (oyunun en çok göründüğü yerler)

1. Ev (`house`), COP31 (`cop31_l1/l2/l3`), tarla bitkileri (`crop_*`, `crops_*`)
2. Köylü karakterleri (`character-*`), itfaiye aracı (`firetruck`)
3. Kızılçam ve zeytin ağaçları, kayalar
4. Kuyu, sera, su deposu, itfaiye, sokak lambası, koruluk
