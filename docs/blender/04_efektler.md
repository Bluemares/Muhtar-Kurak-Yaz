# 04 — Efektler, ışık ve arayüz

Efektlerin hepsi **kodla** üretiliyor (parçacıklar, shader'lar, ışıklar). Modellemen gerekmez; daha güzel görünmeleri için **doku (PNG)** ya da küçük **model** verebilirsin. Dosyaları `assets/fx/` altına koy, adını bana bildir; bağlarım.

## Parçacık efektleri (`scripts/world3d/fx3d.gd`)

Hepsi kameraya dönük kareler; şu an yumuşak beyaz bir daire dokusu, renk zamanla değişiyor.

| Efekt | Ne zaman | Şu an | Senden istenebilecek |
|---|---|---|---|
| Alev | Bina yanarken, çatı hizasından yükselir | Sarı → turuncu → kırmızı daireler | Alev sprite sayfası (4×4 kare, 512 px, şeffaf PNG) |
| Kara duman | Yangında ve harap binada | Gri, büyüyerek yükselir | Duman sprite'ı (256 px, yumuşak) |
| Kıvılcım | Yangında | Küçük parlak noktalar | Gerek yok |
| Böcek sürüsü | Böcekli tarla | Koyu noktalar döner | Küçük böcek sprite'ı (64 px) |
| Toz patlaması | Bina düşünce / taşınınca | Bej daireler yayılır | Toz sprite'ı |
| Parıltı | Yükseltme (altın), onarım (turkuaz), su (mavi), ilaç (yeşil) | Renkli noktalar fışkırır | Yıldız/kıvılcım sprite'ı |
| Sıcak toz | Kuraklıkta havada | Uçuşan açık noktalar | Gerek yok |
| Hortum suyu | Yangın mini oyununda | 2D mavi damlalar | Su püskürtme sprite'ı |
| Yağmur | Yağmur olayında | 2D ekran çizgileri | Gerek yok |

## Shader'lar (`shaders/`)

| Dosya | Ne | Doku verirsen |
|---|---|---|
| `ground.gdshader` | Zemin: çimen, kuru ot lekeleri, toprak yol, arnavut kaldırımı, asfalt, kilitli alan, inşa ızgarası, risk haritası soluklaşması | Tekrarlanan çimen / toprak / parke dokusu (256–512 px, tileable) |
| `water.gdshader` | Nehir: akan dalgacık, kıyı köpüğü | Su normal haritası |
| `sea.gdshader` | Akdeniz: kıyıda turkuaz, açıkta lacivert, köpük | Su normal haritası |
| `select_pad.gdshader` | Bina altı seçim ve risk çerçevesi | Gerek yok |

Bina durum katmanları (yanma turuncusu, harap kararması, inşaat parlaması) `scripts/world3d/building_view.gd` içinde kısa shader'lar.

## Işıklar ve gökyüzü (`scripts/world3d/world_view.gd`)

| Ne | Ayrıntı |
|---|---|
| Güneş | Günün saatine göre döner, gece ay ışığına (mavi, zayıf) geçer; kuraklıkta sıcak ton |
| Gökyüzü | Prosedürel; gece laciverte, yağmurda griye döner |
| Sis | Uzakta sıcak pus, yağmurda yoğun |
| Pencere ışığı | Gece ev, COP31, itfaiye, serada sıcak nokta ışık |
| Yangın ışığı | Yanan binada titreyen turuncu |
| Sokak lambası | Gece 5.5 birim yarıçap; fenerin üstünde parlayan küre |
| Siren | İtfaiye aracında kırmızı/mavi yanıp sönen |

## Aletler

Köylünün elindeki çapa, balta ve kova şu an basit kutu/silindir (`scripts/world3d/actor_view.gd`). Gerçek modeller için bkz. [03_karakter_hayvan_arac.md](03_karakter_hayvan_arac.md) → "Aletler".

## Arayüz (2D, modelleme dışı)

- **Fontlar:** Cinzel (başlık), Alegreya Sans (metin), Google Fonts.
- **İkonlar:** Kodla çizilen vektör ikonlar (`scripts/ui/icon.gd`): para, su, erzak, köylü, kalp, güneş/ay, yükselt, ilaç, damla, onar, taşı, döndür, ürün, balta, çekiç, yol, alev, böcek. İstersen 128 px PNG ikon seti yapabilirsin (`assets/ui/icons/<ad>.png`).
- **Ürün ikonları:** havuç (sebze), kavun, mısır, buğday (`scripts/ui/crop_icon.gd`).
- **Dükkan kartları ve portreler:** 3D modellerden otomatik çekiliyor; modellerin değişince kendiliğinden güncellenir.
