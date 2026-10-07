-- Synthetic fixtures only. No production employee, auth account or financial rows.
INSERT INTO public.tenants(slug,name,schema_name,reference_data)
VALUES('sample','지코바 치킨','tenant_sample','{"inventory":[],"recipes":[],"shelf_life":[],"recipe_categories":["치킨","사이드","음료"]}'),
('qa-isolation','격리 검증 프랜차이즈','tenant_qa','{"inventory":[],"recipes":[],"shelf_life":[],"recipe_categories":["검증 품목"]}')
ON CONFLICT(slug) DO NOTHING;
INSERT INTO tenant_sample.stores(name,code,source_store_key,region_group)
VALUES('샘플 강남점','SAMPLE-A','SAMPLE-A','서울'),('샘플 송파점','SAMPLE-B','SAMPLE-B','서울') ON CONFLICT(code) DO NOTHING;
INSERT INTO tenant_qa.stores(name,code,source_store_key,region_group)
VALUES('격리 검증점','ISOLATION','ISOLATION','검증') ON CONFLICT(code) DO NOTHING;
INSERT INTO tenant_sample.store_settings(id,store_id,open_minute,close_minute,close_grace_minutes)
SELECT id,id,420,1500,0 FROM tenant_sample.stores ON CONFLICT(id) DO NOTHING;
INSERT INTO tenant_qa.store_settings(id,store_id,open_minute,close_minute,close_grace_minutes)
SELECT id,id,420,1500,0 FROM tenant_qa.stores ON CONFLICT(id) DO NOTHING;
INSERT INTO tenant_sample.employees(name,store_id,pin_bcrypt,wage,memo)
SELECT '샘플 직원',s.id,extensions.crypt('2468',extensions.gen_salt('bf')),10320,'가상 샘플 데이터'
FROM tenant_sample.stores s WHERE NOT EXISTS(SELECT 1 FROM tenant_sample.employees e WHERE e.store_id=s.id AND e.name='샘플 직원');
INSERT INTO tenant_qa.employees(name,store_id,pin_bcrypt,wage,memo)
SELECT '격리 검증 직원',s.id,extensions.crypt('8642',extensions.gen_salt('bf')),10320,'자동 QA 전용 가상 데이터'
FROM tenant_qa.stores s WHERE NOT EXISTS(SELECT 1 FROM tenant_qa.employees e WHERE e.store_id=s.id AND e.name='격리 검증 직원');
