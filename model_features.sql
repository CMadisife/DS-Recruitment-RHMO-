/**
This data accounts for learners who are eligible for renewal and have either renewed or churned out of the system.
Here, I account for whether they have attempted an exam, joined a live lesson or watched a pre-recorded video.
Also, for the first three weeks before their current subscription ends, I counted how many exams they attempted,
live lessons joined and the number of pre-recorded videos watched
**/

SELECT t1.learner_id,
CASE
WHEN t2.grade_id in (4,5,6) THEN "Primary"
WHEN t2.grade_id  in (7,8,9) THEN "Junior"
WHEN t2.grade_id  in (10,11,12) THEN "Senior"
END as library,
plan, t1.start_at, t1.end_at, duration_months, status,
t3.name as country,
IF(total_exam > 0, "YES", "NO") AS exam_done,
total_exam,
IF(total_live > 0, "YES","NO") AS live_lesson_attended,
total_live,
IF(total_recorded > 0, "YES", "NO") AS watched_recorded,
total_recorded,
IF(total_practices > 0, "YES", "NO") AS practice_done,
total_practices
FROM `ulesson-app.Static.eligible_renewals` t1
LEFT JOIN `ulesson-app.mysql_rds_ulesson_production_backend.learners` as t2
ON t1.learner_id = t2.id 

LEFT JOIN `ulesson-app.mysql_rds_ulesson_production_backend.countries` t3 
ON t2.country_id = t3.id 

LEFT JOIN
(
WITH smat as
(
SELECT t1.learner_id, start_at, end_at,
IF(attempted_at BETWEEN start_at and DATE_SUB(end_at, INTERVAL 7 DAY),exam_id, null ) as exam_id,
COUNT(attempted_at) as total 
FROM `ulesson-app.Static.eligible_renewals` t1
LEFT JOIN 
(SELECT CAST(new_attempted_at AS DATE) attempted_at, learner_id, exam_id
FROM (SELECT *,
CASE
WHEN attempted_at < '2020-02-27' then created_at
ELSE attempted_at
END AS new_attempted_at
FROM `ulesson-app.mysql_rds_ulesson_production_backend.exams_progress`)) as t3
ON t1.learner_id = t3.learner_id
GROUP BY learner_id,  start_at, end_at,exam_id
)
SELECT learner_id, start_at, end_at, COUNT(DISTINCT(exam_id)) as total_exam
FROM smat 
GROUP BY  learner_id, start_at, end_at
) as t4
ON t1.learner_id = t4.learner_id and t1.start_at = t4.start_at and t1.end_at = t4.end_at

LEFT JOIN 
(
WITH emoji as
(
SELECT t1.learner_id, start_at, end_at,
IF(attended_at BETWEEN start_at and DATE_SUB(end_at, INTERVAL 7 DAY),live_lesson_id, null) as live_id
FROM `ulesson-app.Static.eligible_renewals` t1
LEFT JOIN 
( SELECT CAST(attended_at AS DATE) as attended_at, learner_id, live_lesson_id
FROM `ulesson-app.mysql_rds_ulesson_production_backend.live_lessons_attendance`) t2
ON t1.learner_id = t2.learner_id 
GROUP BY  t1.learner_id, live_id, start_at, end_at
)
SELECT learner_id,start_at, end_at, COUNT(DISTINCT(live_id)) as total_live
FROM emoji 
GROUP BY learner_id, start_at, end_at
) as t5
ON t1.learner_id = t5.learner_id and t1.start_at = t5.start_at and t1.end_at = t5.end_at

LEFT JOIN  
(
WITH mulla as
(
SELECT t1.learner_id, start_at, end_at,
IF(CAST(new_completed_at as DATE) BETWEEN start_at and DATE_SUB(end_at, INTERVAL 7 DAY),lesson_id, null) as lesson_id
FROM `ulesson-app.Static.eligible_renewals` t1
LEFT JOIN 
(SELECT *, 
CASE 
WHEN completed_at < '2020-02-27' then created_at
ELSE completed_at
END AS new_completed_at
FROM `ulesson-app.mysql_rds_ulesson_production_backend.lessons_progress`) as t2
ON t1.learner_id=t2.learner_id 
GROUP BY  t1.learner_id, lesson_id, start_at, end_at
)
SELECT learner_id,start_at, end_at, COUNT(DISTINCT(lesson_id)) as total_recorded
FROM mulla 
GROUP BY learner_id, start_at, end_at) AS t6
ON t1.learner_id = t6.learner_id and t1.start_at = t6.start_at and t1.end_at = t6.end_at

LEFT JOIN 
(
WITH smat as
(
SELECT t1.learner_id, start_at, end_at,
IF(attempted_at BETWEEN start_at and DATE_SUB(end_at, INTERVAL 7 DAY),chapter_id, null ) as chapter_id,
COUNT(attempted_at) as total 
FROM `ulesson-app.Static.eligible_renewals` t1
LEFT JOIN 
(SELECT CAST(new_attempted_at AS DATE) attempted_at, learner_id, chapter_id
FROM (SELECT *,
CASE
WHEN attempted_at < '2020-02-27' then created_at
ELSE attempted_at
END AS new_attempted_at
FROM `ulesson-app.mysql_rds_ulesson_production_backend.practices`)) as t3
ON t1.learner_id = t3.learner_id
GROUP BY learner_id,  start_at, end_at,chapter_id
)
SELECT learner_id, start_at, end_at, COUNT(DISTINCT(chapter_id)) as total_practices
FROM smat 
GROUP BY  learner_id, start_at, end_at
) AS t7
ON t1.learner_id = t7.learner_id and t1.start_at = t7.start_at and t1.end_at = t7.end_at


-- WHERE t1.learner_id = 92250
GROUP BY learner_id, plan, start_at, end_at, duration_months, status, country, 
total_exam, total_live, total_recorded, library, total_practices


