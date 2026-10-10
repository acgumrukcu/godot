# Oyun Tasarım Belgesi (GDD) — Taslak

> Bu bir başlangıç taslağıdır. `[KARAR VER]` işaretli yerleri sen doldur.
> Ajanlar bu belgeyi gerçeğin kaynağı olarak kullanır; belgede olmayan özelliği uygulamazlar.

## 1. Tek cümlelik özet

Küçük bir sahil kasabasında, terk edilmiş bir dükkanı sıcak bir kafeye dönüştürüp
kasabalılarla bağ kurduğun, acelesiz bir işletme simülasyonu. Huzur veren doğa içinde bir mekan

## 2. Tasarım ilkeleri

- **Rahat, cezasız:** İflas yok, zaman baskısı yok. Kötü bir gün sadece daha az kazanç demektir.
- **Küçük adımlarla büyüme:** Her oyun gününde oyuncu yeni bir şey açmış ya da geliştirmiş hissetmeli.
- **Kişiler, rakamlardan önce:** Müşteriler isimli, tekrar gelen karakterlerdir.
- **Mac'e saygı:** Trackpad ve klavye ile akıcı kontrol, Apple Silicon'da yerel performans,
  sessiz ve pil dostu çalışma.

## 3. Ana oyun döngüsü

```
Sabah: menüyü ve fiyatları ayarla, malzeme sipariş et
  → Gün içi: müşteriler gelir, sipariş verir, hazırlanır, servis edilir
  → Akşam: günün özeti (kazanç, müşteri memnuniyeti, ilişkiler)
  → Kazançla: yeni tarif, mobilya, ekipman veya dekor aç
  → Ertesi gün
```

Süre hedefleri (bkz. `docs/kararlar/001-oyun-suresi.md`):
- Bir oyun günü 1x hızda yaklaşık 15 gerçek dakika: açık saatler ~12 dk + sabah/akşam
  ekranları oyuncunun kendi temposunda.
- MVP: ~30 oyun günü ≈ 7–8 saat (~500 dakika) içinde MVP içeriğinin tamamı açılır.
- Çıkış sürümü: ana ilerleme 15–20 saat (~60–80 oyun günü); sonrasında açık uçlu devam.

## 4. Sistemler (MVP kapsamı)

### 4.1 Zaman
- 1 tick = 1 oyun dakikası. Kafe 08:00–20:00 açık (720 tick).
- 1x hızda 1 tick = 1 gerçek saniye → açık saatler ~12 dk. Bu oran veride tutulur,
  Aşama 2 oyun testinden sonra ayarlanabilir.
- Hız seçenekleri: duraklat, 1x, 2x, 4x (açık saatler 12 / 6 / 3 dk).
- Sabah hazırlığı ve akşam özeti sırasında zaman akmaz.

### 4.2 Ekonomi
- Para birimi tam sayı (kuruş).
- Gelir: satılan ürünler. Gider: malzeme, isteğe bağlı kira yok şimdilik.
- Her ürünün maliyeti malzemelerinden hesaplanır; satış fiyatını oyuncu belirler.
- Fiyat yükseldikçe satın alma olasılığı düşer (müşteri tipine göre esneklik).

### 4.3 Menü ve tarifler
- Başlangıç: 3 ürün (ör. filtre kahve, çay, kurabiye).
- Tarifler `data/recipes.json` içinde: malzemeler, hazırlama süresi, temel fiyat, açılma koşulu.

### 4.4 Müşteriler
- Müşteri tipleri `data/customer_types.json`: tercihler, fiyat hassasiyeti, sabır, geliş saatleri.
- İsimli müdavimler: tekrar geldikçe ilişki seviyesi artar, küçük hikayeler/istekler açılır.

### 4.5 Kafe düzeni
- Izgara tabanlı yerleşim: masa, sandalye, tezgah, dekor.
- Dekor "rahatlık" puanı verir → müşteri memnuniyeti ve kalma süresi artar.

### 4.6 Kayıt
- Otomatik kayıt her günün sonunda. Sürümlü kayıt formatı (bkz. CLAUDE.md).
- İleride: iCloud senkronizasyonu (Mac App Store sürümü).

## 5. MVP dışında (sonraki güncellemeler için)

Çalışan almak, mevsimler ve festivaller, ikinci mekan, bahçede malzeme yetiştirme,
mod desteği, iPad sürümü. Bunlar `docs/yol-haritasi.md` içinde planlanır.

## 6. Görsel ve ses yönü

Sıcak renk paletli 2D, üstten 3/4 açı, el çizimi hissi.
Asset ihtiyaçları `docs/asset-listesi.md` içinde toplanır.

## 7. İş modeli

Tek seferlik ücretli temel oyun + ileride ücretli genişleme paketleri.
Mac App Store'da "ücretsiz indir, tek satın alımla tam sürüm" modeli değerlendirilecek.
Fiyat: şimdilik ücretsiz versiyon yapalım.

## 8. Rakip analizi

`Little restaurant, food court idle, my shopping mall` İncelenen oyunlar, kullanıcıların en sık şikayet ettiği konular ve
bizim bunlara cevabımız. (Geri bildirim ajanı bu bölümü destekleyebilir.)
