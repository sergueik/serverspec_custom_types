use test;

-- report measurement / day for a certain month

-- https://dba.stackexchange.com/questions/97773/get-all-dates-in-the-current-month
SET @report_date = date('2018/07/17');

-- fill an empty month days calendar

DROP TABLE if exists `@report_month_days`;
CREATE TABLE `@report_month_days` (month_day INT NOT NULL PRIMARY KEY);
INSERT INTO `@report_month_days` (`month_day`) VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12), (13), (14), (15), (16), (17), (18), (19), (20), (21), (22), (23), (24), (25), (26), (27), (28), (29), (30), (31), (32);

-- use @report_date to cut off unused days of that month calendar
DELETE FROM `@report_month_days` WHERE month_day > DAY(LAST_DAY(@report_date));

DROP TABLE IF EXISTS daily_data;

CREATE TABLE IF NOT EXISTS daily_data (
  ID INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT,
  creation_date_time DATETIME(3) NOT NULL,
  creation_date DATE,
  measurement INT
);

INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/01',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/01',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/02',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/02',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/01',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/11',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/12',10);


SHOW TABLES;

SELECT creation_date,dayofmonth(creation_date) x, report_month_days.month_day as month_day, SUM(measurement) FROM `@report_month_days` report_month_days LEFT OUTER JOIN daily_data ON DAYOFMONTH(daily_data.creation_date) = report_month_days.month_day GROUP BY month_day ORDER BY month_day;



