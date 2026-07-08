# EduBuddy — Play Store Listing (Full, copy-paste ready)

> Updated: July 2026 — matches app v1.0.0+1 (30-level Memory Match, cartoon video scenes)

---

## 1. Store Listing

### App name (30 chars max)
```
EduBuddy - Learning for Kids
```

### Short description (80 chars max)
```
Fun quizzes, stories, videos & games for kids to learn animals, math & more!
```

### Full description — English
```
EduBuddy is a colorful, safe learning app for kids aged 4–12 that makes learning feel like play!

🦁 QUIZZES — Fun questions with beautiful animal illustrations
🧠 MEMORY MATCH — 30 levels across 6 worlds: animals, fruits, ocean, vehicles, food & space
📚 STORYBOOKS — Illustrated stories in English & Bahasa Malaysia
🎬 VIDEOS — Animated lessons on animals, numbers, colors, science & space
🎨 CREATIVE — Coloring, tracing (A–Z, 0–9), drawing & counting games
✏️ WORKSHEETS — English, Math and more

⭐ SAFE & AD-FREE
• No ads, no in-app purchases, no tracking
• Works 100% offline — all progress stays on your device
• Bilingual: English & Bahasa Malaysia

Download EduBuddy and make learning an adventure! 🌟
```

### Full description — Bahasa Malaysia (for MS locale listing)
```
EduBuddy ialah aplikasi pembelajaran berwarna-warni dan selamat untuk kanak-kanak 4–12 tahun — belajar sambil bermain!

🦁 KUIZ — Soalan menyeronokkan dengan ilustrasi haiwan yang cantik
🧠 MEMORY MATCH — 30 tahap merentasi 6 dunia: haiwan, buah, lautan, kenderaan, makanan & angkasa
📚 BUKU CERITA — Cerita bergambar dalam BI & BM
🎬 VIDEO — Pelajaran animasi: haiwan, nombor, warna, sains & angkasa
🎨 KREATIF — Mewarna, menyurih (A–Z, 0–9), melukis & mengira
✏️ LEMBARAN KERJA — Bahasa Inggeris, Matematik & lagi

⭐ SELAMAT & TANPA IKLAN
• Tiada iklan, tiada pembelian dalam apl, tiada penjejakan
• 100% offline — semua kemajuan kekal di peranti anda
• Dwibahasa: Bahasa Inggeris & Bahasa Malaysia

Muat turun EduBuddy dan jadikan pembelajaran satu pengembaraan! 🌟
```

---

## 2. Graphics (files in this folder)

| Slot | File | Spec |
|------|------|------|
| App icon | `icon_512.png` | 512×512 PNG ✅ |
| Feature graphic | `feature_graphic.png` | 1024×500 PNG ✅ |
| Phone screenshots | `screenshots_9x16/*.png` (10 files) | 1475×2622, exact 9:16 ✅ |

⚠️ Use the `screenshots_9x16/` folder — the originals in `screenshots/` are 1:2.17 ratio and will be REJECTED by Play Console.

---

## 3. Categorization & Contact

- **App or game:** App
- **Category:** Education
- **Tags:** Education, Educational games, Kids
- **Email:** zaitulakmal02@gmail.com  *(or support@edubuddy.my if that inbox is real — must be reachable)*
- **Phone / Website:** optional

---

## 4. App Content section — exact answers

### Privacy policy
```
https://zaitulakmal.github.io/EduBuddy/privacy-policy.html
```

### App access
- **All functionality is available without special access** ✅ (no login)

### Ads
- **No, my app does not contain ads** ✅
- ⚠️ Change this to YES the day you wire AdMob in — never before.

### Content rating (IARC questionnaire)
- Email: your contact email
- Category: **Utility, Productivity, Communication, or Other** → then answer:
  - Violence: **No**
  - Sexuality: **No**
  - Language: **No**
  - Controlled substances: **No**
  - Gambling themes / real gambling: **No**
  - Location sharing: **No**
  - Personal info sharing: **No**
  - Digital purchases: **No**
  - User interaction/UGC: **No**
- Expected result: **Rated for 3+ / Everyone**

### Target audience and content
- Target age groups: **5 and under, 6–8, 9–12** (select all three)
- "Could your app unintentionally appeal to children?" — irrelevant since target IS children
- **Ads declaration inside this section: No ads**
- This puts the app under the **Families Policy** — reviews take longer (3–7 days), that's normal.

### Data safety
- Does your app collect or share any of the required user data types? → **No**
- Is all of the user data collected by your app encrypted in transit? → N/A (auto-skipped)
- Do you provide a way for users to request that their data is deleted? → N/A
- Result shown on listing: **"No data collected, No data shared"**

### Other declarations
- News app: **No**
- COVID-19 contact tracing/status: **No**
- Government app: **No**
- Financial features: **None of the above**
- Health features: **None / My app does not have health features**

---

## 5. Release

- **Track:** Internal testing first (recommended), then Production
- **File:** `build/app/outputs/bundle/release/app-release.aab`
- **Release name:** `1.0.0 (1)` (auto-filled)

### Release notes (copy-paste)
```
<en-US>
🎉 First release of EduBuddy!
• Animal quizzes with hand-drawn illustrations
• 30-level Memory Match across 6 themed worlds
• Animated educational videos with cartoon scenes
• Interactive storybooks in English & Bahasa Malaysia
• Coloring, tracing, drawing & counting activities
• 100% offline, ad-free and safe for kids
</en-US>
```

---

## 6. Post-launch reminders

1. **Keystore backup:** copy `android/app/edubuddy-release.jks` + `android/key.properties` somewhere safe (cloud drive). Lose it = can never update the app.
2. **When adding ads later**, update ALL of: privacy policy page, this listing ("Ad-Free" claims), Ads declaration, Families ads certification (use only certified ad SDKs).
3. Next release: bump `version:` in pubspec.yaml (e.g. `1.0.1+2`).
