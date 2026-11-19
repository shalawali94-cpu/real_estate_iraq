-- Iraq geography seed (initial). Admins can edit/extend from the dashboard.
-- Districts follow common administrative usage; Akre/Shekhan listed under Duhok and
-- Makhmur under Erbil as administered by the KRG — staff can move them if needed.

insert into public.governorates (code, name_ckb, name_ar, name_en, sort_order) values
  ('ERB', 'هەولێر',     'أربيل',      'Erbil',         1),
  ('SUL', 'سلێمانی',    'السليمانية', 'Sulaymaniyah',  2),
  ('DUH', 'دهۆک',       'دهوك',       'Duhok',         3),
  ('HAL', 'هەڵەبجە',    'حلبجة',      'Halabja',       4),
  ('KRK', 'کەرکووک',    'كركوك',      'Kirkuk',        5),
  ('BGD', 'بەغدا',      'بغداد',      'Baghdad',       6),
  ('BAS', 'بەسرە',      'البصرة',     'Basra',         7),
  ('NIN', 'نەینەوا',    'نينوى',      'Nineveh',       8),
  ('ANB', 'ئەنبار',     'الأنبار',    'Anbar',         9),
  ('NAJ', 'نەجەف',      'النجف',      'Najaf',        10),
  ('KAR', 'کەربەلا',    'كربلاء',     'Karbala',      11),
  ('BAB', 'بابل',       'بابل',       'Babylon',      12),
  ('WAS', 'واست',       'واسط',       'Wasit',        13),
  ('DIY', 'دیالە',      'ديالى',      'Diyala',       14),
  ('SAL', 'سەلاحەدین',  'صلاح الدين', 'Salah al-Din', 15),
  ('DHQ', 'زیقار',      'ذي قار',     'Dhi Qar',      16),
  ('MAY', 'مەیسان',     'ميسان',      'Maysan',       17),
  ('MUT', 'موسەننا',    'المثنى',     'Muthanna',     18),
  ('QAD', 'قادسییە',    'القادسية',   'Qadisiyyah',   19);

