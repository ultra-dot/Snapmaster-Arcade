# Panduan Manual Setup Godot: Snapmaster Arcade (Phase 1)

Karena script kode (otak dari gamenya) sudah dibuat, sekarang kita hanya perlu membuat "wujud fisik" dari game ini di dalam Godot Engine. 

Ikuti langkah-langkah di bawah ini secara berurutan. Beri tanda centang kalau sudah selesai!

---

## 🟩 CHECKPOINT 1: Pengaturan Awal Project
Langkah ini untuk memastikan resolusi layar dan settingan dasar Godot sudah benar.

- [ ] **1. Buka Godot Project Settings:**
  Di menu paling atas, klik `Project` -> `Project Settings`.
- [ ] **2. Atur Resolusi Layar:**
  Di menu sebelah kiri, scroll ke bawah cari menu `Display`, lalu klik `Window`.
  - Di bagian **Size**, ubah `Viewport Width` menjadi `1280` dan `Viewport Height` menjadi `720`.
  - Di bagian **Stretch**, ubah `Mode` menjadi `canvas_items` dan `Aspect` menjadi `keep`.
- [ ] **3. Pasang Autoload (Globals):**
  Masih di jendela Project Settings, lihat deretan tab di paling atas, klik tab **Globals** (berada di antara Localization dan Plugins).
  - Klik ikon folder (📁) di samping kolom *Path*.
  - Cari dan pilih file `res://scripts/InputManager.gd`, lalu klik *Open*.
  - Pastikan kolom *Node Name* terisi teks **InputManager**.
  - Klik tombol **Add** di sebelah kanannya. (Nama InputManager akan muncul di list bawah).
- [ ] **4. Tambah Input Klik:**
  Masih di Project Settings, pindah ke tab **Input Map** (di sebelah tab General).
  - Di kotak *Add New Action*, ketik kata `click` (huruf kecil semua), lalu tekan Enter / klik tombol Add.
  - Cari tulisan `click` yang baru kamu buat di list bawah, klik tombol **+** di sebelah kanannya.
  - Klik kiri di mana saja pakai mouse kamu (nanti muncul tulisan *Left Mouse Button*). Klik **OK**.
  - Tutup jendela Project Settings (klik tombol Close di bawah).

---

## 🟩 CHECKPOINT 2: Membuat Bebek (Duck.tscn)
Kita akan membuat cetakan objek Bebek yang bisa bergerak.

- [ ] **1. Buat Scene Baru:**
  Di menu atas, klik `Scene` -> `New Scene`.
- [ ] **2. Tambah Root Node Area2D:**
  Di sebelah kiri (panel Scene), klik **Other Node**. Ketik `Area2D` di kolom pencarian, pilih `Area2D` lalu klik Create.
- [ ] **3. Ganti Nama Node:**
  Klik kanan pada tulisan `Area2D`, pilih `Rename` (atau tekan F2). Ganti namanya jadi `Duck`.
- [ ] **4. Masukkan Script:**
  Di panel bawah sebelah kiri (FileSystem), buka folder `scripts`. Drag-and-drop (tarik) file `Duck.gd` ke tulisan node `Duck` di panel Scene. Nanti akan muncul ikon kertas script di sebelah tulisan Duck.
- [ ] **5. Tambah Komponen (Child Nodes):**
  Klik KANAN pada node `Duck`, pilih **Add Child Node** (atau tekan Ctrl+A). Lakukan ini 3 kali untuk menambahkan 3 node berikut:
  - Cari dan tambah node: `AnimatedSprite2D`
  - Cari dan tambah node: `CollisionShape2D`
  - Cari dan tambah node: `VisibleOnScreenNotifier2D`
- [ ] **6. Pasang Animasi Bebek:**
  Klik node `AnimatedSprite2D`. Di sebelah KANAN (panel Inspector), pada bagian `Sprite Frames`, klik kotak `<empty>` lalu pilih `New SpriteFrames`. 
  - Klik tulisan `SpriteFrames` yang baru muncul itu. Nanti panel animasi akan terbuka di bagian paling bawah layar Godot.
  - Di panel bawah itu, kamu bisa narik (drag-and-drop) gambar-gambar *spritesheet* atau kumpulan gambar bebek (frame per frame) lu ke kotak animasinya. Pastikan nama animasinya `default` dan centang opsi **Autoplay** (ikon tombol Play kecil) biar bebeknya selalu ngepak sayap.
- [ ] **7. Pasang Area Tabrakan:**
  Klik node `CollisionShape2D`. Di panel Inspector (kanan), pada bagian `Shape`, klik tulisan `<empty>` lalu pilih `New RectangleShape2D`. 
  - (Opsional) Kamu bisa klik tulisan RectangleShape2D itu untuk mengatur ukurannya agar pas menutupi gambar.
