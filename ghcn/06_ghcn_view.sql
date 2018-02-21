drop view if exists ghcn; 

create view ghcn as 
select o.station_code, 
st.latitude, 
st.longitude,
st.elevation, 
st.state, 
st.name, 
o.observation_date, 
o.data_value,
o.element, 
e.description as element_description,
o.m_flag, 
m.description as measure_description, 
o.q_flag,
q.description as quality_description,
o.s_flag,
s.description as sample_description,
o.obs_time
from observation o 
join station st 
on (o.station_code = st.id)
join elements e 
on (o.element = e.element)
left join mflags m 
on (o.m_flag = m.mflag) 
left join qflags q 
on (o.q_flag = q.qflag) 
left join sflags s 
on (o.s_flag = s.sflag) 
;

