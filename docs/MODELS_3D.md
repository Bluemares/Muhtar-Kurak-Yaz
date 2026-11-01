# Temas, yol bulma ve sinematik düzeltmeleri — 1 Kasım 2026

- Tarla 6 cm kalınlığında toprak tabanı kullanır; sıralar ve bitki kökleri ortak 9 cm yüzeye hizalıdır. Sulama boruları da bu yüzeyin üzerindedir.
- İşçi erişilebilir tarla kenarından gerçek bitki konumunu seçer. Çapa ucu bu dünya konumuna iner; tarla döndürüldüğünde çalışma noktası yeniden hesaplanır.
- Yollar artık engelli son hedefi zorla eklemez. Bina çevresinde güvenlik payı, yatay/dikey yol adımları, segment denetimi ve bina taşındığında yeniden yol bulma uygulanır. Erişilemeyen hedefe doğrudan yürünmez.
- Hayvanların gövdeleri sabit yükseklikte kalır. Dört vuruşlu yürüyüşte yalnız geri alınan ayak kalkar.
- COP31, ambar ve itfaiye tabelaları çerçeveli levha ve yüksek çözünürlüklü, kontursuz Alegreya Sans yazı kullanır. İtfaiye levhası çatının önündedir.
- Yangında kamera oyuncunun önceki açısını kullanmaz: garajı tam karşıdan gösterir, ardından aracı önden takip eder. Bu sırada normal HUD ve bina göstergeleri gizlenir; Geç düğmesi kalır. Yangın bitince önceki kamera görünümü geri yüklenir.
- Görünen ürün adı Karpuz/Watermelon oldu; kayıt uyumluluğu için iç kimlik `melon` korundu.
- Doğrulamalar: `contact_regressions.tscn` bina dışı yolları, işçinin tarlaya ulaşmasını, dört yönde çapa temasını, toprağı, gövde zıplamasını ve kameranın bağımsızlığını kontrol eder. `farm_visual.tscn` gerçek temas anını görüntüler.

# Görsel düzenleme — 1 Kasım 2026

- İşçi ölçeği 0.65 → 0.46; evler %22, itfaiye aracı 0.38 → 0.52 büyütüldü.
- Hayvanların iskelet pozları dosyadaki başlangıç pozundan alınır; bacaklar kat edilen mesafeyle hareket eder, durunca sabitlenir.
- Konuşmacı portreleri `assets/portraits/` içindeki altı ayrı 2D SVG çizimidir (Hasan, Fatma, öğretmen, COP temsilcisi, itfaiyeci, gazeteci).
- Tarla ürününün görünen adı Havuç/Carrot olarak güncellendi.
- Kare binalar 90°, dikdörtgenler 180° döner. Yerleştirme önizlemesi artık 180° seçimini sıfırlamaz.
- Ahşap köprü kullanıcının yeni `bridge_wood.glb` dosyasıdır.
- İtfaiye binası `village_art.gd` ile üretilen 2×2 hücreli, tek kepenkli garajdır. Kapı araç hareket etmeden açılır; araç kapı yönünden çıkar, çıkınca kapanır. Park hâlindeki araç da aynı GLB dosyasını kullanır.
- Ambar aynı dosyada sıvalı duvar, kiremit, ahşap kapı ve tahıl çuvallarıyla köyün temasına uyarlandı.
- Ek kontroller: `tests/garage_sequence.tscn`, `tests/animal_motion.tscn`, genişletilmiş `tests/tt_models.tscn`.

Aşağıdaki kayıt önceki değişimin tarihçesidir; bu bölüm önceliklidir.

# Etkin model seçimi — 1 Kasım 2026

- Ev, COP31/muhtarlık, itfaiye istasyonu ve kuyu: `tt_models/scripts/` içindeki TT paketi. `BuildingKit` mevcut hücre boyutlarına göre ölçekler. COP31 adı ve oyun kuralları korunur.
- İşçiler: TT karakteri; mevcut işçi durumları yürüyüş, çapa, su çekme, taşıma ve arazi temizliği hareketlerini sürer. Rol portreleri de TT karakterini kullanır.
- İtfaiye aracı: kullanıcının seçtiği `assets/models/car/firetruck.glb` (TT araç betiği kullanılmaz).
- Su kulesi, ambar, lamba: seçilen `assets/models/buildings/water_tower.glb`, `granary.glb`, `lamp.glb`.
- Civciv, inek, köpek: seçilen `assets/models/pets/animal-*.glb`; kendi idle/walk/eat animasyonları korunur.
- Çevre, tarla, sera, ekin, koru ve tarımsal aksesuarlar mevcut modellerini kullanır. `farm_rig.gd` yalnızca karakterin çapa hareketini sağlar.
- TT kuyu hareketi simülasyonun gerçek dolum süresini izler. Tarımsal yapılar dışındaki yangın ve enkaz görselleri TT paketindendir; hasar, su tüketimi ve onarım kuralları değişmez.

