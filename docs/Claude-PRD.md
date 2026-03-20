# PRD: Kişisel Finans Yönetim Uygulaması

**Versiyon:** 1.0
**Tarih:** 2026-03-20
**Durum:** Taslak

---

## 1. Genel Bakış

Kişisel ve aile bazlı finansal yönetimi kolaylaştıran bir web uygulaması. Kullanıcılar gelir/gider takibi, yatırım yönetimi, pasif gelir izleme ve toplam net varlık görüntüleme işlemlerini kategori bazlı olarak yapabilir. Aile üyeleri veya ortaklar davet edilerek ortak finansal yönetim sağlanır.

---

## 2. Hedef Kullanıcılar

- **Birincil:** Kişisel finansını aktif yöneten bireyler
- **İkincil:** Ortak bütçe yöneten çiftler/aileler
- **Üçüncül:** Yatırımlarını ve pasif gelirlerini takip etmek isteyen bireysel yatırımcılar

---

## 3. Temel Özellikler

### 3.1 Kullanıcı Yönetimi & Çoklu Kullanıcı

| Özellik | Açıklama |
|---------|----------|
| Kayıt/Giriş | E-posta + şifre ile hesap oluşturma ve giriş |
| Profil | Ad, avatar, para birimi tercihi |
| Davet sistemi | E-posta ile eş/aile üyesi/ortak davet etme |
| Roller | **Sahip** (tam yetki), **Üye** (ekleme/görüntüleme), **Görüntüleyici** (sadece okuma) |
| Ortak çalışma alanı | Davet edilen kişilerle aynı finansal verileri görme ve yönetme |

### 3.2 Gelir Yönetimi

| Özellik | Açıklama |
|---------|----------|
| Gelir ekleme | Tutar, tarih, kategori, açıklama, tekrarlama durumu |
| Gelir kategorileri | Maaş, Serbest Çalışma, Kira Geliri, Pasif Gelir, Hediye, Diğer (özelleştirilebilir) |
| Tekrarlayan gelir | Aylık/haftalık/yıllık otomatik tekrarlama tanımı |
| Gelir geçmişi | Filtrelenebilir ve aranabilir gelir listesi |

### 3.3 Gider Yönetimi

| Özellik | Açıklama |
|---------|----------|
| Gider ekleme | Tutar, tarih, kategori, alt kategori, açıklama, tekrarlama durumu |
| Gider kategorileri | Konut, Ulaşım, Market, Yemek, Sağlık, Eğitim, Eğlence, Giyim, Faturalar, Abonelikler, Diğer (özelleştirilebilir) |
| Tekrarlayan gider | Kira, abonelik gibi düzenli giderlerin otomatik tanımı |
| Gider geçmişi | Filtrelenebilir ve aranabilir gider listesi |

### 3.4 Kategori Yönetimi

| Özellik | Açıklama |
|---------|----------|
| Varsayılan kategoriler | Sistem tarafından sunulan hazır kategori seti |
| Özel kategori | Kullanıcının kendi kategorilerini oluşturabilmesi |
| Alt kategoriler | Her ana kategorinin altında alt kategori tanımı (ör: Konut > Kira, Konut > Aidat) |
| Renk & ikon | Her kategoriye renk ve ikon atama |
| Kategori bazlı bütçe | Her kategoriye aylık bütçe limiti belirleme |

### 3.5 Yatırım Takibi

| Özellik | Açıklama |
|---------|----------|
| Yatırım ekleme | Yatırım adı, türü, alış tarihi, alış fiyatı, miktar, mevcut değer |
| Yatırım türleri | Hisse Senedi, Fon, Altın, Döviz, Kripto, Gayrimenkul, Mevduat, Tahvil/Bono, Diğer |
| Manuel değer güncelleme | Kullanıcının güncel değeri manuel girmesi |
| Kar/Zarar hesaplama | Alış fiyatı vs güncel değer karşılaştırması |
| Pasif gelir tanımı | Her yatırıma bağlı pasif gelir girişi (temettü, kira, faiz vb.) |
| Pasif gelir takvimi | Pasif gelirlerin ne zaman geldiğini gösteren takvim/liste |
| Yatırım özeti | Toplam yatırım değeri, toplam kar/zarar, yatırım dağılımı |

