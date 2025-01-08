-- запрос осуществляет поиск по названию кино и выводит основную информацию о нем
SELECT 
    m.title, 
    m.poster, 
    m.type, 
    m.description, 
    m.year_of_production, 
    m.age_rating, 
    m.duration, 
    m.user_rating, 
    m.view_count, 
    st.subscription_type, 
    STRING_AGG(DISTINCT g.genre_name, ', ') AS genres, 
    STRING_AGG(DISTINCT c.country_name, ', ') AS countries, 
    STRING_AGG(DISTINCT v.video_link, ', ') AS video_links 
FROM movies m
JOIN genre_and_movie gm ON m.movie_id = gm.movie_id
JOIN genres g ON gm.genre_id = g.genre_id
JOIN country_and_movie cm ON m.movie_id = cm.movie_id
JOIN countries c ON cm.country_id = c.country_id
JOIN subscription_types st ON m.subscription_id = st.subscription_id
JOIN video v ON m.movie_id = v.movie_id
WHERE m.ts_description @@ plainto_tsquery('властелин колец')
GROUP BY 
    m.movie_id, 
    m.title, 
    m.poster, 
    m.type, 
    m.description, 
    m.year_of_production, 
    m.age_rating, 
    m.duration, 
    m.user_rating, 
    m.view_count, 
    st.subscription_type;
