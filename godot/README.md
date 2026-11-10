# RESET NIGHT — Godot 4

Bu klasör, mevcut Android/Capacitor sürümünü bozmadan aynı GitHub deposuna eklenen Godot 4 tabanlı 3D üçüncü şahıs prototipidir.

## Açma
1. Godot 4.3 veya daha yeni bir Godot 4 sürümünü açın.
2. Import penceresinde bu klasördeki `project.godot` dosyasını seçin.
3. `scenes/Main.tscn` sahnesini çalıştırın.

## Kontroller
- WASD: hareket
- Fare: karakter yönü
- Space: çivili sopa
- Q: molotof
- F: pompalı
- R: pompalı doldur
- Android: sol alt alanda sanal joystick; sağ alttaki aksiyon tuşları

## İlk oynanabilir sistem
- 3D üçüncü şahıs kamera ve karakter hareketi
- Düşmanların oyuncuyu takip etmesi ve yakın dövüş hasarı
- Çivili sopa: 25 hasar, 1.2 sn bekleme, 15% sersemletme ihtimali
- Molotof: 400 px/s şartının 3D karşılığı olarak 16 m/s fırlatma, 15 hasar/sn, 5 sn yanma alanı
- Paslı pompalı: 6 saçma, 12 hasar/saçma, 2+20 mühimmat, 2.5 sn doldurma
- Mobil dokunmatik kontroller ve düşük maliyetli GL Compatibility renderer

## Not
Bu ilk Godot prototipi, mevcut web tabanlı Android APK hattından ayrı tutulur. Mevcut APK ve GitHub Actions iş akışı değiştirilmemiştir. Godot Android export şablonlarıyla ayrıca APK alınabilir.
