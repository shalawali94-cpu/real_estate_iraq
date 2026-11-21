-- Product decision: the 30,000 IQD publishing fee applies to every listing type
-- (sale, rent, short-term rent, investment). Super admin can still narrow this
-- later from payment settings.
update public.payment_settings
   set applies_to_transaction_types = '{sale,rent,short_term_rent,investment}',
       updated_at = now()
 where service_type = 'PROPERTY_PUBLISHING';
