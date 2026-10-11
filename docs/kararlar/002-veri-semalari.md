# 002 — Veri dosyaları ve şema doğrulama

Tarih: 2026-10-10 — Durum: Kabul edildi

## Bağlam

CLAUDE.md kural 3: içerik `data/*.json` içinde tutulur ve her dosyanın bir şeması ile testi olmalıdır.
Hatalı veri oyunu sessizce bozmamalı; hata, dosya ve alan adıyla anlaşılır şekilde raporlanmalıdır.
Godot 4'ün JSON ayrıştırıcısı bütün sayıları `float` olarak okur, oysa para kuruş cinsinden `int` tutulur.

## Karar

- Her `data/<ad>.json` dosyasının şeması `data/schemas/<ad>.schema.json` dosyasıdır.
  `DataLoader.load_data("<ad>")` bu ikisini birlikte yükler.
- Şemalar JSON Schema'nın **kendi küçük alt kümesi**dir (`SchemaValidator` başlığındaki listeye bakın).
  `int` tipi JSON'dan gelen tam sayı değerli float'ları gerçek `int`'e çevirir.
- Bilinmeyen alanlar varsayılan olarak hatadır (yazım hatalarını yakalamak için).
  `additional_properties: true` ile açılabilir; bu ek alanlar doğrulanmaz ve dönüştürülmez.
- Şemanın kendisi, veriye bakılmadan önce eksiksiz doğrulanır (`validate_schema`). Bozuk bir şema,
  ilgili alan veride bulunmasa bile hata verir.
- Hata varsa `DataLoadResult.data` `null` olur ve hatalar `dosya: $.alan[i]: mesaj` biçiminde döner.
- `tests/data/test_data_files.gd` testi bütün veri dosyalarını ve şemaları otomatik olarak kapsar.

## Alternatifler

- **Tam JSON Schema (draft 2020-12) uygulaması:** Godot için hazır ve bakımı süren bir kütüphane yok.
  Kendimiz yazarsak ihtiyacımızdan çok daha büyük olur.
- **Godot `Resource` (.tres) dosyaları:** Editörde rahat düzenlenir. Ancak metin olarak okunması zor,
  mod desteği ve araç betikleri (denge simülasyonu) için daha az taşınabilir.
- **Doğrulamayı her yükleyici sınıfta elle yazmak:** Tekrar eder ve hata mesajları tutarsız olur.

## Sonuçlar ve bilinen sınırlamalar

- Yeni bir içerik türü eklemek için yeni bir JSON dosyası ve şema yeterlidir; kod gerekmez.
- **Alanlar arası kurallar** (ör. `close_hour > open_hour`) şemayla ifade edilemez. Bunlar, veriyi
  kullanan tipli sınıfta (ör. Aşama 1'deki `SimClock` / oyun ayarları sınıfı) kontrol edilip test edilmelidir.
- **Yinelenen anahtarlar** (`{"a": 1, "a": 2}`) Godot ayrıştırıcısında hata vermez; son değer kalır.
  Bunu yakalamak gerekirse ayrı bir denetim aracı yazılmalıdır.
- **`float`'a kayıpsız sığan sınır:** 2^53'ten büyük tam sayılar reddedilir. Kuruş cinsinden para için bu sınıra
  ulaşılmaz.
- **Dışa aktarma:** `export_presets.cfg` oluşturulurken `data/**/*.json` dosyalarının pakete girdiği
  doğrulanmalıdır (gerekirse `include_filter` ile). Aşama 4'te kontrol edilecek.
