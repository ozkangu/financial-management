# Kişisel Finans Yönetim Uygulaması PRD

## 1. Genel Bakış

### 1.1 Ürün Adı
**FinansFlow** (geçici isim)

### 1.2 Vizyon
Kullanıcıların gelir, gider, yatırım ve pasif gelirlerini tek bir yerden yönetebileceği, aile/paydaşlarla işbirlikçi kullanım sağlayan kişisel finans platformu.

### 1.3 Hedef Kitle
- Bireysel kullanıcılar
- Çiftler/aileler
- Küçük hane halkları

---

## 2. Temel Özellikler

### 2.1 Kullanıcı Yönetimi ve İşbirliği
| Özellik | Açıklama |
|---------|----------|
| Kayıt/Giriş | Email, Google, Apple ile kimlik doğrulama |
| Hane Daveti | E-posta veya link ile eş/aileryi davet etme |
| Rol Yönetimi | Admin (düzenleme), Viewer (sadece görüntüleme) |
| Çoklu Hane | Farklı haneler oluşturabilme (örn: iş, ev) |

### 2.2 Gelir Yönetimi
| Özellik | Açıklama |
|---------|----------|
| Gelir Ekleme | Maaş, freelance, kira, dividen vs. |
| Döngüsel Gelir | Aylık, haftalık, yıllık tekrar eden |
| Tek Seferlik Gelir | Proje bazlı, ikramiye vs. |
| Kaynak Takibi | Hangi hesaptan/hangi şirketten |

### 2.3 Gider Yönetimi
| Özellik | Açıklama |
|---------|----------|
| Gider Ekleme | Manuel giriş |
| Kategori Sistemi | Özelleştirilebilir kategoriler |
| Alt Kategoriler | Market → Meyve/Sebze vs. |
| Tekrar Eden Giderler | Kira, abonelikler, faturalar |
| Etiketleme | #acil, #planlı, #iş vs. |

### 2.4 Öntanımlı Kategoriler
```
GİDER KATEGORİLERİ:
├── Konut
│   ├── Kira
│   ├── Elektrik
│   ├── Su
│   ├── Doğalgaz
│   └── İnternet
├── Ulaşım
│   ├── Yakıt
│   ├── Toplu Taşıma
│   └── Araç Bakım
├── Gıda
│   ├── Market
│   └── Restoran
├── Sağlık
├── Eğitim
├── Eğlence
├── Giyim
├── Kişisel Bakım
└── Diğer

GELİR KATEGORİLERİ:
├── Maaş
├── Freelance
├── Kira Geliri
├── Yatırım Geliri
│   ├── Dividen
│   ├── Faiz
│   └── Kâr Payı
├── Satış
└── Diğer
```

### 2.5 Yatırım Takibi
| Özellik | Açıklama |
|---------|----------|
| Varlık Türleri | Hisse, ETF, Kripto, Döviz, Altın, Gayrimenkul |
| Portföy Yönetimi | Varlıkların toplu görünümü |
| Alım/Satım Kaydı | İşlem geçmişi |
| Güncel Değer | Manuel veya API entegrasyonu ile |
| Pasif Gelir Takibi | Dividend, faiz, kira geliri |

### 2.6 Pasif Gelir Yönetimi
| Kaynak | Takip Edilenler |
|--------|-----------------|
| Hisse Senedi | Dividend (yıllık/çeyrek) |
| Vadeli Mevduat | Faiz geliri |
| Kripto | Staking ödülleri |
| Gayrimenkul | Kira geliri |
| Fon | Kâr payı dağıtımı |

---

## 3. Gösterge Paneli ve Raporlama

### 3.1 Dashboard Widget'ları
```
┌─────────────────────────────────────────────────────┐
│  NET VARLIK                    ₺XXX,XXX             │
├─────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐                 │
│  │ Bu Ay Gelir  │  │ Bu Ay Gider  │                 │
│  │   ₺XX,XXX    │  │   ₺XX,XXX    │                 │
│  └──────────────┘  └──────────────┘                 │
│                                                     │
│  NAKİT AKIŞI (Son 6 Ay)                             │
│  [═════════════════════════════] Grafik             │
│                                                     │
│  GIDER DAGILIMI          YATIRIM PORTFÖYÜ           │
│  [Pasta Grafik]          [Özet Kartlar]             │
│                                                     │
│  PASIF GELIRLER           YAKLASAN ÖDEME            │
│  ₺X,XXX/ay               • Kira - 3 gün             │
│                          • Elektrik - 5 gün         │
└─────────────────────────────────────────────────────┘
```

