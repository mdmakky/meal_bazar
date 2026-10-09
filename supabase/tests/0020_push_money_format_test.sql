-- push_money: Indian grouping, paisa only when present, Bangla digits.
select test.check(push_money(1500, false) = '৳1,500', '1,500');
select test.check(push_money(60, false) = '৳60', 'no grouping under 1000');
select test.check(push_money(1250.5, false) = '৳1,250.50', 'paisa shown as two digits');
select test.check(push_money(123456.78, false) = '৳1,23,456.78', 'lakh grouping');
select test.check(push_money(10000000, false) = '৳1,00,00,000', 'crore grouping');
select test.check(push_money(1500, true) = '৳১,৫০০', 'Bangla digits');
select test.check(push_money(-40, false) = '৳-40', 'negative');