- [ ] **8. Connect Signal Layar:**
  Klik node `VisibleOnScreenNotifier2D`. Di sebelah KANAN, klik tab **Signals** (di sebelahnya Inspector).
  - Cari tulisan `screen_exited()`, klik DUA KALI (Double-click).
  - Akan muncul jendela popup. Pastikan yang tersorot biru adalah `Duck`, lalu klik tombol **Connect** di bawah.
- [ ] **9. Save Scene:**
  Tekan `Ctrl+S` (Save). Masuk ke folder `Scenes`, lalu save dengan nama `Duck.tscn`. Tutup tab Duck di bagian atas layar.

---

## 🟩 CHECKPOINT 3: Membuat Kamera (CameraFrame.tscn)
Kita akan membuat kotak pembidik (crosshair).

- [ ] **1. Buat Scene Baru:**
  Klik `Scene` -> `New Scene`.
- [ ] **2. Tambah Root Node Area2D:**
  Sama seperti bebek, klik **Other Node**, pilih `Area2D`. Ganti namanya jadi `CameraFrame`.
- [ ] **3. Masukkan Script:**
  Tarik file `CameraFrame.gd` dari folder `scripts` ke node `CameraFrame`.
- [ ] **4. Tambah Komponen:**
  Klik kanan pada `CameraFrame`, pilih **Add Child Node**, tambahkan:
  - `Sprite2D` (Kasih gambar `icon.svg` seperti tadi, lalu di Inspector bagian `Transform -> Scale` ubah x dan y jadi 0.5 biar kecil).
  - `CollisionShape2D` (Kasih `RectangleShape2D` juga, atur ukurannya seukuran kotak bidikan yang kamu mau).
- [ ] **5. Save Scene:**
  Tekan `Ctrl+S`. Masuk ke folder `Scenes`, save dengan nama `CameraFrame.tscn`. Tutup tab CameraFrame.

---

## 🟩 CHECKPOINT 4: Menggabungkan Semua (Main.tscn)
Ini adalah level atau ruangan utama di mana gamenya dimainkan.

- [ ] **1. Buat Scene Baru:**
  Klik `Scene` -> `New Scene`.
- [ ] **2. Pilih Tipe 2D Scene:**
  Klik tombol **2D Scene**. (Otomatis akan membuat node bernama `Node2D`).
- [ ] **3. Ganti Nama dan Masukkan Script:**
  Ganti namanya jadi `Main`. Tarik file `GameManager.gd` dari folder `scripts` ke node `Main` ini.
- [ ] **4. Setup Parameter GameManager:**
  Klik node `Main`. Di panel Inspector (kanan), lihat bagian paling atas (Script Variables). Ada kolom **Duck Scene**. 
  - Tarik file `Duck.tscn` dari folder `Scenes` (di FileSystem kiri) ke kotak `<empty>` di Duck Scene tersebut.
- [ ] **5. Bikin Struktur Node:**
  Klik kanan pada node `Main`, tambahkan **Child Node** berikut ini SATU-SATU:
  - `Sprite2D` (Ganti namanya jadi `BackgroundLayer`. Kasih gambar bebas untuk background di Inspector).
  - `Node2D` (Ganti namanya jadi `DuckSpawner`).
  - `Timer` (Ganti namanya jadi `SpawnTimer`. Di Inspector kanan, centang kotak **Autostart**).
  - `CanvasLayer` (Ganti namanya jadi `HUD`).
- [ ] **6. Bikin Teks UI (Dalam HUD):**
  Klik kanan pada node `HUD`, tambahkan **Child Node** `Label`. Ganti namanya jadi `ScoreLabel`. Geser teksnya di layar ke pojok kiri atas.
  - Lakukan hal yang sama: klik kanan `HUD`, tambah `Label`, ganti nama jadi `LivesLabel`. Geser teksnya ke pojok kanan atas.
- [ ] **7. Masukkan CameraFrame:**
  Di panel FileSystem (kiri), buka folder `Scenes`. **Tarik** file `CameraFrame.tscn` ke tengah-tengah layar game kamu. (Otomatis dia akan jadi anak dari node `Main`).
- [ ] **8. Save Scene:**
  Tekan `Ctrl+S`. Masuk ke folder `Scenes`, save dengan nama `Main.tscn`.

---

## 🟩 CHECKPOINT 5: Test Main!
- [ ] **1. Set Main Scene:**
  Di menu atas, klik `Project` -> `Project Settings` -> tab `General`. Di kiri pilih `Application` -> `Run`.
  - Di bagian `Main Scene`, klik folder, pilih `res://Scenes/Main.tscn`. Tutup jendela setting.
- [ ] **2. Play Game:**
  Tekan **F5** di keyboard kamu.

*Selamat! Game kamu harusnya sudah berjalan. Ada target yang lewat, dan kotak ngikutin mouse kamu.*
