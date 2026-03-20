# PRD: Personal and Shared Finance Management App

## 1. Product Summary

Bu ürün, bireysel veya aile kullanımına uygun bir finans yönetimi uygulamasıdır. Kullanıcı kendi finansal hayatını tek başına yönetebilir; isterse eşini veya başka bir aile üyesini/davetli kullanıcıyı sisteme dahil ederek ortak görünüm oluşturabilir.

Uygulamanın temel amacı:

- Gelir ve giderleri düzenli takip etmek
- Aylık nakit akışını görmek
- Kategorilere göre finansal davranışı analiz etmek
- Yatırımları ve bunlardan doğan pasif gelirleri izlemek
- Toplam net varlığı tek ekranda göstermek

Bu ürün, klasik bir muhasebe aracı değil; daha çok günlük finansal farkındalık, ortak bütçe yönetimi ve uzun vadeli varlık takibi odaklı olacaktır.

## 2. Problem Statement

Kullanıcılar genellikle gelir, gider, yatırım ve birikim verilerini farklı yerlerde tutar:

- Banka hareketleri ayrı yerde
- Aylık giderler not uygulamalarında veya Excel'de
- Yatırımlar farklı platformlarda
- Eşle ortak gider takibi mesajlaşma uygulamalarında

Bu da şu sorunlara yol açar:

- Gerçek aylık nakit akışı net görülemez
- Hangi kategoride fazla harcama yapıldığı anlaşılmaz
- Yatırımların toplam portföye ve pasif gelire etkisi izlenemez
- Ortak bütçede kimin ne girdiği ve toplam tablo net olmaz
- Toplam net varlık düzenli takip edilemez

## 3. Product Vision

Kullanıcının tüm kişisel ve ortak finansal durumunu tek bir üründe görebildiği, sade ama güçlü bir finans yönetimi merkezi oluşturmak.

## 4. Target Users

### Primary Users

- Kendi bütçesini düzenli takip etmek isteyen bireyler
- Eşiyle veya partneriyle ortak finans yöneten kullanıcılar
- Gelir, gider ve yatırımını aynı sistemde görmek isteyen kullanıcılar

### Secondary Users

- Aile bütçesine katkı veren diğer bireyler
- Sadece veri girişi yapacak davetli kullanıcılar
- Finansal danışman gibi salt okunur erişim ihtiyacı olabilecek kullanıcılar

## 5. Goals

### Business / Product Goals

- Kullanıcının finansal durumunu tek ekranda özetleyebilmek
- Ortak kullanım senaryosunu güçlü şekilde desteklemek
- Manuel girişle başlanıp ileride banka entegrasyonu için uygun zemin hazırlamak
- Yatırım ve pasif gelir takibini temel bütçe takibiyle birleştirmek

### User Goals

- Aylık ne kadar kazandığını ve harcadığını görmek
- Harcamalarını kategori bazında analiz etmek
- Gelecek ay bütçesini geçmiş veriye göre planlamak
- Yatırımlarının toplam değerini takip etmek
- Pasif gelirlerinin aylık etkisini görmek
- Toplam net varlığını zaman içinde izlemek

## 6. Non-Goals for MVP

İlk sürümde aşağıdakiler kapsam dışıdır:

- Otomatik banka entegrasyonları
- Vergi hesaplama ve resmi muhasebe özellikleri
- Gelişmiş yatırım analitiği (risk skoru, teknik analiz, canlı piyasa verisi)
- Fatura ödeme altyapısı
- Çoklu ülke mevzuatı ve lokal vergi desteği
- Kurumsal muhasebe/ERP özellikleri

## 7. Core Use Cases

