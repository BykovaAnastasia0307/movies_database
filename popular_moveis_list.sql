-- получение списка самого популярного кино за год
SELECT 
    m.title,
    m.year_of_production,
    COUNT(wm.watched_movie_id) AS total_views -- Общее количество просмотров за год (на практике полезнее будет считать за неделю или месяц)
FROM movies m
JOIN watched_movies wm ON m.movie_id = wm.movie_id
WHERE EXTRACT(YEAR FROM wm.watching_date) = EXTRACT(YEAR FROM CURRENT_DATE) -- Просмотры за текущий год (но на практике можно посчитать за месяц или неделю)
GROUP BY m.movie_id, m.title, m.year_of_production -- Группируем по кино
ORDER BY total_views DESC; -- Сортировка по убыванию количества просмотров
