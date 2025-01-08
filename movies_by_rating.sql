-- запросы ищут кино с самым высоким и низким рейтингом (по критериям)
SELECT m.movie_id, m.title, m.user_rating, m.year_of_production, m.duration, m.age_rating
FROM movies m
WHERE m.user_rating > 8.0 -- только кино с рейтингом больше 8
  AND m.year_of_production >= 2000 -- кино, произведённое после 2000 года
ORDER BY m.user_rating DESC; -- сортировка по убыванию рейтинга

SELECT m.movie_id, m.title, m.user_rating, m.year_of_production, m.view_count
FROM movies m
WHERE m.user_rating < 7.5 -- только кино с рейтингом ниже 7,5
  AND m.view_count >= 1 -- фильтры на минимальное количество просмотров (в более наполненной базе данных можно поставить число побольше, чтобы отсечь совсем не популярные фильмы)
  AND m.year_of_production >= 2000 -- кино после 2000 года
ORDER BY m.user_rating ASC; -- сортировка по возрастанию рейтинга
