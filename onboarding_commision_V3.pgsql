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
	on y.uuid_agent = a.uuid),

------------ End Lucio script ------------

-- Filter out ABAs with no email in the mangement dashboard
df_2 as (
    select * 
    from df_1
    where uuid_aba in (select uuid from success_associate where email is not null)),

-- Add in ABA names
df_3 as (
    select
        uuid_agent, date, "month" as month_onboarded, uuid_aba, "name" as aba_name
    from df_2 as a
    left join success_associate as b on a.uuid_aba = b.uuid
),

-- These are the dates on which commissions are to be calcualed
-- If a agent is onboarded in a month but after the coresponding date then they would count for the following months commission
calc_dates_1 (calc_for_month, date_time) AS (
    values
    ('December',  date_trunc('day','2022-12-31T00:00:00.000Z'::date)),
    ('November',  date_trunc('day','2022-11-30T00:00:00.000Z'::date)),
    ('October',   date_trunc('day','2022-10-31T00:00:00.000Z'::date)),
    ('September', date_trunc('day','2022-09-30T00:00:00.000Z'::date)),
    ('August',    date_trunc('day','2022-08-31T00:00:00.000Z'::date)),
    ('July',      date_trunc('day','2022-07-31T00:00:00.000Z'::date)),
    ('June',      date_trunc('day','2022-06-30T00:00:00.000Z'::date)),
    ('May',       date_trunc('day','2022-05-31T00:00:00.000Z'::date)),
    ('April',     date_trunc('day','2022-04-30T00:00:00.000Z'::date))
),

-- Set out what month the agent would fall into based on the above dates
df_4 as (
    select 
        case 
            when "date" <= (select date_time from calc_dates_1 where "calc_for_month" = 'April') then 'April'
            when "date" <= (select date_time from calc_dates_1 where "calc_for_month" = 'May') then 'May'
            when "date" <= (select date_time from calc_dates_1 where "calc_for_month" = 'June') then 'June'
            when "date" <= (select date_time from calc_dates_1 where "calc_for_month" = 'July') then 'July'
            when "date" <= (select date_time from calc_dates_1 where "calc_for_month" = 'August') then 'August'
            when "date" <= (select date_time from calc_dates_1 where "calc_for_month" = 'September') then 'September'
            when "date" <= (select date_time from calc_dates_1 where "calc_for_month" = 'October') then 'October'
            when "date" <= (select date_time from calc_dates_1 where "calc_for_month" = 'November') then 'November'
            when "date" <= (select date_time from calc_dates_1 where "calc_for_month" = 'December') then 'December'
            else 'Error'
        end as agent_onboard_month_for_commissions,
        *
    from df_3
),

-- Group by month & aba
df_5 as (
    select 
        aba_name, 
        agent_onboard_month_for_commissions, 
        count(*) as total_agents_onboarded, 
        uuid_aba,
        date_time
    from df_4
    left join calc_dates_1 on agent_onboard_month_for_commissions = calc_for_month
    group by uuid_aba, aba_name, agent_onboard_month_for_commissions, date_time
    order by aba_name, date_time desc
)

select
    aba_name,
    uuid_aba,
    total_agents_onboarded,
    agent_onboard_month_for_commissions,
    date_time
from df_5
-- Remove April as it includes all previous agents (i.e. Jan, Feb, Mar)
where agent_onboard_month_for_commissions <> 'April'