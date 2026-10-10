# CLAUDE.md — Proje Anayasası

Bu dosya, bu projede çalışan tüm AI ajanları için bağlayıcı kurallardır.
Her oturumun başında bu dosyayı ve `docs/tasarim.md` dosyasını oku.

## Proje özeti

Rahat (cozy) bir işletme simülasyonu: oyuncu küçük bir kasabada bir kafe işletir,
menüsünü genişletir, müşterilerle ilişki kurar ve işletmesini yavaş yavaş büyütür.
Hedef platformlar: macOS (Mac App Store + Steam), ardından Windows (Steam).
Motor: **Godot 4.x**, dil: **statik tipli GDScript**.

Ayrıntılı tasarım: `docs/tasarim.md` — Yol haritası: `docs/yol-haritasi.md`

## Temel mimari kurallar (ihlal etme)

1. **Simülasyon ve görsel katman tamamen ayrıdır.**
   - `src/simulation/` içindeki kod `Node`, `SceneTree`, sahne veya UI'a bağımlı OLAMAZ.
     Sadece `RefCounted` / `Resource` tabanlı saf sınıflar kullan.
   - `src/ui/` simülasyonu okur ve komut gönderir; simülasyon durumunu doğrudan değiştirmez.
   - Simülasyon, ekran olmadan (headless) çalışabilmeli ve test edilebilmelidir.
2. **Simülasyon deterministiktir.**
   - Rastgelelik yalnızca simülasyona enjekte edilen tohumlu `RandomNumberGenerator` ile.
     Global `randi()` / `randf()` kullanma.
   - Zaman sabit tick'lerle ilerler (1 tick = 1 oyun dakikası). Gerçek zamana (`delta`)
     simülasyon mantığında bağlanma; `delta` sadece UI tarafında tick biriktirmek için kullanılır.
3. **İçerik veridir, kod değil.**
   - Ürünler, tarifler, mobilyalar, müşteri tipleri, fiyatlar `data/*.json` içindedir.
   - Yeni içerik eklemek kod değişikliği gerektirmemelidir. Gerektiriyorsa önce veri şemasını genişlet.
   - Her JSON dosyasının bir şeması/doğrulayıcısı ve testi olmalıdır.
4. **Kayıt dosyaları sürümlüdür.**
   - Her kayıtta `save_version` alanı bulunur.
   - Kayıt formatını değiştiren her değişiklik, eski sürümden yenisine bir migrasyon fonksiyonu
     ve bunun testini içermek ZORUNDADIR. Oyuncunun kaydını asla bozma.

## Kod stili

- Tüm değişken, fonksiyon ve sınıf adları İngilizce; yorumlar ve belgeler Türkçe olabilir.
- Statik tipleme zorunlu: `var money: int = 0`, `func add(a: int) -> int:`
- Para tam sayı (kuruş) olarak tutulur, float kullanılmaz.
- Dosya başına tek sınıf, `class_name` ile.
- Sihirli sayı yok; sabitler ya veri dosyasında ya da adlandırılmış `const` olarak.

## Komutlar

```bash
# Testleri çalıştır (GUT test çerçevesi, headless)
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit

# Ekonomi denge simülasyonu (N oyun günü, verilen tohumla)
godot --headless -s tools/balance_sim.gd -- --days=30 --seed=42
```

Bir görevi "bitti" saymadan önce testler geçmek ZORUNDADIR.

## Çalışma kuralları

- Tek seferde tek görev. Bir görev bir git dalı ve küçük, açıklayıcı commit'ler demektir.
- İstenmeyen yeniden düzenleme (refactor) yapma. Gerekli görüyorsan öner, uygulama.
- Belirsiz bir tasarım kararıyla karşılaşırsan tahmin etme; soruyu yaz ve dur.
- Önemli bir mimari karar alındığında `docs/kararlar/NNN-baslik.md` olarak kaydet
  (bağlam, karar, alternatifler, sonuçlar).
- Görsel/ses asset'lerini kendin üretme veya internetten indirme; yer tutucu kullan
  ve `docs/asset-listesi.md` dosyasına ihtiyacı yaz.
- İmzalama sertifikaları, App Store Connect ve Steamworks işlemleri insan sorumluluğundadır;
  bunlara dokunma.

## Klasör yapısı

```
CLAUDE.md            bu dosya
docs/                tasarım, yol haritası, kararlar
data/                tüm oyun içeriği (JSON)
src/simulation/      saf oyun mantığı (Node yok)
src/ui/              sahneler, arayüz, görsel katman
tests/               GUT testleri
tools/               denge simülasyonu, yorum analizi vb. betikler
.claude/agents/      uzman alt ajan tanımları
```
