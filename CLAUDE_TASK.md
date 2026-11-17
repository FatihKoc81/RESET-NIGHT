# RESET NIGHT — Sıradaki doğrudan geliştirme görevi

Claude Code baş geliştiricidir. CLAUDE.md ve GEMINI.md talimatlarına uy. Kullanıcı doğrudan main'e commit ve otomatik APK üretimine açıkça izin verdi.

Bu görevde yalnızca SAVUNMA/SALDIRI fraksiyon seçimi ve insan düşman üretimi/AI temelini denetle ve bir sonraki küçük, doğrulanabilir ilerlemeyi yap.

1. Önce main dalındaki Godot 4 projesini, son commitleri ve mevcut sahne/betikleri incele. Özellikle faction manager, enemy spawner, NPC AI, faction selection ve gameplay scene bağlantılarını bul.
2. SALDIRI ve SAVUNMA akışlarının gerçekten oynanabilir olup olmadığını mevcut kod üzerinden doğrula. SALDIRI fraksiyonu seçilince insan karakter/karşıt taraf davranışı kuruluyor mu kontrol et.
3. En kritik tek hatayı veya eksik bağlantıyı seç ve küçük kapsamlı düzelt. Zombi/undead/infected ekleme. İnsan düşmanlar kullan.
4. SOLO akışını ve sahne referanslarını Godot 4.3 headless import, script parse ve mevcut scene validation araçlarıyla test et.
5. Her tutarlı değişikliği doğrudan main'e commit et ve push et. PR oluşturma.
6. Değişiklik godot/** altında olduğunda Android APK workflow'unu izle. Export/release başarılıysa APK bağlantısını raporla; başarısızsa logları incele, makul bir düzeltme denemesi yap ve sonucu açıkça raporla.
7. Gemini'den hedefli Godot 4 incelemesi ve test önerisi iste. Büyük kapsamlı yeniden yazım yapma.
8. EKİP ve HİKÂYE modlarını çalışmıyorlarsa tamamlandı diye sunma. Android gerçek cihaz testi yapıldı diye iddia etme.

Bu turda yalnızca fraksiyon ve insan düşman temelini ele al. Silah/enventer gibi diğer sistemlere geçme.
