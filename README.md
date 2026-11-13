# تعريب Split Fiction الكامل

تعريب كامل للعبة **Split Fiction**، مترجم من النص الإنجليزي الأصلي بفصحى بسيطة وطبيعية مثل الأفلام المدبلجة، ويناسب جو اللعبة وشخصياتها.

**بواسطة:** [Saad5400](https://github.com/Saad5400)

## ⚡ التثبيت التلقائي (الأسهل)
المثبّت يدوّر على اللعبة في جهازك وين ما كانت: **Steam** أو **EA app** أو **Epic Games** أو أي مجلد ثاني. بعدها يحمّل آخر نسخة من التعريب، ويتأكد إن الملف سليم، ويحطه في المكان الصحيح. وإذا لقى تعريب قديم يتعارض معه، ينقله لمجلد نسخة احتياطية.

### ويندوز
**الطريقة الأولى:** حمّل [`install.bat`](https://github.com/Saad5400/SplitFiction-Arabic/releases/latest/download/install.bat) وافتحه بدبل كليك.

**الطريقة الثانية:** افتح PowerShell والصق هذا الأمر:
```powershell
irm https://raw.githubusercontent.com/Saad5400/SplitFiction-Arabic/main/installer/install.ps1 | iex
```
إذا كانت اللعبة في مجلد يحتاج صلاحيات مسؤول، ويندوز بيطلب منك الموافقة.

### لينكس / Steam Deck
افتح الطرفية (في Steam Deck من وضع سطح المكتب: Konsole) والصق:
```bash
curl -fsSL https://raw.githubusercontent.com/Saad5400/SplitFiction-Arabic/main/installer/install.sh | bash
```
يدعم Steam (العادي وFlatpak) وHeroic، وأي مجلد ثاني عن طريق البحث.

### إزالة التعريب
- **ويندوز:** شغّل [`uninstall.bat`](https://github.com/Saad5400/SplitFiction-Arabic/releases/latest/download/uninstall.bat).
- **لينكس:** نفس أمر التثبيت، بس أضف في آخره `-s -- --uninstall`.

## التثبيت اليدوي
1. حمّل الملف `Saad5400_SplitFiction_Arabic_999_P.pak` من صفحة [آخر إصدار](../../releases/latest).
2. افتح مجلد اللعبة. من Steam: كليك يمين على اللعبة ← **Manage** ← **Browse local files**.
3. الصق الملف داخل المجلد `Split\Content\Paks`.

## بعد التثبيت
شغّل اللعبة وخلّ لغتها **English**. التعريب يركب مكان الإنجليزي، ويطلع اسم الخيار في الإعدادات: **العربية (تعريب Saad5400)**.

## وش يشمل التعريب
- الحوارات والمشاهد السينمائية، والترجمة أثناء اللعب.
- ترجمة المؤثرات الصوتية (Closed Captions).
- القوائم والإعدادات وأزرار التحكم والشروحات.
- أسماء الفصول والقصص الجانبية.
- شارة النهاية (المسميات الوظيفية، والأسماء تبقى زي ما هي).

أكثر من 13,300 نص. وراعيت فيها مين المتكلم ومين المخاطَب (ميو وزوي بصيغة المؤنث)، وحوّلت النكت والتلاعب بالألفاظ لنكت عربية بدل الترجمة الحرفية.

## ملاحظات
- إذا عندك تعريب قديم ثاني في مجلد `Paks`، الأفضل تحذفه. هذا التعريب ياخذ الأولوية عليه حتى لو بقي، والمثبّت التلقائي ينقله لك لمجلد احتياطي.
- التعريب مبني على نسخة اللعبة الحالية. إذا نزل تحديث وأضاف نصوص جديدة، النصوص الجديدة بتطلع بالإنجليزي لين يتحدث التعريب.
- إذا لقيت خطأ في الترجمة أو مشكلة في العرض، افتح [Issue](../../issues).

## الكود المصدري
| المسار | المحتوى |
|---|---|
| `translation/ar.json` | كل الترجمة. كل سطر فيه: `ns` و`key` (مكان النص في اللعبة)، و`hash` (بصمة النص الإنجليزي الأصلي)، و`ar` (الترجمة) |
| `docs/STYLE.md` | دليل الأسلوب والمصطلحات المعتمدة، مثل أسماء الشخصيات وأزرار التحكم والقوائم |
| `tools/build.js` | يبني ملف `Split.locres`، ومعه الخيار `--pack` يبني ملف الـ`.pak` كامل |
| `tools/check.js` | يقارن الترجمة بنصوص اللعبة الإنجليزية: الأسطر والمتغيرات، والنصوص اللي تغيّرت أو انضافت في التحديثات |
| `tools/locres.js` و`tools/cityhash.js` | قراءة وكتابة ملفات `.locres` حق Unreal Engine 5 |
| `installer/` | المثبّت التلقائي لويندوز ولينكس |

### طريقة البناء
تحتاج [Node.js](https://nodejs.org) و[repak](https://github.com/trumank/repak):
```bash
node tools/build.js                                  # يطلع build/Split.locres
node tools/build.js --pack --repak path/to/repak     # يطلع build/Saad5400_SplitFiction_Arabic_999_P.pak
```
ملفات الخطوط العربية ما هي موجودة في المستودع. أداة البناء تاخذها تلقائياً من آخر إصدار منشور، أو من ملف تحدده بـ`--base`.

### تعديل الترجمة
عدّل النص في `translation/ar.json`، ثم شغّل `node tools/check.js <ملف en/Split.locres من اللعبة>`، وبعدها ابنِ الملف.
تقدر تطلّع ملف الإنجليزي من اللعبة بهذا الأمر:
```bash
repak unpack -o english -i Split/Content/Localization/Split/en/Split.locres "<مجلد اللعبة>/Split/Content/Paks/pakchunk0-Windows.pak"
```

---
هذا تعريب من المعجبين وغير رسمي، ولا علاقة له بشركة Hazelight أو Electronic Arts. لازم تكون عندك نسخة أصلية من اللعبة.
