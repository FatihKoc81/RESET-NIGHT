# RESET NIGHT — Godot 4 3D Comic Survival

## Çalıştırma
Godot 4.3+ ile bu klasördeki `project.godot` dosyasını açın. Ana menüde **OYUNA BAŞLA**, doğrudan `scenes/maps/Map3D.tscn` oyun alanını açar. Harita sahnesi oyuncu, düşman üretimi, barikatlar, HUD ve mobil dokunmatik kontrolleri kendi içinde barındırır.

## 3D sahne yapısı
- `scenes/maps/Map3D.tscn`: oynanabilir ana harita ve tüm oyun bileşenlerinin giriş sahnesi.
- `scenes/player/Player3D.tscn`: CharacterBody3D oyuncu, kamera, fener ve Gun3D.
- `scenes/enemies/ZombieWalker3D.tscn`: çizgi roman kaplamalı yürüteç zombi görseli.
- `scenes/ui/MobileControls.tscn`: mobil sanal joystick girişi; HUD aksiyon düğmeleriyle birlikte çalışır.

## Comic / cel-shading
`shaders/comic_cel.gdshader` basamaklı ışıklandırma ve çapraz tarama dokusu uygular. `shaders/ink_outline.gdshader` siyah dış konturu üretir. Oyuncu, zombi ve pompalı tüfek materyalleri bu iki shader katmanını kullanır. Stil, The Walking Dead çizgi romanının atmosferinden esinlenen özgün bir uygulamadır; resmi görsel varlık içermez.

## Android APK
- `export_presets.cfg`: Android / arm64-v8a dışa aktarma profili.
- `build_android.sh`: Godot 4 headless import, Android export ve APK dosyası doğrulama adımları.
- GitHub Actions: `.github/workflows/godot-android.yml`; Godot 4.3 CI ortamında APK üretip artifact olarak yükler.

Yerel derleme için Godot 4.3+, Android SDK, JDK ve Android export templates kurulu olmalıdır:
```bash
cd godot
./build_android.sh
```

Not: Kaynak kod GitHub'a push edildiğinde CI iş akışı tetiklenir. APK'nın gerçekten üretildiği, ilgili GitHub Actions çalışması başarılı olduktan sonra doğrulanmış olur.
