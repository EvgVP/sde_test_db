create table results (
	id INT,
	response TEXT
);

/*1. Вывести максимальное количество человек в одном бронировании*/

insert into results
select 1, count(passenger_id) as c_pas
from tickets t
group by book_ref
order by count(passenger_id) desc
limit 1;

/*2. Вывести количество бронирований с количеством людей
 больше среднего значения людей на одно бронирование*/

with passengers_count as (
	select book_ref as b_ref, count(passenger_id) as c_pas
	from tickets t
	group by book_ref
	)
insert into results
select 2, count(b_ref) as c_ref
from passengers_count
where c_pas > (
	select avg(c_pas)
	from passengers_count
);

/* 3. Вывести количество бронирований, у которых состав пассажиров
 повторялся два и более раза, среди бронирований с максимальным количеством людей (п.1)?*/

with max_passengers_count as (
	select count(passenger_id) as c_pas
	from tickets t
	group by book_ref
	order by count(passenger_id) desc
	limit 1
),
passengers_count as (
	select count(passenger_id) as c_pas, book_ref as b_ref
	from tickets t
	group by book_ref
),
all_max as (
	select b_ref
	from passengers_count
	where c_pas = (
		select c_pas
		from max_passengers_count
	)
),
in_book_ref as (
	select t1.book_ref, t1.passenger_id
	from all_max join tickets t1
	on all_max.b_ref = t1.book_ref
)
insert into results
select 3, t1.book_ref as refs
from in_book_ref t1 join in_book_ref t2
on t1.book_ref <> t2.book_ref
and t1.passenger_id = t2.passenger_id
join in_book_ref t3
on t1.book_ref  <> t3.book_ref
and t2.book_ref <> t3.book_ref
and t2.passenger_id = t3.passenger_id;

/*4. Вывести номера брони и контактную информацию по пассажирам в брони
 (passenger_id, passenger_name, contact_data) с количеством людей в брони = 3*/

with b_ref as (
	select book_ref, count(passenger_id)
	from tickets t
	group by book_ref
	having count(passenger_id) = 3
)
insert into results
select 4, b_r||'|'||passenger_id ||'|'||passenger_name ||'|'||contact_data
from (
	select b_ref.book_ref as b_r, passenger_id, passenger_name, contact_data
	from b_ref join tickets
	on b_ref.book_ref = tickets.book_ref
	order by tickets.book_ref, passenger_id, passenger_name, contact_data
) s;

/*5. Вывести максимальное количество перелётов на бронь*/

insert into results
select 5, count(flight_id) as c_flights
from tickets t join ticket_flights tf
on t.ticket_no = tf.ticket_no
group by book_ref
order by count(flight_id) desc
limit 1;

/*6. Вывести максимальное количество перелётов на пассажира в одной брони*/

insert into results
select 6, count(flight_id) as c_flights
from tickets t join ticket_flights tf
on t.ticket_no = tf.ticket_no
group by book_ref, passenger_id
order by count(flight_id) desc
limit 1;

/*7. Вывести максимальное количество перелётов на пассажира*/

insert into results
select 7, count(flight_id) as c_flights
from tickets t join ticket_flights tf
on t.ticket_no = tf.ticket_no
group by passenger_id
order by count(flight_id) desc
limit 1;

/*8. Вывести контактную информацию по пассажиру(ам)
 (passenger_id, passenger_name, contact_data) и общие траты на билеты,
 для пассажира потратившего минимальное количество денег на перелеты*/

with sum_amount as (
	select passenger_id, passenger_name, contact_data, sum(amount) as total_amount
	from tickets t join ticket_flights tf
	on t.ticket_no = tf.ticket_no
	join flights f
	on tf.flight_id = f.flight_id
	where f.status <> 'Cancelled'
	group by passenger_id, passenger_name, contact_data
	order by sum(amount)
)
insert into results
select 8, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||total_amount
from
(select passenger_id, passenger_name, contact_data,total_amount
from sum_amount
where total_amount = (
	select min(total_amount) as min_total_amount
	from sum_amount
)
order by passenger_id, passenger_name, contact_data asc) tt;

/*9. Вывести контактную информацию по пассажиру(ам)
 (passenger_id, passenger_name, contact_data) и общее время в полётах,
 для пассажира, который провёл максимальное время в полётах*/

