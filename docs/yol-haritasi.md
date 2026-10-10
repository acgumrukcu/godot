# Yol Haritası

Her aşama, bir öncekinin testleri geçtiği ve oynanarak onaylandığı varsayımıyla başlar.

## Aşama 0 — Altyapı
- [x] Godot 4.x projesi, git deposu, `.gitignore`
- [x] GUT test çerçevesinin kurulumu ve örnek bir geçen test
- [ ] GitHub Actions: her push'ta headless testler
- [x] JSON veri yükleyici + doğrulama (hatalı veride anlaşılır hata mesajı)

## Aşama 1 — Simülasyon çekirdeği (görsel yok)
- [ ] `SimClock`: tick tabanlı zaman, gün/saat
- [ ] `Economy`: para (kuruş), gelir/gider kaydı
- [ ] `Recipe` ve `Inventory`: malzeme stoku, ürün hazırlama
- [ ] `CustomerSpawner`: tohumlu rastgele müşteri gelişi, sipariş kararı (fiyat esnekliği)
- [ ] `DaySummary`: gün sonu raporu
- [ ] `SaveSystem`: sürümlü kayıt/yükleme + migrasyon iskeleti
- [ ] `tools/balance_sim.gd`: 30 günlük headless simülasyon, özet çıktı

## Aşama 2 — Oynanabilir prototip
- [ ] Yer tutucu görsellerle kafe sahnesi
- [ ] Müşterilerin gelip oturması, sipariş balonları
- [ ] Menü/fiyat ekranı, gün sonu ekranı
- [ ] Hız kontrolleri, trackpad/klavye kontrolleri
- [ ] **İnsan oyun testi:** eğlenceli mi? (Hayırsa Aşama 3'e geçme.)

## Aşama 3 — İçerik ve derinlik
- [ ] İsimli müdavimler ve ilişki sistemi
- [ ] Mobilya/dekor yerleşimi ve rahatlık puanı
- [ ] 15+ tarif, açılma ağacı
- [ ] Gerçek görseller ve ses

## Aşama 4 — Çıkışa hazırlık
- [ ] macOS dışa aktarım, notarizasyon, Mac App Store sandbox uyumu
- [ ] Steam sayfası, istek listesi kampanyası, Discord
- [ ] Kapalı beta

## Çıkış sonrası — canlı tutma planı
- Yorum ve geri bildirimlerin haftalık analizi → öncelikli iş listesi
- İlk 3 ay: 2 haftada bir küçük güncelleme
- Ardından: mevsimlik içerik güncellemeleri, ilk genişleme paketi