### 3.6 Finansal Akış (Dashboard)

| Özellik | Açıklama |
|---------|----------|
| Aylık özet | Seçilen ayın toplam gelir, gider, net durumu |
| Gelir vs Gider grafiği | Aylık karşılaştırmalı bar/çizgi grafik |
| Kategori bazlı dağılım | Pasta grafik ile gelir ve giderlerin kategori dağılımı |
| Trend analizi | Son 6-12 aylık gelir/gider trendi |
| Nakit akışı | Aylık bazda paranın nereden gelip nereye gittiğini gösteren akış |
| Bütçe performansı | Kategori bazlı harcama vs bütçe karşılaştırması |

### 3.7 Net Varlık (Net Worth)

| Özellik | Açıklama |
|---------|----------|
| Varlık tanımlama | Banka hesapları, nakit, yatırımlar, gayrimenkul, araç vb. |
| Borç tanımlama | Kredi kartı borcu, bireysel kredi, ipotek vb. |
| Net varlık hesaplama | Toplam Varlıklar - Toplam Borçlar = Net Varlık |
| Net varlık trendi | Aylık bazda net varlık değişim grafiği |
| Varlık dağılımı | Varlıkların türlerine göre dağılım grafiği |

---

## 4. Ekranlar

### 4.1 Dashboard (Ana Sayfa)
- Aylık gelir/gider özet kartları
- Bu ayın net durumu (gelir - gider)
- Gelir vs gider karşılaştırma grafiği
- Kategori bazlı harcama dağılımı (pasta grafik)
- Son işlemler listesi (son 10 gelir/gider)
- Net varlık özet kartı
- Pasif gelir özet kartı

### 4.2 Gelirler Sayfası
- Gelir ekleme formu
- Gelir listesi (filtreleme: tarih aralığı, kategori, tutar)
- Aylık gelir özet tablosu

### 4.3 Giderler Sayfası
- Gider ekleme formu
- Gider listesi (filtreleme: tarih aralığı, kategori, tutar)
- Aylık gider özet tablosu
- Bütçe vs gerçekleşen karşılaştırması

### 4.4 Yatırımlar Sayfası
- Yatırım ekleme/düzenleme formu
- Yatırım portföy listesi (tür, alış, güncel, kar/zarar)
- Yatırım dağılım grafiği
- Pasif gelir listesi ve takvimi
- Toplam portföy değeri ve toplam kar/zarar

### 4.5 Net Varlık Sayfası
- Varlık ekleme/düzenleme
- Borç ekleme/düzenleme
- Net varlık = Varlıklar - Borçlar görünümü
- Net varlık trend grafiği (aylık)
- Varlık dağılım grafiği

### 4.6 Kategoriler Sayfası
- Gelir/gider kategorileri yönetimi
- Alt kategori ekleme/düzenleme
- Renk ve ikon seçimi
- Kategori bazlı bütçe belirleme

### 4.7 Raporlar Sayfası
- Tarih aralığına göre gelir/gider raporu
- Kategori bazlı detaylı analiz
- Aylık karşılaştırma raporu
- Yıllık özet raporu

### 4.8 Ayarlar Sayfası
- Profil düzenleme
- Kullanıcı davet etme / yönetme
- Para birimi ayarı (TRY, USD, EUR vb.)
- Bildirim tercihleri
- Veri dışa aktarma (CSV/PDF)

---

## 5. Veri Modeli

### Users
```
id, email, password_hash, name, avatar_url, currency, created_at
```

### Workspaces
```
id, name, owner_id, created_at
```

### Workspace Members
```
id, workspace_id, user_id, role (owner/member/viewer), invited_at, accepted_at
```

### Categories
```
id, workspace_id, name, type (income/expense), parent_id (alt kategori için),
color, icon, monthly_budget, is_default, created_at
```

