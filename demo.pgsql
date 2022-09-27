------------ From Lucio -----------------
-- Output : df_1
-- Returns
--  agent_uuid
--  date onboarding date/month
--  ASA uuid
with x as (select *,
		   case when classification = 'Inactive' or classification = 'Unclassified' then 'no'
		   else 'yes'
		   end as onboarded
		from metrics.user_classification uc),

y as (select unique_id as uuid_agent, min(date) as date
	from x
	where onboarded = 'yes'
	group by unique_id),
	
df_1 as (
    select 
        y.*, 
        date_trunc('month', date)::date as month, 
        a."asaUuid" as uuid_aba
	from y
	left join agent a
	on y.uuid_agent = a.uuid)

select *
from df_1


------------ Updated -----------------

-- uuid_agent
-- date (timestamp with time zone)
-- month (date)
-- uuid_aba


-- Select all Agents & the ABA that onboarded them
with a as (
select 
    uuid as uuid_agent, 
    "onboardedAsaUuid" as uuid_aba_onboarded
    --"asaUuid" as uuid_aba_managing 
from public.agent
)


select *
from metrics.user_classification
limit 100