1. Kullanıcı aylık maaş, freelance gelir veya diğer gelir kalemlerini ekler.
2. Kullanıcı market, kira, ulaşım, sağlık gibi giderleri kategori bazlı girer.
3. Kullanıcı eşiyle ortak bir alan oluşturur ve ikisi de gider/gider katkısı girebilir.
4. Kullanıcı belirli bir ay için toplam gelir, toplam gider ve kalan bakiyeyi görür.
5. Kullanıcı kategori bazında hangi alanda ne kadar harcadığını analiz eder.
6. Kullanıcı yatırım hesaplarını veya varlıklarını manuel olarak ekler.
7. Kullanıcı yatırım kaynaklı pasif gelirleri (temettü, faiz, kira, staking vb.) kaydeder.
8. Kullanıcı tüm nakit, yatırım ve borç bilgilerini bir arada görerek net varlığını takip eder.
9. Kullanıcı zaman içinde finansal gidişatı grafiklerle izler.

## 8. User Roles and Permissions

### 8.1 Owner

- Workspace oluşturur
- Kullanıcı davet eder
- Tüm finansal verileri görebilir
- Kategorileri ve genel ayarları yönetir
- Ortak görünüm ve erişim izinlerini belirler

### 8.2 Member

- Gelir/gider/yatırım kaydı ekleyebilir
- Yetkisine göre mevcut kayıtları görüntüleyebilir
- Ortak alan içindeki kendi veya paylaşılan verileri düzenleyebilir

### 8.3 Viewer (Optional in MVP+1)

- Sadece görüntüleme yapar
- Veri ekleyemez veya düzenleyemez

## 9. Feature Requirements

## 9.1 Authentication and Onboarding

### Requirements

- Kullanıcı e-posta ile kayıt olabilir ve giriş yapabilir.
- Kullanıcı tek başına kişisel workspace oluşturabilir.
- Kullanıcı yeni bir ortak workspace oluşturabilir veya mevcut bir workspace'e davet alabilir.
- Davet linki veya e-posta daveti ile başka kullanıcı eklenebilir.

### Acceptance Criteria

- Yeni kullanıcı 5 dakikadan kısa sürede ilk workspace'ini oluşturabilmeli.
- Davet edilen kullanıcı ilgili workspace'e sorunsuz katılabilmeli.

## 9.2 Workspace Structure

### Requirements

- Sistem "workspace" mantığıyla çalışmalıdır.
- Bir workspace tek kişi veya birden fazla kişi içerebilir.
- Her kayıt, bir workspace altında tutulmalıdır.
- Kayıt seviyesinde "kişisel", "ortak" veya "belirli kullanıcıya ait" işaretleme desteklenmelidir.

### Why

Bu yapı, hem tek kullanıcı hem de eşle ortak kullanım senaryosunu aynı ürün içinde çözmek için gereklidir.

## 9.3 Income Tracking

### Requirements

- Kullanıcı gelir kaydı ekleyebilmelidir.
- Gelir alanları:
  - tutar
  - tarih
  - kategori
  - açıklama
  - tekrar tipi (tek seferlik / aylık / haftalık / yıllık)
  - sahibi (hangi kullanıcıya ait)
  - ortak mı kişisel mi bilgisi
- Gelir kategorileri özelleştirilebilir olmalıdır.
- Düzenli gelirler gelecek aylara projekte edilebilmelidir.

### Example Categories

- Maaş
- Serbest çalışma
- Kira geliri
- Temettü
- Faiz
- Diğer

## 9.4 Expense Tracking

### Requirements

- Kullanıcı gider kaydı ekleyebilmelidir.
- Gider alanları:
  - tutar
  - tarih
  - kategori
  - açıklama
  - ödeme yöntemi
  - sahibi
  - ortak mı kişisel mi bilgisi
  - tekrar tipi
- Kategori bazlı filtreleme yapılabilmelidir.
- Aylık toplam giderler görülebilmelidir.
- Sabit giderler ayrı işaretlenebilmelidir.

### Example Categories

- Kira
- Market
- Ulaşım
- Faturalar
- Sağlık
- Eğitim
- Eğlence
- Yeme içme
- Çocuk
- Ev
- Abonelikler

