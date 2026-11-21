-- Map centering: plain lat/lng on governorates and districts (district falls back to governorate).
alter table public.governorates add column if not exists center_lat double precision, add column if not exists center_lng double precision;
alter table public.districts add column if not exists center_lat double precision, add column if not exists center_lng double precision;

update public.governorates g set center_lat = v.lat, center_lng = v.lng
from (values
 ('ERB',36.1912,44.0092),('SUL',35.5558,45.4351),('DUH',36.8679,42.9885),('HAL',35.1778,45.9861),
 ('KRK',35.4681,44.3922),('BGD',33.3152,44.3661),('BAS',30.5085,47.7835),('NIN',36.3400,43.1300),
 ('ANB',33.4258,43.3010),('NAJ',32.0000,44.3300),('KAR',32.6160,44.0249),('BAB',32.4637,44.4196),
 ('WAS',32.5128,45.8182),('DIY',33.7500,44.6500),('SAL',34.6100,43.6800),('DHQ',31.0580,46.2570),
 ('MAY',31.8356,47.1440),('MUT',31.3100,45.2800),('QAD',31.9900,44.9250)
) as v(code, lat, lng) where g.code = v.code;

update public.districts d set center_lat = v.lat, center_lng = v.lng
from public.governorates g, (values
 ('ERB','Erbil',36.1912,44.0092),('ERB','Shaqlawa',36.4040,44.3170),('ERB','Soran',36.6540,44.5380),
 ('ERB','Koya',36.0830,44.6270),('ERB','Makhmur',35.7740,43.5800),
 ('SUL','Sulaymaniyah',35.5558,45.4351),('SUL','Chamchamal',35.5300,44.8300),('SUL','Dukan',35.9500,44.9500),
 ('SUL','Kalar',34.6250,45.3200),('SUL','Penjwen',35.6170,45.9570),('SUL','Rania',36.2550,44.8800),
 ('DUH','Duhok',36.8679,42.9885),('DUH','Zakho',37.1440,42.6870),('DUH','Amedi',37.0920,43.4870),
 ('DUH','Akre',36.7440,43.8890),('DUH','Shekhan',36.7080,43.3150),
 ('HAL','Halabja',35.1778,45.9861),
 ('KRK','Kirkuk',35.4681,44.3922),('KRK','Hawija',35.3200,43.7800),
 ('BAS','Basra',30.5085,47.7835),('BAS','Zubair',30.3900,47.7100),('BAS','Fao',29.9800,48.4800),
 ('NIN','Mosul',36.3400,43.1300),('NIN','Tel Afar',36.3700,42.4500),('NIN','Sinjar',36.3200,41.8700),
 ('ANB','Ramadi',33.4258,43.3010),('ANB','Fallujah',33.3500,43.7800),
 ('NAJ','Najaf',32.0000,44.3300),('NAJ','Kufa',32.0300,44.4000),
 ('KAR','Karbala',32.6160,44.0249),('BAB','Hillah',32.4637,44.4196),
 ('WAS','Kut',32.5128,45.8182),('DIY','Baqubah',33.7500,44.6500),
 ('SAL','Tikrit',34.6100,43.6800),('SAL','Samarra',34.1980,43.8740),
 ('DHQ','Nasiriyah',31.0580,46.2570),('MAY','Amarah',31.8356,47.1440),
 ('MUT','Samawah',31.3100,45.2800),('QAD','Diwaniyah',31.9900,44.9250)
) as v(code, en, lat, lng)
where d.governorate_id = g.id and g.code = v.code and d.name_en = v.en;
