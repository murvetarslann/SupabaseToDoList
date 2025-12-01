# SupabaseToDoList
Bu proje, kullanıcıların not almasını, notlarını önceliklendirmesini ve profil yönetimi yapabilmesini sağlayan bir uygulamadır.

## Özellikler

### 1. Not Önceliklendirme
Her not için bir öncelik seviyesi belirlenebilir. Bu sayede kullanıcı hangi notlarının daha acil veya önemli olduğunu görsel olarak ayırt edebilir.  

**Öncelik seviyeleri:**
- **Önemli:** Önemli ama biraz ertelenebilir notlar (kırmızı ikon)  
- **Normal:** Standart notlar (turuncu ikon)  
- **Düşük:** Acil olmayan, zamanı olunca bakılabilecek notlar (beyaz ikon)  

Not listesinde her notun yanında öncelik seviyesini gösteren renkli bir ikon bulunur. Böylece kullanıcı liste üzerinde hızlıca hangi notların daha önemli olduğunu görebilir.  
Not oluştururken öncelik seçilmezse otomatik olarak **"Normal"** atanır.

### 2. Not Sabitleme
Kullanıcı, sürekli erişmek istediği önemli notları sabitleyebilir. Sabitlenen notlar liste görünümünde her zaman en üstte yer alır.  

- Not üzerinde bir raptiye/pin ikonu bulunur. Bu ikona tıklandığında not sabitlenir ve listenin en üstüne taşınır.  
- Tekrar tıklandığında sabitleme kaldırılır ve not normal sıralamasına geri döner.  
- Birden fazla not sabitlendiğinde, sabitlenen notlar kendi aralarında oluşturulma tarihine göre sıralanır.

### 3. Profil Yönetimi
Uygulamada bir profil sayfası bulunur. Bu sayfada kullanıcı kendi hesap bilgilerini görüntüleyebilir ve güncelleyebilir.  

**Görüntülenebilir ve düzenlenebilir bilgiler:**
- **Ad Soyad:** Kullanıcının tam adı  
- **Email Adresi:** Kayıt sırasında kullanılan ve hatırlatıcı maillerinin gönderileceği adres  
- **Profil Fotoğrafı:** Kullanıcı galerisinden veya kameradan fotoğraf seçip yükleyebilir  
- **Hesap Oluşturma Tarihi:** Uygulamayı kullanmaya başladığı tarih (sadece görüntüleme)  

Kullanıcı profil sayfasından adını-soyadını değiştirebilir, yeni bir profil fotoğrafı yükleyebilir.  
Profil fotoğrafı yüklendiğinde, uygulama içinde notlar ekranının üst kısmında veya menüde kullanıcının profil fotoğrafı görünür.