with flight_time as (
	select passenger_id, passenger_name, contact_data, sum(actual_duration) as total_flight_time
	from flights_v fv join ticket_flights tf
	on fv.flight_id = tf.flight_id
	join tickets tk
	on tk.ticket_no  = tf.ticket_no
	where fv.status = 'Arrived'
	group by passenger_id, passenger_name, contact_data
)
insert into results
select 9, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||total_flight_time
from (
	select passenger_id, passenger_name, contact_data, total_flight_time
	from flight_time ft
	where total_flight_time = (
		select max(total_flight_time) as max_flight_time
		from flight_time
	)
	order by passenger_id, passenger_name, contact_data
) s;

/*10. Вывести город(а) с количеством аэропортов больше одного*/

insert into results
select 10, city
from airports a
group by city
having count(airport_code) > 1
order by city;

/*11. Вывести город(а), у которого самое меньшее количество городов прямого сообщения*/

with cities_count as (
	select departure_city, count(distinct arrival_city) as c_count
	from routes r
	group by departure_city
)
insert into results
select 11, departure_city
from cities_count
where c_count = (
	select min(c_count)
	from cities_count
)
order by departure_city;

/*12. Вывести пары городов, у которых нет прямых сообщений
 исключив реверсные дубликаты*/

insert into results
select 12, d.departure_city || '|' || d.departure_city_2
from (
	select  a.departure_city , b.departure_city as departure_city_2
	from routes a
	inner join routes b
	on  a.departure_city <> b.departure_city
	group by a.departure_city, b.departure_city
)  d
left join
	(select  a.departure_city, a.arrival_city
	from routes a
	group by a.departure_city, a.arrival_city
) as c
on d.departure_city = c.departure_city and d.departure_city_2 = c.arrival_city
where c.departure_city is null and c.arrival_city is null and d.departure_city < d.departure_city_2
order by d.departure_city, d.departure_city_2

/*13. Вывести города, до которых нельзя добраться без пересадок из Москвы*/

insert into results
select distinct 13, r1.arrival_city
from routes r1
where r1.arrival_city NOT IN (select r2.arrival_city from routes r2 where r2.departure_city = 'Москва')  and r1.arrival_city != 'Москва'
order by arrival_city;

/*14. Вывести модель самолета, который выполнил больше всего рейсов*/

insert into bookings.results
select 14, a.model
from  flights f join aircrafts a  on f.aircraft_code = a.aircraft_code
where f.status != 'Cancelled'
group by a.model
order by count(*) desc
limit 1;

/*15. Вывести модель самолета, который перевез больше всего пассажиров*/

insert into results
select 15, a.model
from  flights f join aircrafts a on f.aircraft_code = a.aircraft_code
join ticket_flights tf on tf.flight_id = f.flight_id
join tickets t on t.ticket_no =tf.ticket_no
where f.status = 'Arrived'
group by a.model
order by count(*) desc
limit 1;

/*16. Вывести отклонение в минутах суммы запланированного времени
 перелета от фактического по всем перелётам*/

insert into results
select 16, (DATE_PART('day', count_all) * 24 + DATE_PART('hour', count_all)) * 60 + DATE_PART('minute',count_all)
from
	(select (sum(actual_duration) - sum(scheduled_duration)) as count_all
	from bookings.flights_v
	where status = 'Arrived') as a

/*17. Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2016-09-13*/

insert into results
select distinct 17,  arrival_city
from flights_v fv
where (status = 'Arrived' or status = 'Departed')
	  and departure_city = 'Санкт-Петербург'
	  and date(actual_departure) = '2016-09-13'
order by arrival_city;

/*18. Вывести перелёт(ы) с максимальной стоимостью всех билетов*/

insert into results
select 18, flight_id
from flights_v
where flight_id = (
	select flight_id
	from ticket_flights
	group by flight_id
	order by sum(amount) desc
	limit 1);

/*19. Выбрать дни в которых было осуществлено минимальное количество перелётов*/

with count_flights as (
	select date(actual_departure) as depart_date, count(flight_id) as c_flights
	from flights f
	where status <> 'Cancelled'
		  and actual_departure is not null
	group by date(actual_departure)
)
insert into results
select 19, depart_date
from count_flights
where c_flights = (
	select min(c_flights)
	from count_flights
);

/*20. Вывести среднее количество вылетов в день из Москвы за 09 месяц 2016 года */

insert into results
select 20, avg(count_flights) avg_flights_per_day
from
	(select count(flight_id) count_flights
	from flights
	where actual_departure is not null and date_trunc('month', actual_departure) = '2016-09-01'
	group by actual_departure::date) t;

/*21. Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3
часов*/

insert into results
select 21, t1.dep_city
from
	(select departure_city as dep_city
	from flights_v
	group by departure_city
	having avg(actual_duration)  > interval '3hours'
	order by  avg(actual_duration) desc
	limit 5) t1
order by t1.dep_city;