## 9.5 Cash Flow Dashboard

### Requirements

- Kullanıcı seçilen ay için aşağıdaki bilgileri görebilmelidir:
  - toplam gelir
  - toplam gider
  - net nakit akışı
  - geçen aya göre değişim
- Dashboard aylık bazda varsayılan açılmalıdır.
- Kullanıcı tarih aralığı seçebilmelidir.
- Grafik veya özet kartlarla trend sunulmalıdır.

### Core Formula

Net nakit akışı = toplam gelir - toplam gider

## 9.6 Category-Based Analytics

### Requirements

- Kullanıcı gelir ve giderleri kategori bazlı kırılımda görebilmelidir.
- Belirli kategori için zaman içindeki değişim izlenebilmelidir.
- Kullanıcı filtre uygulayabilmelidir:
  - tarih aralığı
  - kullanıcı
  - ortak/kişisel
  - kategori
- En yüksek harcama yapılan kategoriler listelenmelidir.

## 9.7 Investment Tracking

### Requirements

- Kullanıcı yatırım varlığı ekleyebilmelidir.
- Desteklenecek yatırım tipleri:
  - nakit
  - altın
  - döviz
  - hisse senedi
  - fon
  - kripto
  - mevduat
  - bireysel emeklilik
  - gayrimenkul
  - diğer