Doğrulama: `tests/tt_models.tscn` model oluşturma, işçi hareketleri, kuyu, yangın, enkaz ve onarım geçişlerini denetler; görüntülü çalıştırmada `tests/shots/tt_models.png` üretir. `tests/smoke_test.tscn` oyun akışını, `tests/shots3d.tscn` oyun içi görünümü denetler.

Aşağıdaki eski envanter, korunan temel varlıkların kaynak bilgisidir; yukarıdaki seçim önceliklidir.

# 3D model envanteri ve eşleme (Sürüm 4)

Tüm modeller Kenney (CC0). Ham paketler `_downloads/` altında (oyuna girmez). Oyunda kullanılanlar `assets/models/` altında:

| Klasör | Kaynak | Not |
|---|---|---|
| `assets/models/town/` | Fantasy Town Kit (GLB, tamamı) | Duvar/çatı/kapı/pencere parçaları, çeşme, tezgah, değirmen. Doku: `town/Textures/colormap.png` |
| `assets/models/nature/` | Nature Kit (seçilmiş 87 model) | Ağaç, kaya, uçurum, ekin, çit, köprü, çömlek, antik sütun. Malzeme renkleri GLB içinde, doku yok |
| `assets/models/car/` | Car Kit (7 model) | `firetruck`, `tractor`, `truck`, `van`, `delivery-flat`, `cone`, `box`. Doku: `car/Textures/colormap.png` |
| `assets/models/chars/` | Mini Characters (12 karakter) | `character-male-a..f`, `character-female-a..f`. İskeletli; animasyonlar: `idle`, `walk`, `sprint`, `pick-up`, `interact-right`, `holding-both`, `drive`, `sit`, `emote-yes`, `emote-no` … |

Fontlar (`assets/fonts/`, Google Fonts, OFL): `cinzel_700/900.ttf` (Witcher tarzı başlık), `alegreya_sans_400/700.ttf` (gövde metni). Türkçe ğĞşŞıİçÇöÖüÜ kapsamı doğrulandı.

## Oyun nesnesi → model eşlemesi

| Oyun nesnesi | Kenney parçaları | Antalya uyarlaması |
|---|---|---|
| Ev (`house`) | `town/wall`, `wall-window-shutters`, `wall-door`, `roof-gable` | Duvar beyaz badana (malzeme rengi değişimi), çatı kiremit turuncusu |
| COP31 binası (`cop31`) | `town/wall-arch`, `pillar-stone`, `roof-flat`, `banner-green` | Taş kemerli belediye, yeşil COP31 bayrakları; Lv2/Lv3 kat eklenir |
| İtfaiye (`fire_station`) | `town/wall-doorway-square-wide`, `roof-flat` + `car/firetruck` | Kırmızı-beyaz garaj, önünde araç |
| Kuyu (`well`) | `nature/stone_tallA` + `town/poles`, `roof-point` | Taş bilezik, küçük kiremit çatı |
| Su kulesi (`water_tower`) | `town/pillar-wood`, `town/fountain-round` | Ahşap ayaklı depo |
| Tarla (`field`) | `nature/crops_dirtRow` + `crops_cornStage*` / `crops_leafsStage*` | Sebze bahçesi: domates/biber yerine yapraklı + mısır evreleri |
| Sera (`greenhouse`) | Koddan: yarı saydam kutu + `town/planks` iskelet | Antalya örtü altı serası (beyaz naylon görünüm) |
| Koru (`grove`) | `nature/tree_fat` / `tree_plateau` (zeytin), `tree_default` küçük ölçek (narenciye) | Turuncu küre meyveler koddan eklenir |
| Orman / dağ | `nature/tree_pineTall*`, `tree_pineRound*` (kızılçam), `cliff_*_rock` (Toroslar) | |
| Nehir / köprü | `nature/bridge_wood`, `bridge_stone`, `lily_*` | Su yüzeyi koddan (shader) |
| Süs | `nature/pot_large` (küp), `statue_column(Damaged)` (antik kalıntı), `tent_smallOpen` (yörük çadırı), `tree_palm*` (sahil) | |
| Köylüler | `chars/character-*` | `walk` yürürken, `pick-up` hasatta, `idle` beklerken |
| İtfaiye aracı | `car/firetruck`; traktör süs olarak `car/tractor` | |

## Blender ile değiştirme kuralı (özet)

Arkadaşın modelleri aynı klasöre **aynı dosya adıyla** `.glb` olarak konursa oyun kod değişmeden onları yükler. Ayrıntılı adlandırma belgesi X10'da (`docs/BLENDER_NAMING.md`).
