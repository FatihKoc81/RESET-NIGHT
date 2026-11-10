# RESET NIGHT — Godot 4 3D Comic Survival

## Oyun modları
- Solo Hayatta Kalma: tek oyunculu dalga tabanlı hayatta kalma modu.
- Co-op Hayatta Kalma: ENet tabanlı oda oluşturma/oda katılma, 2–4 kişilik LAN bağlantı altyapısı.
- Hikaye & Görev: şehirden kaçış ve bölge temizleme modu için ayrı menü girişi (mevcut oynanış haritası kullanılır; görev zinciri geliştirme aşamasındadır).

## Co-op ağ altyapısı
`NetworkManager` autoload'u Godot 4 `ENetMultiplayerPeer` ile host/join işlemlerini, bağlantı olaylarını ve oda durumunu yönetir. Varsayılan port UDP 2456'dır. Aynı yerel ağdaki oyuncular host IP'siyle bağlanabilir. İnternet üzerinden oynama için host tarafında UDP port yönlendirme veya bir relay/dedicated server gerekir.

**Önemli geliştirme sınırı:** Bu commit lobi ve bağlantı temelini kurar; oyuncu karakterlerinin, düşmanların, envanterin ve oyun durumunun ağ üzerinden senkronizasyonu henüz uygulanmış değildir. Bu nedenle Co-op menüsünde oda kurma/katılma çalışması, tam senkronize çok oyunculu maçın tamamlandığı anlamına gelmez.

## Menü seçenekleri
- Oyna / Mod Seçimi: Solo, Co-op, Hikaye.
- Karakter Seçimi / Eşyalar: Lider ve Öncü görsel arketipleri; seçim cihazda saklanır.
- Ayarlar: ana ses ve dokunmatik hassasiyet ayarı saklanır; grafik profili mobil GL Compatibility'dir.
- Liderlik Tablosu: arayüz girişi hazır; gerçek çevrimiçi skor API'si henüz bağlı değildir.

## Android
Android application ID: `com.fatihkoc.resetnight`, version `1.4.1` (code 6). Debug APK imzalama anahtarı sabittir; test APK güncellemeleri aynı anahtarla imzalanmalıdır.

Godot 4.3+, Android SDK, JDK ve Godot Android export templates gerekir:
```bash
cd godot
./build_android.sh
```
