CREATE OR REPLACE FUNCTION tenant_template.admin_inventory_purchase_receive(p_order_id bigint, p_quantity numeric)
 RETURNS tenant_template.inventory_purchase_orders
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_template', 'pg_temp'
AS $function$
declare r tenant_template.inventory_purchase_orders; v_remaining numeric; v_stock_qty numeric; v_updated bigint;
begin
 select * into r from tenant_template.inventory_purchase_orders where id=p_order_id for update;
 if r.id is null then raise exception 'ORDER_NOT_FOUND'; end if;
 if not tenant_template.can_manage_store(r.store_id) then raise exception 'NOT_AUTHORIZED'; end if;
 if r.status not in ('ORDERED','PARTIAL') then raise exception 'ORDER_NOT_RECEIVABLE'; end if;
 v_remaining:=r.ordered_quantity-r.received_quantity;
 if coalesce(p_quantity,0)<=0 or p_quantity>v_remaining then raise exception 'INVALID_RECEIVE_QUANTITY'; end if;
 v_stock_qty:=p_quantity*coalesce(r.conversion_quantity,1);
 if r.manual_item_id is not null then
   update tenant_template.inventory_manual_items set on_hand=on_hand+v_stock_qty,updated_at=now()
   where id=r.manual_item_id and store_id=r.store_id returning id into v_updated;
   if v_updated is null then raise exception 'INVENTORY_ITEM_NOT_FOUND'; end if;
 else
   if not exists(select 1 from tenant_template.inventory_items where id=r.item_id) then raise exception 'INVENTORY_ITEM_NOT_FOUND'; end if;
   insert into tenant_template.inventory_movements(store_id,item_id,business_date,movement_type,quantity,source_type,source_key,note)
   values(r.store_id,r.item_id,(now() at time zone 'Asia/Seoul')::date,'RECEIPT',v_stock_qty,'PURCHASE_ORDER',r.id::text,
          '발주 입고 '||p_quantity||' '||coalesce(r.order_unit,r.unit)||case when coalesce(r.conversion_quantity,1)<>1 then ' → '||v_stock_qty||' '||coalesce(r.stock_unit,r.unit) else '' end);
 end if;
 update tenant_template.inventory_purchase_orders
 set received_quantity=received_quantity+p_quantity,
     status=case when received_quantity+p_quantity>=ordered_quantity then 'RECEIVED' else 'PARTIAL' end,
     received_at=case when received_quantity+p_quantity>=ordered_quantity then now() else received_at end,
     updated_at=now()
 where id=r.id returning * into r;
 return r;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_sample.admin_inventory_purchase_receive(p_order_id bigint, p_quantity numeric)
 RETURNS tenant_sample.inventory_purchase_orders
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_sample', 'pg_temp'
AS $function$
declare r tenant_sample.inventory_purchase_orders; v_remaining numeric; v_stock_qty numeric; v_updated bigint;
begin
 select * into r from tenant_sample.inventory_purchase_orders where id=p_order_id for update;
 if r.id is null then raise exception 'ORDER_NOT_FOUND'; end if;
 if not tenant_sample.can_manage_store(r.store_id) then raise exception 'NOT_AUTHORIZED'; end if;
 if r.status not in ('ORDERED','PARTIAL') then raise exception 'ORDER_NOT_RECEIVABLE'; end if;
 v_remaining:=r.ordered_quantity-r.received_quantity;
 if coalesce(p_quantity,0)<=0 or p_quantity>v_remaining then raise exception 'INVALID_RECEIVE_QUANTITY'; end if;
 v_stock_qty:=p_quantity*coalesce(r.conversion_quantity,1);
 if r.manual_item_id is not null then
   update tenant_sample.inventory_manual_items set on_hand=on_hand+v_stock_qty,updated_at=now()
   where id=r.manual_item_id and store_id=r.store_id returning id into v_updated;
   if v_updated is null then raise exception 'INVENTORY_ITEM_NOT_FOUND'; end if;
 else
   if not exists(select 1 from tenant_sample.inventory_items where id=r.item_id) then raise exception 'INVENTORY_ITEM_NOT_FOUND'; end if;
   insert into tenant_sample.inventory_movements(store_id,item_id,business_date,movement_type,quantity,source_type,source_key,note)
   values(r.store_id,r.item_id,(now() at time zone 'Asia/Seoul')::date,'RECEIPT',v_stock_qty,'PURCHASE_ORDER',r.id::text,
          '발주 입고 '||p_quantity||' '||coalesce(r.order_unit,r.unit)||case when coalesce(r.conversion_quantity,1)<>1 then ' → '||v_stock_qty||' '||coalesce(r.stock_unit,r.unit) else '' end);
 end if;
 update tenant_sample.inventory_purchase_orders
 set received_quantity=received_quantity+p_quantity,
     status=case when received_quantity+p_quantity>=ordered_quantity then 'RECEIVED' else 'PARTIAL' end,
     received_at=case when received_quantity+p_quantity>=ordered_quantity then now() else received_at end,
     updated_at=now()
 where id=r.id returning * into r;
 return r;
end $function$
;
CREATE OR REPLACE FUNCTION tenant_qa.admin_inventory_purchase_receive(p_order_id bigint, p_quantity numeric)
 RETURNS tenant_qa.inventory_purchase_orders
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'tenant_qa', 'pg_temp'
AS $function$
declare r tenant_qa.inventory_purchase_orders; v_remaining numeric; v_stock_qty numeric; v_updated bigint;
begin
 select * into r from tenant_qa.inventory_purchase_orders where id=p_order_id for update;
 if r.id is null then raise exception 'ORDER_NOT_FOUND'; end if;
 if not tenant_qa.can_manage_store(r.store_id) then raise exception 'NOT_AUTHORIZED'; end if;
 if r.status not in ('ORDERED','PARTIAL') then raise exception 'ORDER_NOT_RECEIVABLE'; end if;
 v_remaining:=r.ordered_quantity-r.received_quantity;
 if coalesce(p_quantity,0)<=0 or p_quantity>v_remaining then raise exception 'INVALID_RECEIVE_QUANTITY'; end if;
 v_stock_qty:=p_quantity*coalesce(r.conversion_quantity,1);
 if r.manual_item_id is not null then
   update tenant_qa.inventory_manual_items set on_hand=on_hand+v_stock_qty,updated_at=now()
   where id=r.manual_item_id and store_id=r.store_id returning id into v_updated;
   if v_updated is null then raise exception 'INVENTORY_ITEM_NOT_FOUND'; end if;
 else
   if not exists(select 1 from tenant_qa.inventory_items where id=r.item_id) then raise exception 'INVENTORY_ITEM_NOT_FOUND'; end if;
   insert into tenant_qa.inventory_movements(store_id,item_id,business_date,movement_type,quantity,source_type,source_key,note)
   values(r.store_id,r.item_id,(now() at time zone 'Asia/Seoul')::date,'RECEIPT',v_stock_qty,'PURCHASE_ORDER',r.id::text,
          '발주 입고 '||p_quantity||' '||coalesce(r.order_unit,r.unit)||case when coalesce(r.conversion_quantity,1)<>1 then ' → '||v_stock_qty||' '||coalesce(r.stock_unit,r.unit) else '' end);
 end if;
 update tenant_qa.inventory_purchase_orders
 set received_quantity=received_quantity+p_quantity,
     status=case when received_quantity+p_quantity>=ordered_quantity then 'RECEIVED' else 'PARTIAL' end,
     received_at=case when received_quantity+p_quantity>=ordered_quantity then now() else received_at end,
     updated_at=now()
 where id=r.id returning * into r;
 return r;
end $function$
;
