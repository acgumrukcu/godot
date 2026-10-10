# 001 — Oyun günü ve toplam oyun süresi

Tarih: 2026-10-10 — Durum: Kabul edildi (Aşama 2 oyun testinde yeniden değerlendirilecek)

## Bağlam

Tasarım belgesinde "bir oyun günü gerçek zamanda yaklaşık 500 dakika" yazıyordu. Bu bir günün
değil, oyunun toplam oynanabilir süresinin hedefiydi. Hem gün uzunluğu hem toplam süre
belirsizdi. `SimClock` ve denge simülasyonu bu değerlere dayanacak.

## Karar

- 1x hızda 1 tick (1 oyun dakikası) = 1 gerçek saniye. 08:00–20:00 arası 720 tick, yani yaklaşık 12 dakika.
- Sabah hazırlığı ve akşam özeti sırasında zaman durur. Bunlarla bir gün yaklaşık 15 dakika sürer.
- MVP hedefi: yaklaşık 30 oyun günü, yani 7–8 saat (~500 dk). MVP içeriğinin tamamı bu sürede açılır.
  Denge simülasyonunun varsayılanı olan `--days=30` bu hedefi ölçer.
- Çıkış sürümü hedefi: ana ilerleme 15–20 saat (~60–80 oyun günü), ardından açık uçlu oyun.
- Saniye/tick oranı veride (sabit/ayar dosyası) tutulur, kodda sabit yazılmaz.

## Alternatifler

- **Günde 5–8 dakika:** İlerleme hissi hızlı olur ama müşteri akışı ve ilişkiler yüzeysel kalır,
  ayrıca gün sonu ekranı çok sık araya girer.
- **Günde 20+ dakika:** Çok yavaş kalır; "her gün yeni bir şey" ilkesiyle çelişir.
- **Toplam 500 dk'yı tam oyun olarak hedeflemek:** Ücretli genişleme modeli ve canlı tutma
  planı için kısa kalır.

## Sonuçlar

- `SimClock` gerçek zamandan bağımsız kalır; oran yalnızca UI'daki tick biriktiricide kullanılır.
- Ekonomi ve açılma ağacı 30 günde MVP içeriğini bitirecek şekilde dengelenmelidir.
- Aşama 2 oyun testinde gün uzunluğu yeniden ölçülür. Gerekirse oran değiştirilir ve bu belge güncellenir.
