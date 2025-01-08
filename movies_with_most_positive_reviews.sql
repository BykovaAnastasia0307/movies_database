-- запрос ищет кино с наибольшим количеством положительных отзывов (оценка от 8) и выводит их в порядке убывания количества положительных отцывов
WITH positive_reviews AS (
    -- Считаем количество положительных отзывов для каждого фильма
    SELECT 
        r.movie_id, 
        COUNT(r.review_id) AS positive_reviews_count
    FROM 
        reviews r
    WHERE 
        r.rating >= 8  
    GROUP BY 
        r.movie_id
),
top_movies AS (
    -- Выбираем топ-5 фильмов с наибольшим количеством положительных отзывов
    SELECT 
        movie_id, 
        positive_reviews_count
    FROM 
        positive_reviews
    ORDER BY 
        positive_reviews_count DESC
    LIMIT 5
)
SELECT 
    m.title, 
    tm.positive_reviews_count, -- число положительных отзывов
    m.year_of_production, 
    m.type
FROM 
    top_movies tm
JOIN 
    movies m ON tm.movie_id = m.movie_id
ORDER BY 
    tm.positive_reviews_count DESC; -- сортировка по убыванию числа отзывов


