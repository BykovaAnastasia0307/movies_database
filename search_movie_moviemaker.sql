-- запрос осуществляет поиск кино по его создателям
SELECT DISTINCT 
    m.*, -- Информация о кино
    mmk.name AS moviemaker_name, -- Имя создателя кино
    mm.role AS moviemaker_role -- Роль создателя в кино
FROM movies m
JOIN moviemaker_and_movie mm ON m.movie_id = mm.movie_id
JOIN moviemakers mmk ON mm.moviemaker_id = mmk.moviemaker_id
WHERE mmk.name ILIKE 'Питер Джексон'; 