### Transactions
```
id, workspace_id, user_id, type (income/expense), category_id,
amount, currency, date, description, is_recurring,
recurrence_interval (monthly/weekly/yearly), created_at
```

### Investments
```
id, workspace_id, user_id, name, type (stock/fund/gold/crypto/real_estate/deposit/bond/other),
purchase_date, purchase_price, quantity, current_value, currency,
notes, created_at, updated_at
```

### Passive Incomes
```
id, investment_id, workspace_id, amount, currency,
frequency (monthly/quarterly/yearly), next_payment_date,
description, created_at
```

### Assets
```
id, workspace_id, name, type (bank_account/cash/investment/real_estate/vehicle/other),
value, currency, notes, created_at, updated_at
```

### Debts
```
id, workspace_id, name, type (credit_card/personal_loan/mortgage/other),
total_amount, remaining_amount, interest_rate, monthly_payment,
currency, due_date, notes, created_at, updated_at
```

---

## 6. Teknik Mimari (Önerilen)

### Frontend
- **Framework:** Next.js 14+ (App Router)
- **UI Kütüphanesi:** Tailwind CSS + shadcn/ui
- **Grafikler:** Recharts veya Chart.js
- **State Management:** Zustand veya React Context
- **Form Yönetimi:** React Hook Form + Zod (validasyon)

### Backend
- **Runtime:** Next.js API Routes (full-stack)
- **ORM:** Prisma veya Drizzle ORM
- **Veritabanı:** PostgreSQL (Supabase veya Neon)
- **Authentication:** NextAuth.js (Auth.js)
- **E-posta:** Resend (davet e-postaları için)

### Deployment
- **Platform:** Vercel
- **Veritabanı:** Supabase / Neon / PlanetScale
- **Dosya Depolama:** Gerekirse Cloudflare R2 veya S3

---

## 7. MVP Kapsamı (Faz 1)

İlk sürümde yer alacak minimum özellikler:

1. Kullanıcı kayıt/giriş
2. Gelir ekleme/listeleme (kategori bazlı)
3. Gider ekleme/listeleme (kategori bazlı)
4. Varsayılan kategoriler + özel kategori oluşturma
5. Dashboard: aylık özet, gelir vs gider grafiği, kategori dağılımı
6. Basit yatırım takibi (ekleme, güncel değer, kar/zarar)
7. Net varlık hesaplama (varlıklar - borçlar)
8. Kullanıcı davet etme (ortak çalışma alanı)

## 8. Gelecek Fazlar

### Faz 2
- Tekrarlayan gelir/gider otomasyonu
- Pasif gelir takibi ve takvimi
- Bütçe limitleri ve uyarılar
- Detaylı raporlar ve dışa aktarma

### Faz 3
- Bildirimler (bütçe aşımı, yaklaşan ödemeler)
- Otomatik yatırım fiyat güncelleme (API entegrasyonu)
- Mobil uyumlu PWA
- Çoklu para birimi desteği ve dönüşüm

### Faz 4
- Hedef belirleme (birikim hedefi, borç ödeme planı)
- Finansal sağlık skoru
- AI bazlı harcama önerileri
- Banka entegrasyonu (açık bankacılık API)

---

## 9. Başarı Kriterleri

- Kullanıcı 2 dakika içinde ilk gelir/gider kaydını girebilmeli
- Dashboard yüklenme süresi < 2 saniye
- Eş/ortak davet süreci 3 adımda tamamlanabilmeli
- Tüm finansal verilerin tutarlılığı ve doğruluğu sağlanmalı
- Mobil cihazlarda sorunsuz kullanılabilmeli (responsive)

---

## 10. Güvenlik Gereksinimleri

- Tüm veriler HTTPS üzerinden iletilmeli
- Şifreler bcrypt/argon2 ile hash'lenmeli
- Workspace bazlı yetkilendirme (bir kullanıcı başkasının verisine erişememeli)
- Rate limiting (brute-force koruması)
- CSRF ve XSS koruması
- Düzenli veri yedekleme
