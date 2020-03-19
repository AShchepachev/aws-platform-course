create database mydbpostgresweek3;
\connect mydbpostgresweek3

create table myTableWeek3 (
	id int not null,
	name varchar(80),
	primary key (id)
);

insert into myTableWeek3 (id, name)
values (1, 'FirstLine'),
       (2, 'SecondLine');

select current_database();

select * from myTableWeek3;
