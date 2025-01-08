-- запрос ищет отзывы на определенное кино (по его названию и году производства) и упорядочивает результаты по дате отзыва
SELECT 
    r.review_text, -- текст отзыва
    r.rating, -- оценка в шкале от 1 до 10
    r.review_date, -- дата отзыва
    u.username -- имя пользователя, оставившего возраст
FROM reviews r
JOIN users u ON r.user_id = u.user_id
WHERE r.movie_id = (
    SELECT movie_id 
    FROM movies 
    WHERE title LIKE 'Властелин колец: Братство кольца%' 
      AND year_of_production = 2001
) -- ищем id нужного кино, указывая год
ORDER BY r.review_date DESC; -- сортируем по дате отзыва
