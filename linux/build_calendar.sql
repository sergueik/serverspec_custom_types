use test;

-- report measurement / day for a certain month

SET @report_date = date('2018/07/17');

-- fill an empty month days calendar

DROP TABLE if exists `@report_month_days`;
CREATE TABLE `@report_month_days` (month_day INTEGER);
INSERT INTO `@report_month_days` (`month_day`) VALUES (1);
INSERT INTO `@report_month_days` (`month_day`) VALUES (2);
INSERT INTO `@report_month_days` (`month_day`) VALUES (3);
INSERT INTO `@report_month_days` (`month_day`) VALUES (4);
INSERT INTO `@report_month_days` (`month_day`) VALUES (5);
INSERT INTO `@report_month_days` (`month_day`) VALUES (6);
INSERT INTO `@report_month_days` (`month_day`) VALUES (7);
INSERT INTO `@report_month_days` (`month_day`) VALUES (8);
INSERT INTO `@report_month_days` (`month_day`) VALUES (9);
INSERT INTO `@report_month_days` (`month_day`) VALUES (10);
INSERT INTO `@report_month_days` (`month_day`) VALUES (11);
INSERT INTO `@report_month_days` (`month_day`) VALUES (12);
INSERT INTO `@report_month_days` (`month_day`) VALUES (13);
INSERT INTO `@report_month_days` (`month_day`) VALUES (14);
INSERT INTO `@report_month_days` (`month_day`) VALUES (15);
INSERT INTO `@report_month_days` (`month_day`) VALUES (16);
INSERT INTO `@report_month_days` (`month_day`) VALUES (17);
INSERT INTO `@report_month_days` (`month_day`) VALUES (18);
INSERT INTO `@report_month_days` (`month_day`) VALUES (19);
INSERT INTO `@report_month_days` (`month_day`) VALUES (20);
INSERT INTO `@report_month_days` (`month_day`) VALUES (21);
INSERT INTO `@report_month_days` (`month_day`) VALUES (22);
INSERT INTO `@report_month_days` (`month_day`) VALUES (23);
INSERT INTO `@report_month_days` (`month_day`) VALUES (24);
INSERT INTO `@report_month_days` (`month_day`) VALUES (25);
INSERT INTO `@report_month_days` (`month_day`) VALUES (26);
INSERT INTO `@report_month_days` (`month_day`) VALUES (27);
INSERT INTO `@report_month_days` (`month_day`) VALUES (28);
INSERT INTO `@report_month_days` (`month_day`) VALUES (29);
INSERT INTO `@report_month_days` (`month_day`) VALUES (30);
INSERT INTO `@report_month_days` (`month_day`) VALUES (31);
INSERT INTO `@report_month_days` (`month_day`) VALUES (32);

-- use @report_date to cut off unused days of that month calendar
DELETE FROM `@report_month_days` WHERE month_day > DAY(LAST_DAY(@report_date));

DROP TABLE IF EXISTS daily_data;
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/01',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/01',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/02',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/02',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/01',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/11',10);
INSERT INTO daily_data (creation_date,measurement) VALUES  ('2019/07/12',10);
CREATE TABLE IF NOT EXISTS daily_data (
  ID INTEGER PRIMARY KEY NOT NULL AUTO_INCREMENT,
  creation_date_time DATETIME(3) NOT NULL,
  creation_date DATE,
  measurement INT  
);
SHOW TABLES;

SELECT creation_date,dayofmonth(creation_date) x, report_month_days.month_day as month_day, SUM(measurement) FROM `@report_month_days` report_month_days LEFT OUTER JOIN daily_data ON DAYOFMONTH(daily_data.creation_date) = report_month_days.month_day GROUP BY month_day ORDER BY month_day;



