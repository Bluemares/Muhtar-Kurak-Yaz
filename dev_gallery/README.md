# Model ve animasyon galerisi

`Galeriyi-Ac.cmd` dosyasını çift tıklayın. Alternatif: Godot'ta `dev_gallery/gallery.tscn` sahnesini açıp **F6** ile çalıştırın. Ana oyun sahnesi değişmez.

- Kategori ve arama: köylüler, hayvanlar, bina seviyeleri, ürünler, araç, efektler, portreler ve tüm GLB dosyaları.
- Alt menü: seçili modelin hareketleri/durumları. Oynat/duraklat, hız ve zaman çubuğu.
- Sol fare tuşunu sürükleyin: yatay/dikey döndürme. Tekerlek: yakınlaştırma. Kamera sıfırlama: modele sığdırma.
- “Binalar”, “Köylüler” ve “Hayvanlar” oyunun ortak görünüm kodlarını kullanır. “Model dosyaları” arşivdeki alternatifleri de içerir; ham GLB ile oyunun nihai görünümü farklı olabilir.
- Kaydetme ve oyun ilerlemesi çalıştırılmaz. Bu bağımsız sahne yalnız yerel geliştirme içindir; bir erişim kontrolü/parola sistemi değildir.

Windows ve Web presetlerinin `exclude_filter` alanında `dev_gallery/*` bulunur. Oyun sahnelerinden galeriye referans yoktur. Sahne ayrıca export edilmiş çalışma ortamında açılmayı reddeder. Yeni export preseti eklenirse aynı klasör hariç tutulmalıdır.

Otomatik kontrol: Godot'u bu sahneyle ve `-- --gallery-check` argümanıyla çalıştırmak tüm katalog ve animasyon seçeneklerini açar; `GALLERY_OK` yazar. Görselli çalışmada `preview.png` üretir.
