# RESET NIGHT — Godot 4 3D

Bu klasör, mevcut Android/Capacitor sürümünden ayrı tutulan Godot 4 tabanlı 3D üçüncü şahıs hayatta kalma prototipidir.

## Açma
1. Godot 4.3 veya daha yeni bir Godot 4 sürümünü açın.
2. Bu klasördeki `project.godot` dosyasını seçin.
3. `scenes/Main.tscn` sahnesini çalıştırın.

## Kontroller
- WASD: hareket
- Fare: karakter yönü
- Space: çivili sopa
- Q: molotof
- F: pompalı
- R: pompalı doldur
- L: el fenerini aç/kapat
- Android: sol alt alanda sanal joystick; sağ alttaki aksiyon tuşları ve fener düğmesi

## Harita ve atmosfer
- `scenes/maps/MapBase.tscn`: 3D harita kökü, WorldEnvironment, ay ışığı, NavigationRegion3D, GridMap3D, çevre nesneleri ve SpawnPoints3D.
- `scripts/map_environment.gd`: çatlak asfalt, beton kaldırımlar, terk edilmiş araçlar, sokak lambaları, yanan variller, tel örgü ve yıkık duvarları prosedürel olarak üretir.
- Gece ortamı #050608 arka plan, #0a0c12 ambient renk/0.15 enerji, #0f1218 sis/0.035 yoğunluk ve #1a233a ay ışığı/0.18 enerjiyle ayarlıdır. Godot projesi GL Compatibility kullandığından volumetrik sis bu render modunda etkinleştirilemez; standart atmosferik sis kullanılır.
- Oyuncu feneri CameraPivot altındaki SpotLight3D: 45 derece, 2.8 enerji, 16 m menzil ve gerçek zamanlı gölge desteği.
- Fener açıkken düşman algılama mesafesi 1.7 katına çıkar; kapalıyken algılama 3 m yakın mesafeyle sınırlıdır.
- Düşman görüşü fizik ışın testiyle engellere takılır.

## Silahlar
- Çivili sopa: 25 hasar, 1.2 sn bekleme, %15 sersemletme.
- Molotof: 5 sn yangın alanı, saniyede 15 hasar.
- Paslı pompalı: 6 saçma, 12 hasar/saçma, 2+20 mühimmat, 2.5 sn doldurma.

## Teknik not
Harita nesneleri bu prototipte Godot primitive mesh ve malzemeleriyle üretilen oynanabilir placeholder varlıklardır; listelenen PNG sanat dosyaları henüz çizilmiş gerçek texture dosyaları değildir. Godot Android APK export işlemi ayrıca yapılandırılmalı ve cihazda test edilmelidir.
