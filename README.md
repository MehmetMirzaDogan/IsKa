# İş Kamera Uygulaması

İş yerinde çekilen fotoğrafları düzenli bir şekilde yönetmek için geliştirilmiş bir Flutter mobil uygulamasıdır.

## 🎯 Özellikler

### Kullanıcı Yönetimi
- ✅ Kullanıcı kayıt ve giriş sistemi
- ✅ Güvenli oturum yönetimi (SharedPreferences)
- ✅ Otomatik giriş yapma

### Fotoğraf Çekimi
- 📷 Yerleşik kamera desteği
- 🔄 Ön/Arka kamera değiştirme
- 📸 Yüksek kaliteli fotoğraf çekimi
- 💾 Otomatik kaydetme

### Albüm Yönetimi
- 📁 Manuel albüm oluşturma
- 📅 Otomatik günlük albüm oluşturma (tarih bazlı)
- 🗑️ Albüm silme özelliği
- 🏷️ Albüm türü gösterimi (Otomatik/Manuel)

### Fotoğraf Detayları
- 👤 Fotoğrafı çeken kişinin adı
- 📅 Çekim tarihi
- ⏰ Çekim saati
- 🔍 Tam ekran görüntüleme
- 🔎 Zoom (pinch to zoom) özelliği
- ➡️ Sağa/Sola kaydırarak fotoğraflar arası geçiş

### Galeri Görünümü
- 📱 Grid layout ile albüm görüntüleme
- 🖼️ Grid layout ile fotoğraf görüntüleme
- 🗑️ Fotoğraf silme (uzun basma)
- 🔄 Yenileme (pull to refresh)

## 🛠️ Teknolojiler

- **Flutter**: Mobil uygulama framework'ü
- **SQLite**: Yerel veritabanı (sqflite)
- **Camera Plugin**: Kamera işlemleri
- **SharedPreferences**: Oturum yönetimi
- **Path Provider**: Dosya yolu yönetimi
- **Intl**: Tarih/saat formatlama

## 📦 Kurulum

### Gereksinimler
- Flutter SDK (3.9.2 veya üzeri)
- Dart SDK
- Android Studio / VS Code
- iOS için: Xcode (macOS)
- Android için: Android SDK

### Adımlar

1. **Projeyi klonlayın**
```bash
cd work_camera_app
```

2. **Bağımlılıkları yükleyin**
```bash
flutter pub get
```

3. **Uygulamayı çalıştırın**
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

## 📱 Kullanım

### İlk Kullanım

1. **Kayıt Ol**: Uygulamayı ilk açtığınızda kayıt olun
   - Ad Soyad
   - Kullanıcı Adı (en az 3 karakter)
   - Şifre (en az 6 karakter)

2. **Giriş Yap**: Mevcut hesabınızla giriş yapın

### Fotoğraf Çekme

1. Ana ekrandaki **"Fotoğraf Çek"** butonuna basın
2. Albüm seçin veya günlük albüm kullanın
3. Kamera açılacak, beyaz butona basarak fotoğraf çekin
4. Fotoğraf otomatik olarak seçili albüme kaydedilecek

### Albüm Oluşturma

1. Ana ekrandaki **"+"** (klasör) butonuna basın
2. Albüm adı girin (örn: "Proje A", "Site İnşaatı")
3. **"Oluştur"** butonuna basın

### Fotoğrafları Görüntüleme

1. Ana ekrandan bir albüme tıklayın
2. Fotoğraf listesi görüntülenir
3. Bir fotoğrafa tıklayarak detayları görüntüleyin
   - Çeken kişi
   - Tarih
   - Saat
4. Fotoğraflar arası geçiş için sağa/sola kaydırın

### Silme İşlemleri

- **Albüm Silme**: Albüm kartındaki çöp kutusu ikonuna basın
- **Fotoğraf Silme**: Fotoğraf üzerine uzun basın

## 🏗️ Proje Yapısı

```
lib/
├── models/              # Veri modelleri
│   ├── user.dart       # Kullanıcı modeli
│   ├── album.dart      # Albüm modeli
│   └── photo.dart      # Fotoğraf modeli
│
├── services/            # İş mantığı katmanı
│   ├── database_service.dart    # SQLite işlemleri
│   ├── auth_service.dart        # Kimlik doğrulama
│   ├── album_service.dart       # Albüm işlemleri
│   └── camera_service.dart      # Kamera işlemleri
│
├── screens/             # Ekranlar
│   ├── login_screen.dart            # Giriş ekranı
│   ├── register_screen.dart         # Kayıt ekranı
│   ├── home_screen.dart             # Ana ekran (Albümler)
│   ├── camera_screen.dart           # Kamera ekranı
│   ├── album_detail_screen.dart     # Albüm detay
│   └── photo_detail_screen.dart     # Fotoğraf detay
│
└── main.dart            # Uygulama giriş noktası
```

## 🔐 Güvenlik Notu

⚠️ **ÖNEMLİ**: Bu uygulama demo amaçlıdır. Üretim ortamında kullanmadan önce:
- Şifreleri hash'leyin (bcrypt, argon2, vb.)
- HTTPS kullanın
- Daha güvenli bir kimlik doğrulama sistemi ekleyin
- Token tabanlı kimlik doğrulama kullanın

## 📝 Veritabanı Şeması

### Users Tablosu
```sql
- id: INTEGER PRIMARY KEY
- username: TEXT (UNIQUE)
- password: TEXT
- name: TEXT
- created_at: TEXT
```

### Albums Tablosu
```sql
- id: INTEGER PRIMARY KEY
- name: TEXT
- user_id: INTEGER (Foreign Key)
- created_at: TEXT
- is_auto_generated: INTEGER (0/1)
```

### Photos Tablosu
```sql
- id: INTEGER PRIMARY KEY
- path: TEXT
- album_id: INTEGER (Foreign Key)
- user_id: INTEGER (Foreign Key)
- taken_at: TEXT
- taken_by: TEXT
```

## 🎨 Özellikler

### Otomatik Albüm Oluşturma
- Eğer kullanıcı fotoğraf çekmeden önce albüm seçmezse
- O günün tarihi ile otomatik albüm oluşturulur (örn: "18.11.2025")
- Aynı gün içinde çekilen tüm fotoğraflar bu albüme eklenir

### Kullanıcı Deneyimi
- Modern ve sezgisel arayüz
- Material Design 3
- Gradient renkler
- Animasyonlu geçişler
- Loading göstergeleri
- Hata mesajları

## 🚀 Gelecek Özellikler (Planlanan)

- [ ] Cloud backup
- [ ] Fotoğraf paylaşma
- [ ] Fotoğraf düzenleme
- [ ] Arama ve filtreleme
- [ ] Çoklu dil desteği
- [ ] Dark mode
- [ ] Export/Import özelliği

## 📄 Lisans

Bu proje eğitim amaçlıdır.

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen bir issue açın veya pull request gönderin.

## 📞 İletişim

Sorularınız için lütfen bir issue açın.
