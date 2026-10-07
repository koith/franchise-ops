CREATE OR REPLACE FUNCTION __SCHEMA__.hq_store_dashboard()
RETURNS TABLE(store_id bigint,store_name text,store_code text,source_store_key text,region_group text,sales_total numeric,sales_7d numeric,tx_count bigint,trend jsonb,menu_trend jsonb)
LANGUAGE plpgsql SECURITY DEFINER SET search_path=__SCHEMA__,pg_temp AS $$
BEGIN
 IF NOT __SCHEMA__.is_hq_admin() THEN RAISE EXCEPTION 'NOT_AUTHORIZED'; END IF;
 RETURN QUERY
 SELECT s.id,s.name,s.code,s.source_store_key,s.region_group,
 coalesce(metrics.total,0),coalesce(metrics.recent,0),coalesce(metrics.n,0),coalesce(daily.rows,'[]'::jsonb),coalesce(menu.rows,'[]'::jsonb)
 FROM __SCHEMA__.stores s
 LEFT JOIN LATERAL (
  SELECT sum(t.total_amount)::numeric total,
  sum(t.total_amount) FILTER(WHERE t.business_date >= (now() AT TIME ZONE 'Asia/Seoul')::date-6)::numeric recent,count(*) n
  FROM __SCHEMA__.operations_transactions t WHERE t.source_store_key IN(s.source_store_key,'store-'||s.id) AND t.transaction_type='SALE' AND t.status='CONFIRMED'
 ) metrics ON true
 LEFT JOIN LATERAL (
  SELECT jsonb_agg(jsonb_build_object('date',d.business_date,'sales',d.sales) ORDER BY d.business_date) rows
  FROM(SELECT t.business_date,sum(t.total_amount)::numeric sales FROM __SCHEMA__.operations_transactions t
    WHERE t.source_store_key IN(s.source_store_key,'store-'||s.id) AND t.transaction_type='SALE' AND t.status='CONFIRMED' AND t.business_date >= (now() AT TIME ZONE 'Asia/Seoul')::date-13 GROUP BY t.business_date) d
 ) daily ON true
 LEFT JOIN LATERAL (
  SELECT jsonb_agg(jsonb_build_object('name',m.name,'sales',m.sales,'orders',m.orders,'channels',m.channels) ORDER BY m.sales DESC) rows
  FROM(SELECT c.name,sum(c.sales) sales,sum(c.orders) orders,jsonb_object_agg(c.channel,c.orders) channels
   FROM(SELECT coalesce(t.counterparty,'미분류') name,coalesce(t.channel,'미분류') channel,sum(t.total_amount)::numeric sales,count(*) orders
    FROM __SCHEMA__.operations_transactions t WHERE t.source_store_key IN(s.source_store_key,'store-'||s.id) AND t.transaction_type='SALE' AND t.status='CONFIRMED' AND t.business_date >= (now() AT TIME ZONE 'Asia/Seoul')::date-6 GROUP BY t.counterparty,t.channel) c GROUP BY c.name) m
 ) menu ON true
 WHERE s.is_active ORDER BY s.region_group,s.name;
END $$;
REVOKE ALL ON FUNCTION __SCHEMA__.hq_store_dashboard() FROM PUBLIC,anon,authenticated;
