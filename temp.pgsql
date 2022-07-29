-- Set days where we wwant to calculated commisiosn on
with calc_dates (calc_for_month, date_time) AS (
    values
    ('July',  date_trunc('day','2022-07-27T00:00:00.000Z'::date)),
    ('June',  date_trunc('day','2022-06-27T00:00:00.000Z'::date)),
    ('May',   date_trunc('day','2022-05-27T00:00:00.000Z'::date)),
    ('April', date_trunc('day','2022-04-27T00:00:00.000Z'::date))
)

select 
    case 
        when date_time > date_trunc('day',CURRENT_DATE::date) then date_trunc('day',CURRENT_DATE::date)
        else date_time
    end
from calc_dates 

SELECT date_trunc('day',CURRENT_DATE::date);