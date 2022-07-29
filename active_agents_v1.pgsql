
-- Set days where we wwant to calculated commisiosn on
with calc_dates_1 (calc_for_month, date_time) AS (
    values
    ('July',  date_trunc('day','2022-07-27T00:00:00.000Z'::date)),
    ('June',  date_trunc('day','2022-06-27T00:00:00.000Z'::date)),
    ('May',   date_trunc('day','2022-05-27T00:00:00.000Z'::date)),
    ('April', date_trunc('day','2022-04-27T00:00:00.000Z'::date))
),

-- If the current month assessment is in future then select the current date
calc_dates_2 as (
    select
    calc_for_month,
    case 
        when date_time > date_trunc('day',CURRENT_DATE::date) then date_trunc('day',CURRENT_DATE::date)
        else date_time
    end as date_time
    from calc_dates_1
),

-- Select agent status
df_agent_staus_1 as (
    -- Select Agent & Agent status
    select 
        unique_id as uuid_agent,
        "asaUuid" as uuid_aba,
        classification,
        date
    from metrics.user_classification
    -- Join agent table to get agent's ABA ("asaUuid")
    left join agent on agent.uuid =  unique_id
    -- Filter ABA calcs to only date we want to calculate
    where date in (select date_time from calc_dates_2) -- where calc_for_month = 'June'
    -- Filter out agents with no ABA
    and "asaUuid" is not null
),

-- Group to see total count of aggets in each status
df_agent_status_2 as (
    select 
        count(*),
        uuid_aba,
        classification,
        date as commision_calc_date
    from df_agent_staus_1
    group by uuid_aba, classification, date
),

-- Add in ABA & filter out any ABAs not in the system
df_agent_status_3 as (
    select
        commision_calc_date,
        count,
        classification,
        uuid_aba,
        "name" as aba_name,
        email
    from df_agent_status_2
    left join success_associate on uuid_aba = uuid
    where email is not null
),

-- Order data
df_agent_status_4 as (
    select *
    from df_agent_status_3
    order by aba_name, commision_calc_date, classification
)

select *
from df_agent_status_4



