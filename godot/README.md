# RESET NIGHT — Godot 4 3D Third-Person Survival

RESET NIGHT'in oyun mimarisi Godot 4 3D olarak yapılandırılmıştır. Oyun 3D karakter, 3D çevre, üçüncü şahıs kamera, fener, 3D silah ve mobil dokunmatik kontroller kullanır.

## Açma
1. Godot 4.3 veya daha yeni bir Godot 4 sürümüyle `godot/project.godot` dosyasını açın.
2. Ana menüden **OYUNA BAŞLA** seçin.
3. Oyun sahnesi `scenes/Main3D.tscn`; 3D harita `scenes/maps/Map3D.tscn` ve oyuncu `scenes/player/Player3D.tscn` dosyalarıdır.

## 3D mimari
- `Player3D.tscn`: CharacterBody3D, CapsuleShape3D, 3D karakter görseli, Gun3D, SpringArm3D, Camera3D, SpotLight3D ve InventoryManager.
- `Map3D.tscn`: Node3D, WorldEnvironment, ay ışığı, NavigationRegion3D, zemin/çevre düğümleri ve spawn işaretleri.
- `Main3D.tscn`: harita, oyuncu, düşman üretici, barikat üretici, HUD ve mobil kontrolleri birleştirir.
- Eski Player.tscn ve MapBase.tscn dosyaları geriye dönük referans için korunur; ana oyun akışında kullanılmaz.

## Kontroller
- PC: WASD hareket, fare kamera yönü, Space sopa, F pompalı, R doldur, Q molotof, L fener, E ara, H ilk yardım, I çanta.
- Android: sol alt sanal joystick; sağ üst ekranda sürükleme ile kamera; HUD üzerindeki VUR, ATEŞ, İLK YARDIM, DOLDUR, FENER ve ARA düğmeleri.

## Atmosfer ve performans
- Gece arka planı #050608; ambient ışık düşük, ay ışığı soğuk ve zayıf, standart atmosferik sis etkin.
- Oyuncu feneri SpotLight3D, 45 derece açı, 16 metre menzil, gölge desteği.
- Proje Android uyumluluğu için GL Compatibility renderer kullanır. Bu renderer volumetrik sis desteklemediği için gerçek volumetrik sis yerine performans dostu standart 3D fog kullanılır.
- Çevre nesneleri prosedürel primitive mesh placeholder'lardır. Gerçek sanat varlıkları ve ayrıntılı LOD modelleri henüz eklenmemiştir.

## Önemli
GitHub'a gönderilen kaynaklar cihazda Godot editörüyle açılıp Android export alınarak test edilmelidir. Bu çalışma otomatik olarak imzalı APK üretmez.
