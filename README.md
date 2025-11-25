# 📚 Kütüphane Yönetim Sistemi (Library Management System)

Modern ve kullanıcı dostu bir kütüphane yönetim sistemi. Flutter ile geliştirilmiş mobil uygulama ve ASP.NET Core ile backend API.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![.NET](https://img.shields.io/badge/.NET-512BD4?style=for-the-badge&logo=dotnet&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

## 📖 Proje Hakkında

Bu proje, kütüphane işlemlerini dijitalleştiren, kullanıcıların kitap kiralama, oturma yeri rezervasyonu yapabileceği ve yöneticilerin tüm işlemleri yönetebileceği tam kapsamlı bir sistemdir.

### 🎯 Temel Özellikler

#### 👤 Kullanıcı Özellikleri:
- ✅ Güvenli giriş ve kayıt sistemi (JWT Authentication)
- ✅ Kitap arama ve listeleme
- ✅ Kitap kiralama ve iade
- ✅ Oturma yeri rezervasyonu
- ✅ Kişisel istatistikler ve geçmiş görüntüleme
- ✅ Profil yönetimi
- ✅ Aktif kiralamalar ve rezervasyonlar takibi

#### 👨‍💼 Admin Özellikleri:
- ✅ Kullanıcı yönetimi (CRUD işlemleri)
- ✅ Kitap yönetimi (Envanter takibi)
- ✅ Kiralama yönetimi (Manuel iade, gecikme takibi)
- ✅ Rezervasyon yönetimi (İptal, durum takibi)
- ✅ Dashboard ile genel istatistikler
- ✅ Rol bazlı erişim kontrolü (Admin, User, Student, Librarian)
- ✅ Gelişmiş filtreleme ve arama

## 🛠️ Kullanılan Teknolojiler

### Frontend (Mobile App)
- **Framework:** Flutter 3.x
- **Dil:** Dart
- **UI:** Material Design 3
- **State Management:** StatefulWidget & setState
- **HTTP Client:** http package
- **Local Storage:** shared_preferences
- **Date Formatting:** intl package

### Backend (API)
- **Framework:** ASP.NET Core 8.0
- **Dil:** C#
- **ORM:** Entity Framework Core
- **Database:** PostgreSQL 16
- **Authentication:** JWT (JSON Web Tokens)
- **Password Hashing:** BCrypt.NET
- **API Documentation:** Swagger/OpenAPI

### Veritabanı Şeması
- Users (Kullanıcılar)
- Books (Kitaplar)
- BookRentals (Kitap Kiralamaları)
- Seats (Oturma Yerleri)
- SeatReservations (Oturma Yeri Rezervasyonları)

## 📁 Proje Yapısı

```
IOS-Library-Management-System/
├── backend/                          # ASP.NET Core API
│   ├── Controllers/                  # API Controllers
│   │   ├── AuthController.cs         # Giriş/Kayıt
│   │   ├── BooksController.cs        # Kitap işlemleri
│   │   ├── BookRentalsController.cs  # Kiralama işlemleri
│   │   ├── UsersController.cs        # Kullanıcı yönetimi
│   │   ├── SeatsController.cs        # Oturma yerleri
│   │   ├── SeatReservationsController.cs  # Rezervasyonlar
│   │   └── AdminController.cs        # Admin işlemleri
│   ├── Data/                         # Database Context
│   │   └── LibraryContext.cs
│   ├── Models/                       # Veri modelleri
│   │   ├── User.cs
│   │   ├── Book.cs
│   │   ├── BookRental.cs
│   │   ├── Seat.cs
│   │   └── SeatReservation.cs
│   ├── Program.cs                    # API yapılandırması
│   └── appsettings.json             # Konfigürasyon
│
├── lib/                              # Flutter App
│   ├── main.dart                     # Uygulama giriş noktası
│   ├── screens/                      # Ekranlar
│   │   ├── login_screen.dart         # Giriş ekranı
│   │   ├── register_screen.dart      # Kayıt ekranı
│   │   ├── dashboard_screen.dart     # Ana sayfa
│   │   ├── book_screen.dart          # Kitaplar
│   │   ├── seat_screen.dart          # Oturma yerleri
│   │   ├── profile_screen.dart       # Profil
│   │   ├── admin_dashboard_screen.dart      # Admin paneli
│   │   ├── admin_users_screen.dart          # Kullanıcı yönetimi
│   │   ├── admin_books_screen.dart          # Kitap yönetimi
│   │   ├── admin_rentals_screen.dart        # Kiralama yönetimi
│   │   └── admin_reservations_screen.dart   # Rezervasyon yönetimi
│   └── services/                     # API servisleri
│       └── user_service.dart
│
├── PRESENTATION_QA.md               # Sunum soru-cevapları
├── README.md                        # Bu dosya
└── pubspec.yaml                     # Flutter bağımlılıklar
```

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK (3.x veya üzeri)
- Dart SDK
- .NET 8.0 SDK
- PostgreSQL 16
- VS Code veya Android Studio

### 1️⃣ Veritabanı Kurulumu

```bash
# PostgreSQL'e bağlanın
psql -U postgres

# Veritabanı oluşturun
CREATE DATABASE library_management;
```

### 2️⃣ Backend Kurulumu

```bash
# Backend dizinine gidin
cd backend

# Bağımlılıkları yükleyin
dotnet restore

# Veritabanı migration'ları çalıştırın
dotnet ef database update

# Backend'i çalıştırın
dotnet run
```

Backend şu adreste çalışacak: `http://localhost:5038`

**Swagger UI**: `http://localhost:5038/swagger`

### 3️⃣ Flutter Uygulaması Kurulumu

```bash
# Ana dizinde
# Bağımlılıkları yükleyin
flutter pub get

# Uygulamayı çalıştırın
flutter run

# Web için
flutter run -d chrome

# Android için
flutter run -d android

# iOS için (macOS gerekli)
flutter run -d ios
```

## 🔐 Varsayılan Kullanıcılar

Sistem ilk kurulumda şu test kullanıcılarını oluşturur:

| Email | Şifre | Rol | Açıklama |
|-------|-------|-----|----------|
| admin@library.com | Admin123! | Admin | Tam yetki |
| user@library.com | User123! | User | Normal kullanıcı |
| student@library.com | Student123! | Student | Öğrenci |

## 📡 API Endpoint'leri

### 🔐 Authentication
```
POST   /api/Auth/login           # Giriş yap
POST   /api/Auth/register        # Kayıt ol
```

### 📚 Books
```
GET    /api/Books                # Tüm kitaplar
GET    /api/Books/{id}           # Tek kitap
GET    /api/Books/search?query=  # Kitap ara
POST   /api/Books                # Yeni kitap
PUT    /api/Books/{id}           # Kitap güncelle
DELETE /api/Books/{id}           # Kitap sil
```

### 📖 Book Rentals
```
GET    /api/BookRentals                    # Tüm kiralamalar
GET    /api/BookRentals/{id}               # Tek kiralama
GET    /api/BookRentals/user/{userId}      # Kullanıcı kiralamaları
POST   /api/BookRentals                    # Kitap kirala
PUT    /api/BookRentals/{id}/return        # Kitap iade
```

### 👥 Users
```
GET    /api/Users                # Tüm kullanıcılar
GET    /api/Users/{id}           # Tek kullanıcı
POST   /api/Users                # Kullanıcı oluştur
PUT    /api/Users/{id}           # Kullanıcı güncelle
DELETE /api/Users/{id}           # Kullanıcı sil
```

### 🪑 Seats
```
GET    /api/Seats                # Tüm koltuklar
GET    /api/Seats/{id}           # Tek koltuk
```

### 📅 Seat Reservations
```
GET    /api/SeatReservations                        # Tüm rezervasyonlar
GET    /api/SeatReservations/{id}                   # Tek rezervasyon
GET    /api/SeatReservations/user/{userId}          # Kullanıcı rezervasyonları
POST   /api/SeatReservations                        # Rezervasyon yap
DELETE /api/SeatReservations/{id}                   # Rezervasyon iptal
DELETE /api/SeatReservations/user/{userId}/history  # Geçmiş temizle
```

### ⚙️ Admin
```
GET    /api/Admin/stats                  # Dashboard istatistikleri
GET    /api/Admin/users/{userId}/stats   # Kullanıcı istatistikleri
```

## 🎨 Ekran Görüntüleri

### Login & Dashboard
| Login Screen | User Dashboard |
|--------------|----------------|
| *Giriş ekranı* | *Kullanıcı ana sayfası* |

### Admin Panel
| Admin Dashboard | User Management |
|----------------|-----------------|
| *Admin paneli* | *Kullanıcı yönetimi* |

### Books & Rentals
| Book List | Seat Reservation |
|-----------|------------------|
| *Kitap listesi* | *Oturma yeri rezervasyonu* |

> 📸 Ekran görüntülerini `screenshots/` klasörüne ekleyebilirsiniz

## 🎨 Tasarım Özellikleri

### UI/UX Highlights
- ✨ **Modern Gradient Tasarım** - Renk geçişli kartlar
- 🌈 **Material Design 3** - Google'ın en yeni tasarım dili
- 💫 **Smooth Animations** - Geçiş animasyonları
- 🎯 **Responsive Layout** - Tüm ekran boyutlarına uyumlu
- 🔄 **Pull to Refresh** - Aşağı çekerek yenileme
- 🎨 **Custom Widgets** - Yeniden kullanılabilir bileşenler
- 📊 **Data Tables** - Gelişmiş veri gösterimi
- 🔍 **Search & Filter** - Anlık arama ve filtreleme
- 💬 **SnackBar Notifications** - Kullanıcı bildirimleri
- 🎭 **Modal Dialogs** - CRUD işlemleri için popup'lar

### Renk Paleti
```dart
Primary: Colors.blue.shade700      // Ana renk
Secondary: Colors.purple.shade700  // Admin rengi
Success: Colors.green             // Başarılı işlemler
Warning: Colors.orange            // Uyarılar
Error: Colors.red                 // Hatalar
```

## 🔧 Geliştirme

### Hot Reload
```bash
# Uygulamada değişiklik yaptıktan sonra
# Terminal'de 'r' tuşuna basın
r

# Tam yeniden başlatma için
R
```

### Debug Mode
- VS Code Debug Console'da logları görün
- Flutter DevTools ile performance analizi
- `print()` ve `debugPrint()` kullanımı

### Code Quality
```bash
# Dart format
flutter format .

# Dart analyze
flutter analyze

# Tests
flutter test
```

## 🚀 Production Build

### Android APK
```bash
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Google Play için)
```bash
flutter build appbundle --release
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### iOS Build (macOS gerekli)
```bash
flutter build ios --release
# Xcode ile archive edin ve App Store'a gönderin
```

### Web Build
```bash
flutter build web --release
# Output: build/web/
```

## 🧪 Test

### Backend Tests
```bash
cd backend
dotnet test
```

### Flutter Tests
```bash
flutter test
```

### API Testing
- **Swagger UI**: http://localhost:5038/swagger
- **Postman**: Collection export edilebilir
- **curl** komutları ile manuel test

## 📝 Önemli Notlar

### Güvenlik
- ✅ Şifreler BCrypt ile hash'leniyor
- ✅ SQL Injection korumalı (EF Core)
- ✅ CORS yapılandırılmış
- ⚠️ Production'da HTTPS kullanın
- ⚠️ JWT secret key'i güvenli tutun
- ⚠️ Environment variables kullanın

### Best Practices
- ✅ RESTful API tasarımı
- ✅ Async/await pattern
- ✅ Error handling
- ✅ Input validation
- ✅ Clean code principles
- ✅ Responsive UI

## 🛣️ Roadmap / Gelecek Geliştirmeler

- [ ] 🔔 Push notifications (Firebase)
- [ ] 📱 Barcode/QR code scanner
- [ ] 📧 Email bildirimleri (gecikme, hatırlatma)
- [ ] 📊 Dashboard charts ve grafikler
- [ ] 🌍 Çoklu dil desteği (i18n)
- [ ] 🌙 Dark mode
- [ ] 📱 Offline mode (local database)
- [ ] 📸 Profil fotoğrafı yükleme
- [ ] 🔄 Real-time updates (SignalR)
- [ ] 📄 PDF rapor oluşturma
- [ ] 💳 Ödeme entegrasyonu (ceza bedelleri için)
- [ ] 📱 Widget tests ve integration tests

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/AmazingFeature`)
3. Commit edin (`git commit -m 'Add some AmazingFeature'`)
4. Push edin (`git push origin feature/AmazingFeature`)
5. Pull Request açın

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 👥 Geliştirici

**Doğukan Filiz**
- GitHub: [@dogukan-filiz](https://github.com/dogukan-filiz)
- Proje: [IOS-Library-Management-System](https://github.com/dogukan-filiz/IOS-Library-Management-System)

## 📞 İletişim

Sorularınız veya önerileriniz için issue açabilirsiniz.

## 🙏 Teşekkürler

- Flutter Team - Harika framework için
- Microsoft - .NET Core için
- PostgreSQL Team - Güçlü veritabanı için
- Material Design - Güzel UI bileşenleri için

---

⭐ Projeyi beğendiyseniz yıldız vermeyi unutmayın!

**Made with ❤️ and ☕**