insert into public.districts (governorate_id, name_ckb, name_ar, name_en)
select g.id, d.ckb, d.ar, d.en
from (values
  -- Erbil
  ('ERB','هەولێر','أربيل','Erbil'), ('ERB','شەقڵاوە','شقلاوة','Shaqlawa'), ('ERB','سۆران','سوران','Soran'),
  ('ERB','کۆیە','كويسنجق','Koya'), ('ERB','مێرگەسۆر','ميركه سور','Mergasur'), ('ERB','چۆمان','جومان','Choman'),
  ('ERB','خەبات','خبات','Khabat'), ('ERB','دەشتی هەولێر','دشت أربيل','Dashti Hawler'), ('ERB','ڕەواندز','راوندوز','Rawanduz'),
  ('ERB','مەخموور','مخمور','Makhmur'),
  -- Sulaymaniyah
  ('SUL','سلێمانی','السليمانية','Sulaymaniyah'), ('SUL','چەمچەماڵ','جمجمال','Chamchamal'), ('SUL','دەربەندیخان','دربندخان','Darbandikhan'),
  ('SUL','دووکان','دوكان','Dukan'), ('SUL','کەلار','كلار','Kalar'), ('SUL','کفری','كفري','Kifri'),
  ('SUL','ماوەت','ماوت','Mawat'), ('SUL','پێنجوێن','بنجوين','Penjwen'), ('SUL','پشدەر','بشدر','Pshdar'),
  ('SUL','ڕانیە','رانية','Rania'), ('SUL','شارباژێڕ','شاربازير','Sharbazher'), ('SUL','شارەزوور','شهرزور','Sharazur'),
  ('SUL','سەیدسادق','سيد صادق','Saidsadiq'), ('SUL','قەرەداغ','قرداغ','Qaradagh'),
  -- Duhok
  ('DUH','دهۆک','دهوك','Duhok'), ('DUH','زاخۆ','زاخو','Zakho'), ('DUH','ئامێدی','العمادية','Amedi'),
  ('DUH','سێمێل','سميل','Semel'), ('DUH','بەردەڕەش','بردرش','Bardarash'), ('DUH','ئاکرێ','عقرة','Akre'),
  ('DUH','شێخان','الشيخان','Shekhan'),
  -- Halabja
  ('HAL','هەڵەبجە','حلبجة','Halabja'), ('HAL','خورماڵ','خورمال','Khurmal'), ('HAL','بیارە','بيارة','Byara'),
  ('HAL','سیروان','سيروان','Sirwan'),
  -- Kirkuk
  ('KRK','کەرکووک','كركوك','Kirkuk'), ('KRK','حەویجە','الحويجة','Hawija'), ('KRK','دوبز','الدبس','Dibis'),
  ('KRK','داقووق','داقوق','Daquq'),
  -- Baghdad
  ('BGD','ڕەسافە','الرصافة','Rusafa'), ('BGD','ئەعزەمییە','الأعظمية','Adhamiyah'), ('BGD','شاری سەدر','مدينة الصدر','Sadr City'),
  ('BGD','کەرخ','الكرخ','Karkh'), ('BGD','کازمییە','الكاظمية','Kadhimiyah'), ('BGD','مەحمودییە','المحمودية','Mahmudiyah'),
  ('BGD','ئەبو غرێب','أبو غريب','Abu Ghraib'), ('BGD','تارمییە','الطارمية','Tarmiyah'), ('BGD','مەدائین','المدائن','Madain'),
  -- Basra
  ('BAS','بەسرە','البصرة','Basra'), ('BAS','ئەبولخەسیب','أبو الخصيب','Abu al-Khasib'), ('BAS','زوبەیر','الزبير','Zubair'),
  ('BAS','قورنە','القرنة','Qurna'), ('BAS','فاو','الفاو','Fao'), ('BAS','شەتولعەرەب','شط العرب','Shatt al-Arab'),
  ('BAS','مەدینە','المدينة','Al-Midaina'), ('BAS','دێر','الدير','Al-Dair'),
  -- Nineveh
  ('NIN','مووسڵ','الموصل','Mosul'), ('NIN','تەلەعفەر','تلعفر','Tel Afar'), ('NIN','شنگال','سنجار','Sinjar'),
  ('NIN','حەمدانییە','الحمدانية','Hamdaniya'), ('NIN','تەلکێف','تلكيف','Tel Kaif'), ('NIN','بەعاج','البعاج','Al-Baaj'),
  ('NIN','حەزەر','الحضر','Hatra'),
  -- Anbar
  ('ANB','ڕەمادی','الرمادي','Ramadi'), ('ANB','فەللووجە','الفلوجة','Fallujah'), ('ANB','هیت','هيت','Hit'),
  ('ANB','حەدیسە','حديثة','Haditha'), ('ANB','عانە','عانة','Anah'), ('ANB','ڕاوە','راوة','Rawah'),
  ('ANB','قائیم','القائم','Al-Qaim'), ('ANB','ڕوتبە','الرطبة','Rutba'), ('ANB','کەرمە','الكرمة','Al-Karmah'),
  -- Najaf
  ('NAJ','نەجەف','النجف','Najaf'), ('NAJ','کووفە','الكوفة','Kufa'), ('NAJ','مەناذیرە','المناذرة','Al-Manathera'),
  ('NAJ','مشخاب','المشخاب','Al-Mishkhab'),
  -- Karbala
  ('KAR','کەربەلا','كربلاء','Karbala'), ('KAR','هیندییە','الهندية','Al-Hindiya'), ('KAR','عەین تەمر','عين التمر','Ain al-Tamr'),
  -- Babylon
  ('BAB','حیللە','الحلة','Hillah'), ('BAB','مەحاویل','المحاويل','Al-Mahawil'), ('BAB','موسەییب','المسيب','Al-Musayyib'),
  ('BAB','هاشمییە','الهاشمية','Al-Hashimiya'),
  -- Wasit
  ('WAS','کووت','الكوت','Kut'), ('WAS','حەی','الحي','Al-Hai'), ('WAS','نوعمانییە','النعمانية','Al-Numaniyah'),
  ('WAS','سووەیرە','الصويرة','Al-Suwaira'), ('WAS','عەزیزییە','العزيزية','Al-Aziziyah'), ('WAS','بەدرە','بدرة','Badra'),
  -- Diyala
  ('DIY','بەعقووبە','بعقوبة','Baqubah'), ('DIY','موقدادییە','المقدادية','Al-Muqdadiya'), ('DIY','خالس','الخالص','Al-Khalis'),
  ('DIY','خانەقین','خانقين','Khanaqin'), ('DIY','بەلەدڕووز','بلدروز','Baladrooz'),
  -- Salah al-Din
  ('SAL','تکریت','تكريت','Tikrit'), ('SAL','سامەڕا','سامراء','Samarra'), ('SAL','بێجی','بيجي','Baiji'),
  ('SAL','بەلەد','بلد','Balad'), ('SAL','دوجەیل','الدجيل','Al-Dujail'), ('SAL','دووزخورماتوو','طوز خورماتو','Tuz Khurmatu'),
  ('SAL','دوور','الدور','Al-Daur'), ('SAL','شەرقات','الشرقاط','Al-Shirqat'),
  -- Dhi Qar
  ('DHQ','ناسرییە','الناصرية','Nasiriyah'), ('DHQ','ڕیفاعی','الرفاعي','Al-Rifai'), ('DHQ','شەترە','الشطرة','Al-Shatra'),
  ('DHQ','سووق ئەلشیوخ','سوق الشيوخ','Suq al-Shuyukh'), ('DHQ','چەبایش','الجبايش','Al-Chibayish'),
  -- Maysan
  ('MAY','عەمارە','العمارة','Amarah'), ('MAY','عەلی غەربی','علي الغربي','Ali al-Gharbi'), ('MAY','کەحلا','الكحلاء','Al-Kahla'),
  ('MAY','مەجەری گەورە','المجر الكبير','Al-Majar al-Kabir'), ('MAY','قەڵعەی ساڵح','قلعة صالح','Qalat Salih'),
  ('MAY','مەیمونە','الميمونة','Al-Maimouna'),
  -- Muthanna
  ('MUT','سەماوە','السماوة','Samawah'), ('MUT','ڕومەیسە','الرميثة','Al-Rumaitha'), ('MUT','خدر','الخضر','Al-Khidhr'),
  ('MUT','سەلمان','السلمان','Al-Salman'),
  -- Qadisiyyah
  ('QAD','دیوانییە','الديوانية','Diwaniyah'), ('QAD','عەفەک','عفك','Afak'), ('QAD','شامییە','الشامية','Al-Shamiya'),
  ('QAD','حەمزە','الحمزة','Al-Hamza')
) as d(gov, ckb, ar, en)
join public.governorates g on g.code = d.gov;

