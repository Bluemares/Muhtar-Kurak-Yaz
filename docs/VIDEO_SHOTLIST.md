# 60 sn Tanıtım Videosu — 3D Çekim Listesi (Sürüm 4.6)

Senaryo ve dış ses metni: `docs/SUNUM.md` → "60 Saniyelik Tanıtım Videosu Çekim Senaryosu". Bu dosya **3D Antalya köyü sürümünün nasıl çekileceğini** anlatır.

## Kayıt yöntemi (önerilen: Godot film modu, takılmasız)

Proje klasöründe çalıştır; dosya B: diskine yazılır:

```
B:\Godot\godot.exe --path "B:\app\oyunlar\MUHTAR KURAK YAZ" --write-movie "B:\app\oyunlar\MUHTAR KURAK YAZ\build\video\cekim.avi" --fixed-fps 60
```

- Oyun normal açılır, sen oynarsın; her kare kaybolmadan AVI'ye yazılır (ses dahil).
- Pencereyi kapatınca kayıt biter. AVI'yi kurgu programında (DaVinci Resolve, Clipchamp vb.) kes.
- `build\video` klasörünü önce oluştur.

Alternatif: OBS ile pencere kaydı (60 fps).

## Çekim için tuşlar (editör/debug çalıştırmada; F9 release'te de açık)

| Tuş | Ne yapar | Ne için |
|---|---|---|
| Sağ tık sürükle / Q-E | 3D kamerayı döndür ve eğ | Toroslar, Akdeniz ve köyü sinematik tanıtmak |
| Çift sol tık | Binaya odaklan | Sera, ambar, COP31 veya tarlayı yakından göstermek |
| B | İnşa dükkanını aç/kapat | 3D bina kartlarını göstermek |
| R | Seçili / yerleştirilen binayı döndür | Binaları yerleştirirken veya seçiliyken çevirmek |
| F | Yangın riski haritası (alev butonu) | Tutuşma olasılığı katmanını göstermek |
| N | Toprak nemi haritası (damla butonu) | Tarlaların nem durumunu göstermek |
| F7 | HUD gizle/göster | Temiz 3D sinematik vadi planları |
| F4 | +500 altın | Hızlıca ambar/sera/yol kurmak |
| F3 | Rastgele tarlaya böcek | İlaçlama sahnesi |
| F2 | Yangın çıkar | 3D itfaiye aracı + canlı 3D hortum mini oyunu |
| F1 | Tur süresini 30 sn yap | Gün batımı/gece ve ay geçişini hızlandırmak |
| F5 | Turu hemen bitir | Ay sonu özeti + iklim notu + COP31 politikası |

## 60 Saniyelik Plan Listesi (3D Antalya Köyü)

| # | Süre | Plan | Nasıl Çekilir? |
|---|---|---|---|
| **1** | **0–6 sn** | **Ana menü (dönen 3D köy):** Gün batımında yaşayan Antalya köyü dönerken solda Witcher tarzı dikey menü | Menüde 4–5 sn bekle, ardından *Yeni Oyun*'a tıkla |
| **2** | **6–14 sn** | **Kamerayı döndürerek köyü tanıtma:** Kuzeyde Toros dağları ve kızılçamlar, güneyde Akdeniz kıyısı ve palmiyeler; Hasan Dayı ve Elif'in görev kartı | Sağ tık sürükle veya `Q`/`E` ile kamerayı yumuşakça döndür, tekerlekle vadiyi göster |
| **3** | **14–24 sn** | **Dükkandan bina + düşüş + ürün seçimi:** 3D İnşa dükkanından Ambar, Sera ve Tarla seçilir (`R` ile döndürülür), gökyüzünden toz kaldırarak düşer; tarla ve serada *Ürün seç → Buğday* seçilir | `B` → Tarım sekmesi → yola bitişik yerleştir; tarla/seraya tıkla → *Ürün seç* |
| **4** | **24–32 sn** | **Dokunarak hasat + Pazar + Nem (N) ve Risk (F) haritaları:** Köylüler çapayla çalışır ve kuyudan su kulesine kova taşır; olgun tarlada balona tıklanır (+%15 bonus), altın/ürün ikonları üst çubuğa uçar; Pazar ile `N` ve `F` haritaları açılır | Balona tıkla; üstteki yiyecek hapına tıklayıp Pazarı göster; `N` (Toprak nemi) ve `F` (Yangın riski) tuşlarına bas |
| **5** | **32–40 sn** | **Gün batımı / gece + karar kartı:** Ev pencereleri ve sokak lambaları yanar; Fatma Teyze'nin *"Anız yakma izni"* karar kartı reddedilir | Gece ışıklarını göster, karar kartında *Yasakla* seçeneğine bas |
| **6** | **40–52 sn** | **Ağustos (sararan ağaçlar) + Yangın + İtfaiye + Mini oyun:** Kurak vadide yangın çıkar, siren ışıklı 3D itfaiye aracı yol ağından gelir, canlı 3D hortum mini oyununda alevler söndürülür | Ağustos'ta `F2` ile yangın çıkar (*Geç*'e basma), hortumla alevleri söndür |
| **7** | **52–60 sn** | **Final ekranı:** Gündüz konfetileri eşliğinde 3 yıldızlı *"Köyün örnek oldu!"*, *"Gıda güvenliği: köylüler zamanın %X'inde tok"*, Önlem vs Hasar çubukları ve slogan | Ağustos'u bitir (`F5`), yıldızların ve puanın doluşunu kaydet |

## İpuçları
- Kamera dönüşlerinde sağ tık sürüklemeyi yavaş ve akıcı kullan; bir binayı vurgulamak için üzerine **çift tıkla**.
- `F7` ile HUD'u gizleyip Toroslar'dan Akdeniz'e doğru 2–3 saniyelik temiz bir 3D vadi planı al.
- Müzik (Hicaz teması) ve gündüz ağustos böceği korosu oyunun içinden gelir; ayrı ses eklemene gerek yok.