- Yatırım alanları:
  - varlık adı
  - varlık tipi
  - adet/miktar
  - birim maliyet
  - güncel değer (MVP'de manuel)
  - para birimi
  - platform/kurum
  - not
  - sahibi

### MVP Constraint

Canlı fiyat entegrasyonu ilk sürümde zorunlu değildir. Kullanıcı manuel güncelleme yapabilir.

## 9.8 Passive Income Tracking

### Requirements

- Kullanıcı yatırım kaynaklı pasif gelir ekleyebilmelidir.
- Pasif gelir tipleri:
  - temettü
  - faiz
  - kira
  - staking
  - kupon geliri
  - diğer
- Pasif gelirler aylık toplam içinde ayrı gösterilmelidir.
- Kullanıcı toplam gelir içinde pasif gelir oranını görebilmelidir.

### Core Formula

Pasif gelir oranı = toplam pasif gelir / toplam gelir

## 9.9 Net Worth Tracking

### Requirements

- Kullanıcı toplam varlıklarını ve borçlarını girebilmelidir.
- Net varlık ekranı aşağıdaki kırılımı göstermelidir:
  - toplam nakit
  - toplam yatırım değeri
  - toplam diğer varlıklar
  - toplam borçlar
  - net varlık
- Zaman içindeki değişim grafikle sunulmalıdır.

### Core Formula

Net varlık = toplam varlıklar - toplam borçlar

## 9.10 Liabilities / Debt Tracking

### Requirements

- Kullanıcı borç kayıtları ekleyebilmelidir.
- Borç tipleri:
  - kredi kartı
  - ihtiyaç kredisi
  - konut kredisi
  - araç kredisi
  - şahsi borç
  - diğer
- Borç alanları:
  - toplam borç
  - kalan borç
  - aylık ödeme
  - faiz oranı (opsiyonel)
  - son ödeme tarihi

## 9.11 Reports and Views

### Requirements

- Kullanıcı aşağıdaki ekranları görmelidir:
  - genel özet
  - aylık nakit akışı
  - kategori analizi
  - yatırım portföyü
  - pasif gelir özeti
  - net varlık geçmişi
- Kullanıcı CSV dışa aktarma yapabilmelidir (MVP+1 olabilir).

## 10. Functional Requirements Summary

- FR-1: Kullanıcı kayıt olabilir ve giriş yapabilir.
- FR-2: Kullanıcı kişisel veya ortak workspace oluşturabilir.
- FR-3: Kullanıcı başka bir kullanıcıyı davet edebilir.
- FR-4: Gelir kaydı ekleme, düzenleme, silme yapılabilir.
- FR-5: Gider kaydı ekleme, düzenleme, silme yapılabilir.
- FR-6: Gelir ve giderler kategorilerle ilişkilendirilebilir.
- FR-7: Aylık gelir-gider özeti gösterilir.
- FR-8: Kategori bazlı analiz gösterilir.
- FR-9: Yatırım varlıkları manuel girilebilir.
- FR-10: Pasif gelirler ayrı takip edilir.
- FR-11: Borçlar girilebilir ve net varlık hesabına dahil edilir.
- FR-12: Toplam net varlık zaman serisi olarak gösterilir.
- FR-13: Her kayıt kullanıcıya ve workspace'e bağlanır.
- FR-14: Ortak ve kişisel görünüm aynı sistem içinde filtrelenebilir.

## 11. Non-Functional Requirements

- Uygulama mobil öncelikli çalışmalıdır.
- Web uygulaması olarak başlanmalı; mobil uygulamaya genişleyebilir olmalıdır.
- Veri giriş akışı hızlı olmalıdır.
- Kritik dashboard ekranları 2 saniye altında açılmalıdır.
- Finansal veriler güvenli şekilde saklanmalıdır.
- Yetkilendirme kayıt bazında doğru uygulanmalıdır.
- Audit trail ihtiyacı MVP+1 için düşünülmelidir.

## 12. UX Principles

- İlk girişte kullanıcıyı yormayan sade onboarding
- Hızlı veri girişi
- "Bu ay durumum ne?" sorusuna tek ekranda cevap
- Ortak kullanımda kafa karıştırmayan sahiplik modeli
- Grafikler anlaşılır olmalı, süslü ama belirsiz olmamalı

## 13. Suggested Information Architecture

### Main Navigation

- Dashboard
- Gelirler
- Giderler
- Kategoriler
- Yatırımlar
- Pasif Gelirler
- Borçlar
- Net Varlık
- Ayarlar

### Key Screens

#### Dashboard

- Bu ay toplam gelir
- Bu ay toplam gider
- Net nakit akışı
- Son 6 ay trendi
- En çok harcanan kategoriler
- Pasif gelir özeti
- Net varlık özeti

#### Income List

- Filtrelenebilir gelir listesi
- Yeni gelir ekleme

#### Expense List

- Filtrelenebilir gider listesi
- Yeni gider ekleme

#### Investments

- Portföy listesi
- Varlık detay ekranı
- Manuel değer güncelleme

#### Net Worth

- Varlıklar
- Borçlar
- Net varlık grafiği

## 14. Data Model Draft

### Main Entities

- User
  - id
  - name
  - email
- Workspace
  - id
  - name
  - owner_id
- WorkspaceMember
  - id
  - workspace_id
  - user_id
  - role
- Category
  - id
  - workspace_id
  - type (income / expense / passive_income)
  - name
- Transaction
  - id
  - workspace_id
  - user_id
  - type (income / expense)
  - category_id
  - amount
  - currency
  - date
  - recurrence_rule
  - visibility_scope
  - note
- InvestmentAsset
  - id
  - workspace_id
  - user_id
  - asset_type
  - name
  - quantity
  - unit_cost
  - current_unit_price
  - currency
  - institution
- PassiveIncome
  - id
  - workspace_id
  - user_id
  - investment_asset_id (optional)
  - category_id
  - amount
  - date
- Liability
  - id
  - workspace_id
  - user_id
  - liability_type
  - total_amount
  - remaining_amount
  - monthly_payment
  - due_date
- NetWorthSnapshot
  - id
  - workspace_id
  - date
  - total_assets
  - total_liabilities
  - net_worth

## 15. MVP Scope

MVP aşağıdaki kapsamla çıkmalıdır:

- Kullanıcı kaydı ve giriş
- Tekil veya ortak workspace oluşturma
- Davet ile ikinci kullanıcı ekleme
- Gelir ekleme ve listeleme
- Gider ekleme ve listeleme
- Kategori yönetimi
- Aylık dashboard
- Kategori bazlı analiz
- Yatırım varlığı ekleme
- Pasif gelir kaydı
- Borç ekleme
- Net varlık ekranı

## 16. Post-MVP Roadmap

### Phase 2

- CSV içe/dışa aktarma
- Tekrarlayan kayıtların otomatik oluşması
- Bildirimler ve bütçe uyarıları
- Çoklu para birimi dönüşümü
- Salt okunur kullanıcı rolü

### Phase 3

- Banka ve finans kurumu entegrasyonları
- Otomatik işlem kategorileme
- Yatırım fiyat entegrasyonları
- Gelişmiş raporlama
- Hedef bazlı birikim planları

## 17. Success Metrics

### Product Metrics

- İlk hafta içinde ilk gelir veya gider kaydı oluşturan kullanıcı oranı
- İlk 30 günde en az 3 farklı günde uygulamayı kullanan kullanıcı oranı
- Workspace başına davet edilen kullanıcı sayısı
- Aylık aktif kullanıcı oranı

### Value Metrics

- Kullanıcı başına aylık ortalama kayıt sayısı
- En az bir yatırım ekleyen kullanıcı oranı
- Net varlık ekranını görüntüleyen kullanıcı oranı
- Pasif gelir kaydı oluşturan kullanıcı oranı

## 18. Risks and Open Questions

- Ortak ve kişisel finans görünümü hangi seviyede ayrılmalı?
- Eşler birbirinin tüm kayıtlarını varsayılan olarak görmeli mi?
- Çoklu para birimi MVP'ye alınmalı mı, yoksa tek para birimiyle mi başlanmalı?
- Net varlık snapshot'ı sistem tarafından mı üretilecek, yoksa her hesaplamada anlık mı çıkarılacak?
- Yatırım varlıklarında gerçekleşmiş/getirisel kazanç ayrı gösterilmeli mi?
- Pasif gelir, genel gelirden ayrı bir modül mü olmalı, yoksa gelir alt tipi olarak mı tutulmalı?

## 19. Recommended Product Decisions

Başlangıç için aşağıdaki kararlar önerilir:

- İlk sürüm web tabanlı yapılmalı
- Mobil responsive tasarım zorunlu olmalı
- Manuel veri girişiyle başlanmalı
- Tek para birimi varsayılan kabul edilmeli, veri modeli çoklu para birimine açık tasarlanmalı
- Owner ve Member rolleri MVP için yeterli olmalı
- Ortak ve kişisel kayıt görünümü filtre ile yönetilmeli

## 20. Suggested MVP Tech Direction

Bu bölüm bağlayıcı teknik tasarım değildir; uygulamaya geçiş için öneri niteliğindedir.

- Frontend: Next.js
- Backend: Next.js API routes veya ayrı backend
- Database: PostgreSQL
- Auth: Supabase Auth / Auth.js / Clerk benzeri çözüm
- Charts: basit ve okunabilir grafik kütüphanesi
- Hosting: Vercel + managed database

## 21. Launch Definition

MVP, aşağıdaki durumlarda yayına hazır kabul edilir:

- Tek kullanıcı akışı sorunsuz çalışıyor
- Workspace daveti ile ikinci kullanıcı eklenebiliyor
- Gelir/gider CRUD tamam
- Dashboard aylık özetleri doğru hesaplıyor
- Yatırım, pasif gelir ve borç kayıtları net varlık hesabına dahil ediliyor
- Temel filtreleme ve kategori analizi çalışıyor
- Mobil ve masaüstü kullanımda temel akışlar stabil

## 22. Next Step Recommendation

Bu PRD'den sonra önerilen sıradaki adımlar:

1. User flow ve wireframe hazırlama
2. Veri modeli ve teknik mimariyi netleştirme
3. MVP backlog çıkarma
4. Tasarım sistemi ve ilk ekranların uygulanması
