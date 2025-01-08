-- запрос осуществляет поиск по имени создателя кино и выводит основную информацию о нем (в том числе список кино с его участием)
SELECT   
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY mm.moviemaker_id ORDER BY m.title) = 1 
        THEN mm.name 
        ELSE NULL 
    END AS name, -- Имя создателя выводится только в первой строке
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY mm.moviemaker_id ORDER BY m.title) = 1 
        THEN mm.photo 
        ELSE NULL 
    END AS photo, -- Фото только в первой строке
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY mm.moviemaker_id ORDER BY m.title) = 1 
        THEN mm.birth_date 
        ELSE NULL 
    END AS birth_date, -- Дата рождения выводится только в первой строке
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY mm.moviemaker_id ORDER BY m.title) = 1 
        THEN mm.birth_place 
        ELSE NULL 
    END AS birth_place, -- Место рождения выводится только в первой строке
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY mm.moviemaker_id ORDER BY m.title) = 1 
        THEN mm.death_date 
        ELSE NULL 
    END AS death_date, -- Дата смерти выводится только в первой строке
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY mm.moviemaker_id ORDER BY m.title) = 1 
        THEN mm.death_place 
        ELSE NULL 
    END AS death_place,
    mm_m.role, 
    m.title,
    m.year_of_production, 
    m.type 
FROM moviemakers mm
JOIN moviemaker_and_movie mm_m ON mm.moviemaker_id = mm_m.moviemaker_id
JOIN movies m ON mm_m.movie_id = m.movie_id
WHERE mm.ts_description @@ plainto_tsquery('Питер Джексон') 
ORDER BY mm.name, m.title;