### 3.2 Finansal Akış Grafiği
- Aylık/Zaman bazlı nakit akışı
- Gelir vs Gider karşılaştırma
- Trend analizi
- Mevsimsel desenler

### 3.3 Raporlar
| Rapor Türü | İçerik |
|------------|--------|
| Aylık Özet | Gelir-gider dengesi, tasarruf oranı |
| Kategori Analizi | Hangi kategoriye ne kadar harcama |
| Yatırım Performansı | Getiri yüzdesi, pasif gelir toplamı |
| Net Varlık Tarihsel | Zaman içinde varlık değişimi |
| Bütçe vs Gerçekleşen | Hedeflenen vs yapılan harcama |

---

## 4. Net Varlık Hesaplama

```
NET VARLIK = TOPLAM VARLIKLAR - TOPLAM BORÇLAR

TOPLAM VARLIKLAR:
├── Nakit (Banka hesapları)
├── Yatırımlar (Hisse, kripto, fon vs. güncel değer)
├── Gayrimenkuller (tahmini piyasa değeri)
├── Diğer (altın, araç vs.)
└── Alacaklar (benden alacaklı olanlar)

TOPLAM BORÇLAR:
├── Kredi Kartı Borcu
├── Krediler (İhtiyaç, konut, araç)
├── Borçlar (Başkalarına olan)
└── Diğer Yükümlülükler
```

---

## 5. Teknik Gereksinimler

### 5.1 Platform Hedefleri
| Faz | Platform |
|-----|----------|
| MVP | Web (PWA) |
| Faz 2 | iOS + Android (React Native/Flutter) |
| Faz 3 | Desktop (Electron) |

### 5.2 Teknoloji Stack Önerileri
```
Frontend:  React/Next.js veya Vue/Nuxt
Backend:   Node.js (NestJS) veya Python (FastAPI)
Database:  PostgreSQL
Auth:      Firebase Auth veya Auth0
Hosting:   Vercel (frontend) + Railway/Render (backend)
```

### 5.3 Veri Modeli (Özet)
```
User ──┬── Household (Hane)
       │
Expense ── Category
       ── SubCategory
       ── User
       ── Household

Income ── Category
       ── User
       ── Household

Investment ── InvestmentType
           ── User
           ── PassiveIncome[]

Asset ── AssetType
      ── User

Liability ── User
```

---

## 6. Geliştirme Yol Haritası

### Faz 1 - MVP (4-6 Hafta)
- [ ] Kullanıcı kayıt/giriş
- [ ] Gelir/Gider CRUD
- [ ] Kategori yönetimi
- [ ] Temel dashboard
- [ ] Net varlık hesaplama

### Faz 2 - İşbirliği (2-3 Hafta)
- [ ] Hane oluşturma
- [ ] Davet sistemi
- [ ] Rol yönetimi
- [ ] Ortak veri görüntüleme

### Faz 3 - Yatırım (3-4 Hafta)
- [ ] Yatırım portföyü
- [ ] Pasif gelir takibi
- [ ] Portföy dashboard

### Faz 4 - Raporlama (2-3 Hafta)
- [ ] Detaylı grafikler
- [ ] Export (PDF/Excel)
- [ ] Bütçe planlama

### Faz 5 - Mobil (4-6 Hafta)
- [ ] React Native/Flutter uygulaması
- [ ] Push bildirimler
- [ ] Offline mod

---

## 7. Gelecek Özellikler (Nice-to-have)
- Banka entegrasyonu (özel API)
- OCR ile fiş okuma
- Bütçe hedefleri ve uyarılar
- Finansal hedefler (örn: "6 ayda X biriktir")
- Dövizli hesaplar
- Kripto fiyat API entegrasyonu
- AI destekli harcama analizi
