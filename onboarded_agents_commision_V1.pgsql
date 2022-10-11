
with x as (
	select 
		*,
		-- Agent is only considered onboarded if they move from Inactive or Unclassified
		case when classification = 'Inactive' or classification = 'Unclassified' then 'no'
			else 'yes'
		   	end as onboarded
	from metrics.user_classification uc
),

y as (
	select 
		unique_id as uuid_agent, 
		min(date) as date -- date the agent offically counts as onboarded. It is not the onboarded date
	from x
	where onboarded = 'yes'
	group by unique_id
),

z as (
	select
		unique_id as uuid_agent, 
		min(date) as date_onboarded -- date agent first appears in system. i.e. date they were onboarded
	from metrics.user_classification uc
	group by unique_id
),
	
df_1 as (
    select 
        y.uuid_agent, 
		y.date as date_agent_moved_to_officall_onboarded,
        a."asaUuid" as uuid_aba,
		a."onboardedAsaUuid" as uuid_aba_onboarded_by
	from y
	left join agent a on y.uuid_agent = a.uuid
),

df_2 as (
	select
		df_1.uuid_agent,
		z.date_onboarded,
		df_1.date_agent_moved_to_officall_onboarded,
		uuid_aba as uuid_aba_managed_by,
		uuid_aba_onboarded_by,
		'yes' as "onboarded_correctly"
	from df_1
	left join z on df_1.uuid_agent = z.uuid_agent
),

-- Need all Agents who never actually got onboarded correclty but are still in the system
df_3 as (
	select 
		unique_id as uuid_agent, 
		min(date) as date_onboarded
	from metrics.user_classification
	where unique_id not in (select distinct(uuid_agent) from df_2)
	group by unique_id
),

df_4 as (
	select
		uuid_agent,
		date_onboarded,
		NULL::timestamptz as date_agent_moved_to_officall_onboarded,
		"asaUuid" as uuid_aba_managed_by,
		"onboardedAsaUuid" as uuid_aba_onboarded_by,
		'no' as "onboarded_correctly"
	from df_3
	left join agent on uuid = uuid_agent
),

-- Join two data set together
df_5 as (
	select * from df_2
	UNION
	select * from df_4
)

select *
from df_5