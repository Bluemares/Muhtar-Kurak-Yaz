# Testleri çalıştırma

Python 3 ve Godot 4.7.1 ile, proje kökünden:

```powershell
python tools/run_tests.py --godot "C:\path\Godot_console.exe"
python tools/run_tests.py --godot "C:\path\Godot_console.exe" contact_regressions farm_cycle pedestrians
python tools/run_tests.py --godot "C:\path\Godot_console.exe" --visual animal_motion river_quest farm_visual
python tools/run_tests.py --godot "C:\path\Godot_console.exe" --seed 3 farm_cycle
python tools/run_tests.py --godot "C:\path\Godot_console.exe" --clean-import --visual --timeout 300
python tools/run_tests.py --godot "C:\path\Godot_console.exe" --bot-policy chaos --seed 3 balance_bot
```

Koşucu projeyi geçici klasöre kopyalar. Asıl projenin kayıt, ayar ve import
dosyalarını değiştirmez. Her test temiz kayıt durumuyla başlar. `user://`
çıktıları da geçici klasöre yönlendirilir. Klasör yolu başlangıçta yazılır;
günlükler, `results.json` ve ekran görüntüleri inceleme için orada tutulur.
`--clean-import` mevcut import önbelleğini kullanmaz; silinen bir asset'in
önbellekteki kopyasıyla gizlenmesini önlemek için temizlik sonrasında kullanılır.
Windows/Linux üzerinde `user://` kökü de geçici çalışma klasörüne alınır.

Varsayılan koşu headless'tır. Render gerektiren sahneler `SKIP` olarak
raporlanır; bunları çalıştırmak için `--visual` gerekir. Bu sahneler doğrudan
headless açıldığında da `TEST_SKIP` yazıp çıkar. Atlanan test geçmiş sayılmaz.

Her sahne için varsayılan duvar saati sınırı 240 saniyedir (`--timeout`).
Başarı için süreç 0 ile çıkmalı, sahnenin `TEST_OK <ad>` işareti bulunmalı ve
script/engine hatası veya `SAVE FAIL` olmamalıdır. Assertion sonrası sahnenin
asılı kalması süre aşımı olarak başarısız sayılır. Koşucu herhangi bir
başarısızlıkta 1 ile çıkar; `--quit-after` çıkış koduna güvenmez.
Script hatası görüldüğünde süre sınırının dolmasını beklemeden ilgili süreci
sonlandırır. Koşucunun kendi kontrolleri: `python tools/test_run_tests.py`.

Mevcut Godot kapanışındaki `resources still in use at exit` ve
`RID allocations ... were leaked at exit` mesajları ayrı bir
kaynak sızıntısı uyarısı olarak `results.json` içinde tutulur; başarıyı tek
başına bozmaz. Diğer engine hataları başarısızlıktır.

`farm_cycle` varsayılan seed 3 ile çalışır: diğer işçilerin dondurulduğu eski
senaryoda temizleme takılmasını tekrar üretir. Temizleme aşamasında bütün
işçiler ilerletilir; normal oyundaki yaya kaçınma davranışı korunur.
`--greenhouse` varyantı sahneyi doğrudan izole kopyada çalıştırırken kullanılabilir.

Kayıt silen testleri asıl proje üzerinde doğrudan çalıştırmayın; koşucuyu kullanın.

`resume_context`, ay ortasında kaydet/yükle sırasında hava olaylarını, karar
kartlarını, yangın sayısını ve yan görev ilerlemesini doğrular. `round_resume`,
ay sonu raporundan ve politika seçiminden devam etmeyi, ödüllerin tekrar
verilmemesini ve Ağustos raporundaki final düğmesini kontrol eder.
