-- запрос осуществляет поиск кино по его характеристикам (жанр, страна, год создания)
SELECT DISTINCT m.*
FROM movies m
JOIN genre_and_movie gm ON m.movie_id = gm.movie_id
JOIN genres g ON gm.genre_id = g.genre_id
JOIN country_and_movie cm ON m.movie_id = cm.movie_id
JOIN countries c ON cm.country_id = c.country_id
WHERE g.genre_name ILIKE 'драма' 
  AND m.year_of_production > 2003
  AND c.country_name  ILIKE 'Россия';
