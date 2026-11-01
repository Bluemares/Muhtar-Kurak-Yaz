# 03 — Karakterler, hayvanlar, araç

İskeletli (rigged) modellerde **animasyon adları birebir aşağıdaki gibi olmalı**; oyun animasyonu adıyla çağırır. Animasyonlar `.glb` içine gömülü (Blender: NLA'da her aksiyon ayrı, *Export → Animation → Actions* açık).

## Köylüler — `assets/models/chars/`

12 karakter; her köylü oyun boyunca birini taşır (köylü sayısı oyunda 4'ten 14'e çıkar). Oyun karakteri 0.62 ile küçültür (Kenney karakteri ≈ 0.78 boy → oyunda ≈ 0.48). Aynı oranı koru: **boy ≈ 0.78 birim**, ayaklar y = 0, yüz +Z. Sağ el kemiğinin adı `hand-right` (ya da `HandR`) olursa aletleri ele bağlarım.

### Karakter çeşitliliği (istek)

Köy kalabalık görünmeli, 12 karakter birbirinden kolay ayrılmalı:

| Dosya | Önerilen tip |
|---|---|
| `character-male-a` | Genç çiftçi, iş tulumu, hasır şapka |
| `character-male-b` | Yaşlı köylü (Hasan Dayı), kasket, bıyık, yelek |
| `character-male-c` | İtfaiyeci (Murat), kırmızı kask, reflektörlü üniforma |
| `character-male-d` | Orta yaşlı çiftçi, şalvar, kuşak |
| `character-male-e` | Seracı, eldiven, önlük |
| `character-male-f` | Gazeteci (Kerem), fotoğraf makinesi, gömlek |
| `character-female-a` | Genç kadın çiftçi, başörtüsü, çiçekli şalvar |
| `character-female-b` | COP31 iklim görevlisi (Elif), mavi yelek, yaprak rozeti |
| `character-female-c` | Yaşlı nine, yazma, hırka |
| `character-female-d` | Öğretmen (Zeynep), gözlük |
| `character-female-e` | Çoban kadın, yelek, değnek |
| `character-female-f` | Fatma Teyze (çiftçi), yazma, önlük |

Ten renkleri, yaşlar ve kıyafet renkleri çeşitli olsun. Çocuk köylüler istersen `character-child-a/b.glb` olarak ekleyebiliriz (kodda küçük değişiklik).

### Animasyonlar

| Ad | Şu an oyunda | Ne zaman | İstek |
|---|---|---|---|
| `idle` | var | Boşta beklerken | Hafif nefes, etrafa bakma |
| `walk` | var | Yürürken | |
| `sprint` | var | Yangında sığınağa koşarken | Panik koşusu, eller havada |
| `interact-right` | var | **Tarlada / serada çapa vurma, arazi temizlerken balta vurma** (oyun eline çapa ya da balta koyar) | Ayrı animasyonlar istiyoruz: `hoe` (çapalama, iki elle yukarıdan aşağı), `chop` (balta, yandan) |
| `pick-up` | var | Kuyudan kova doldururken eğilme | Ayrı: `draw-water` (kuyudan ip çekme) |
| `holding-right` | var | Kova taşırken dururken | Ayrı: `carry` (kovayı sağ elde taşıyarak yürüme) |

İstenen yeni animasyonlar — **bu adlarla koyarsan oyun kendiliğinden kullanır** (yoksa tablodaki Kenney yedeğini oynatır):

| Ad | Ne |
|---|---|
| `hoe` | Çapa vurma (tarla, sera) — **oyunda bağlı** (yedek: `interact-right`) |
| `chop` | Balta ile ağaç kesme / kaya kırma — **oyunda bağlı** (yedek: `interact-right`) |
| `draw-water` | Kuyudan ipi çekip kova doldurma — **oyunda bağlı** (yedek: `pick-up`) |
| `carry` | Kova taşıyarak yürüme — **oyunda bağlı** (yedek: `walk`) |
| `water` | Kovadan/hortumdan bitki sulama (ileride) |
| `harvest` | Eğilip ürün toplama, sepete koyma (ileride) |
| `cheer` | Hasat şenliği, görev tamamlandığında sevinme (ileride) |
| `sit` | Kahvede/bankta oturma (ileride, süs) |

### Aletler (ayrı modeller) — `assets/models/props/`

Şu an oyun bunları basit kutu ve silindirlerle çiziyor. **Bu klasöre bu adlarla koyduğun `.glb` dosyalarını oyun kendiliğinden kullanır** (`hoe`, `axe`, `bucket` bağlı; diğerleri ileride). Sap ucu (tutma noktası) orijinde, alet +Y yönünde uzansın; kova için orijin sapın ortası.

| Dosya | Ne | Boy ≈ |
|---|---|---|
| `hoe.glb` | Çapa | 0.45 |
| `axe.glb` | Balta | 0.35 |
| `bucket.glb` | Su kovası (dolu/boş) | 0.12 |
| `basket.glb` | Ürün sepeti | 0.15 |
| `hose.glb` | İtfaiye hortumu ucu | 0.2 |

## Rol portreleri (diyalog kartları)

Portreler aynı karakter modellerinden baş-omuz çekimiyle **otomatik** üretilir (`scripts/world3d/thumbs.gd`). Hangi rol hangi modeli kullanıyor:

| Rol | Ad | Şu anki model | İstek |
|---|---|---|---|
| hasan | Rehber Hasan Dayı | `character-male-b` | Yaşlı, kasketli, bıyıklı köylü |
| cop | Elif — COP31 iklim görevlisi | `character-female-b` | Mavi yelek, yaprak rozeti |
| fire | Murat — itfaiye şefi | `character-male-c` | Kırmızı kask, itfaiye üniforması |
| teacher | Zeynep Öğretmen | `character-female-d` | Gözlük |
| farmer | Fatma Teyze — çiftçi | `character-female-f` | Yazma, önlük |
| press | Kerem — gazeteci | `character-male-a` | Fotoğraf makinesi |

## Hayvanlar — `assets/models/pets/`

| Dosya adı | Ne | Oyundaki ölçek | Gereken animasyonlar |
|---|---|---|---|
| `animal-chick.glb` | Civciv / tavuk | 0.17 | `idle`, `walk`, `eat` |
| `animal-cow.glb` | İnek | 0.36 | `idle`, `walk`, `eat` |
| `animal-dog.glb` | Köpek | 0.24 | `idle`, `walk` |

Kenney hayvanları ≈ 1.25 birim küp; oyun yukarıdaki oranla küçültür. Kendi modelini **gerçek boyda** (tavuk ≈ 0.2, inek ≈ 0.45, köpek ≈ 0.3) yaparsan haber ver, ölçekleri 1'e çekerim. İstek: keçi ve koyun (Toros köyü), eşek (su taşıyan) eklenebilir.

## İtfaiye aracı — `assets/models/car/firetruck.glb`

- Uzunluk ≈ 3.2 birim (oyun 0.38 ile küçültür → ≈ 1.25 hücre). Burun +Z.
- Animasyon gerekmez; oyun yön çevirir, sirende tavana kırmızı/mavi ışık koyar (≈ 0.8 yükseklik). Araç yol ağını izler.
- İstek: Türk itfaiyesi kırmızısı, yan şerit, merdiven, "112" yazısı.
- Diğer araçlar (`tractor`, `truck`, `van`, `delivery-flat`) şu an kullanılmıyor; traktör tarlada süs olarak eklenebilir.
- `cone.glb` (trafik konisi) yalnız dükkandaki yol kartında.
