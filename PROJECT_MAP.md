# RESET NIGHT — Proje Haritası

> İlk harita: 18 Kasım 2026. README ve depo kökü esas alınmıştır. Godot sahne/düğüm bağımlılıkları ayrıca sahne dosyaları üzerinden çıkarılmalıdır.

## Projenin amacı
Mobil hayatta kalma oyunu. Depo README'sinde ilk oynanabilir sürüm tek oyunculu, çevrimdışı gece savunması olarak tanımlanıyor.

## Oynanış akışı
Oyuncu hareketi (sanal joystick/WASD) → düşman etkileşimi → yakın dövüş/ateş → sağlık ve şarjör yönetimi → cihazda rekor saklama.

## Kök dosyalar
- `README.md`: oyun özeti, kontroller ve APK dağıtım bilgisi.
- `CLAUDE.md`, `CLAUDE_TASK.md`: Claude proje bağlamı ve görev notları.
- `GEMINI.md`: Gemini proje yönergeleri.
- `capacitor.config.json`: Capacitor yapılandırması.
- `firebase-config.js`: Firebase istemci yapılandırma dosyası; içeriği ve kullanım amacı ayrıca denetlenmeli.
- `godot-android.yml`: Android derleme iş akışı.
- `.github/`: GitHub Actions ve depo otomasyonu.
- `IMG-20261110-WA0002.jpg`: görsel referans.

## Kontroller
- Sol sanal joystick: hareket
- VUR: yakın dövüş
- ATEŞ: en yakın düşmana ateş
- İLK YARDIM: sağlık yenileme
- DOLDUR: şarjör doldurma
- Klavye: WASD, Space, J, H, R

## Derleme ve dağıtım
- GitHub Actions içindeki RESET NIGHT Android APK iş akışı.
- Başarılı çalışmanın `RESET-NIGHT` artifact'i.
- Oyun adı ve resmî logo korunmalı; rekor cihazda saklanır.

## Mimari doğrulama notu
Proje geçmişinde Godot 4 3D hedefi belirlenmişti; ancak mevcut README tek başına sahnelerin gerçekten 3D olduğunu kanıtlamaz. Sahne ağacı ve proje ayarları incelenmeden 3D mimari tamamlandı denmemelidir.

## Harita güncelleme kuralı
Her yeni sahne, script, oyun modu, faction, kontrol veya export adımı eklendiğinde bu dosyayı güncelle.
