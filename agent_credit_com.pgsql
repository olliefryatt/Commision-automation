/*THE PAID is paid in period */ 
 

/*gather info on agent that we need*/  
with agent_info as (
	select 
	a.uuid, 
	a."agentName",
	l.uuid as loan_id_c, 
	aba_manage.name as aba_name,  
	case when l.uuid is not null then row_number() over (partition by l."agentUuid" order by l."startDate") end as loan_cycle 
	from agent a
	left join loan l on a.uuid = l."agentUuid"
	left JOIN success_associate aba_manage ON a."asaUuid" = aba_manage.uuid
	-- left JOIN success_associate aba_onboard ON a."onboardedAsaUuid" = aba_onboard.uuid
	where l."agentUuid" is not null 
)
, 
/*grab the weekly cohort data => you may want to make this w*/ 
loan_w_benchmarks as (
select l."loanId" as loan_id,
	   lrs.loan_id as long_loan_id, 
	   date(date_gs)  as report_date, 
--  date(date_gs) - date(start_date) as payment_number, 
-- 	   date(lrs.start_date) as start_date, 
	   l."durationInMonths" * 4 as loan_duration_weeks, 
	   (date(lrs.date_gs) - date(lrs.start_date))  as dob, 
	   (date(lrs.date_gs) - date(lrs.start_date))/7  as week, 
	   case when date(lrs.date_gs) >= "endDate" then "endDate" else date(lrs.date_gs) end as due_date_actual, 
	   date(lrs.date_gs) as due_date_artificial, 
	 --  round("loanAmount"*(1+ (0.05*"durationInMonths")))
	
	   l."startDate" as startdate,
	   l."endDate", 
	   "agentUuid", 
	   "agentName", 
	   a.aba_name, 
	   a.loan_cycle, 
	   total as amount_due, 
	   lrs.weekly_payment as expected, 
	   owed as cum_expected, 
--	   amount as paid, 
	   cum_amount as cum_paid_2
	     	
from metrics.loan_repayment_schedule lrs 
left join loan l on lrs.loan_id = l.uuid
left join agent_info a on a.uuid = l."agentUuid" and a.loan_id_c = lrs.loan_id

-- keep the last day of the month (if week make this end of the week)   
where date(date_gs) = date(date_trunc('month', date(date_gs)))
--(date(date_gs) - date(start_date)) % 7 = 0 
--and l.uuid = '4842da8e-729d-4fb9-a6be-77a512107a5b'
--where loan_id = '0002'

) 

, agent_payments as (
 select 	 
	  -- lrs.*, 
	  -- date(startdate)+(weeks*7) as payment_date_artifical, 
	  	  report_date, 
	  	  "agentUuid" as agent_id, 
	  	  aba_name, 
	  	 coalesce(sum(case when date(lp.date) > date(due_date_artificial)-7 then amount else 0 end),0) as paid_in_period,
	   	 coalesce(sum(amount),0) as cum_paid,
-- 	   	 sum(case when amount is not null then 1 else 0 end) as payment_num, 
	   	 date(max(lp."date")) as last_payment_day
	   
from loan_w_benchmarks lrs
left join public.loan_payment lp on lrs.long_loan_id = lp."loanUuid" and date(date_trunc('month', date(lp.date)))  <= report_date
where report_date <= current_date
group by 1,2,3 --,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18) 

)

/*Delinquency rate defined as if you had at least one agent with delinquency > 1 that is counted as a delinquent loan.*/ 

select report_date, 
	   aba_name, 
	   case when sum(sum_active_loans) = 0 then 'no active loans' else 'activite loans' end as activity_status, 
	   case when sum(sum_active_loans) > 0 then 
	   round(sum(sum_deliquencies) / sum(sum_active_loans),4) end as delinquency_rate,
	  
	   sum(paid_in_period) as paid_in_period
	   
from agent_payments ap 

left join (
			select date(date_trunc('month', date(date))) as report_d ,
				  unique_id,  
				  sum(case when delinquencies>= 1 then 1 else 0 end) as sum_deliquencies, 
				  sum(has_active_loan) as sum_active_loans 
				  
		   from metrics.user_classification
		   group by 1,2
		--   having  sum(case when delinquencies>= 1 then 1 else 0 end) >   sum(has_active_loan)
		    ) 
		   uc on ap.agent_id = uc.unique_id and uc.report_d = ap.report_date 

group by 1,2
order by aba_name,report_date; --sum_deliquencies; 

--select * from metrics.user_classification where unique_id = '0f487962-ad71-4670-b7fa-3360edee1d8c';