-- Initial neighborhoods (well-known areas only; more are added by users and staff).
insert into public.neighborhoods (district_id, name_original, original_locale, name_ckb, name_ar, name_en, status)
select dist.id, n.ckb, 'ckb', n.ckb, n.ar, n.en, 'approved'
from (values
  ('Erbil','عەنکاوە','عنكاوة','Ankawa'), ('Erbil','بەختیاری','بختياري','Bakhtiari'), ('Erbil','ئیسکان','الإسكان','Iskan'),
  ('Erbil','شۆڕش','شورش','Shorsh'), ('Erbil','برایەتی','برايتي','Brayati'), ('Erbil','ئازادی','آزادي','Azadi'),
  ('Erbil','مامۆستایان','ماموستايان','Mamostayan'), ('Erbil','تەیراوە','طيراوة','Tayrawa'), ('Erbil','کەسنەزان','كسنزان','Kasnazan'),
  ('Erbil','دریم سیتی','دريم سيتي','Dream City'), ('Erbil','گوندی ئیتاڵی','القرية الإيطالية','Italian Village'),
  ('Erbil','گوندی ئینگلیزی','القرية الإنكليزية','English Village'), ('Erbil','ئیمپایەر وۆرڵد','إمباير وورلد','Empire World'),
  ('Erbil','سێتاقان','سيتاقان','Setaqan'), ('Erbil','ڕزگاری','رزگاري','Rizgari'), ('Erbil','کوردستان','كوردستان','Kurdistan'),
  ('Sulaymaniyah','سەرچنار','سرچنار','Sarchnar'), ('Sulaymaniyah','بەکرەجۆ','بكرجو','Bakrajo'), ('Sulaymaniyah','ڕاپەڕین','رابرين','Raparin'),
  ('Sulaymaniyah','ئازادی','آزادي','Azadi'), ('Sulaymaniyah','گۆیژە','گويژة','Goizha'), ('Sulaymaniyah','تاسڵوجە','تاسلوجة','Tasluja'),
  ('Sulaymaniyah','مەلکەندی','ملكندي','Malkandi'), ('Sulaymaniyah','سابونکەران','صابونكران','Sabunkaran'),
  ('Sulaymaniyah','ئیبراهیم پاشا','إبراهيم باشا','Ibrahim Pasha'), ('Sulaymaniyah','هەواری شار','هواري شار','Hawari Shar'),
  ('Sulaymaniyah','قوڵەڕەیسی','قلەرەيسي','Qularaisi'), ('Sulaymaniyah','تووی مەلیک','توي مليك','Tuy Malik'),
  ('Sulaymaniyah','شۆڕش','شورش','Shorsh'), ('Sulaymaniyah','گوندی ئەڵمانی','القرية الألمانية','German Village'),
  ('Sulaymaniyah','ڕزگاری','رزگاري','Rizgari')
) as n(dist_en, ckb, ar, en)
join public.districts dist on dist.name_en = n.dist_en
join public.governorates g on g.id = dist.governorate_id
  and g.name_en = n.dist_en;  -- capital district of the same-named governorate
