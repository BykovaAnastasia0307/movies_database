--
-- PostgreSQL database dump
--

-- Dumped from database version 10.22
-- Dumped by pg_dump version 10.22

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: add_to_watched_movies(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_to_watched_movies() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- добавляем в таблицу watched_movies фильмы из истории просмотра
    IF TG_TABLE_NAME = 'history' THEN
        IF NEW.stop_time = (SELECT duration FROM movies WHERE movie_id = NEW.movie_id AND type = 'фильм') THEN
            INSERT INTO watched_movies (movie_id, user_id, watching_date)
            VALUES (NEW.movie_id, NEW.user_id, NEW.watching_date)
            ON CONFLICT DO NOTHING;
        END IF;
    END IF;

    -- добавляем в таблицу watched_movies фильмы и сериалы, на которые был оставлен отзыв
    IF TG_TABLE_NAME = 'reviews' THEN
        INSERT INTO watched_movies (movie_id, user_id, watching_date)
        VALUES (NEW.movie_id, NEW.user_id, NEW.review_date)
        ON CONFLICT DO NOTHING; 
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_to_watched_movies() OWNER TO postgres;

--
-- Name: calculate_age(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calculate_age() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.death_date IS NOT NULL THEN
        NEW.age := EXTRACT(YEAR FROM age(NEW.death_date, NEW.birth_date));
    ELSE
        NEW.age := EXTRACT(YEAR FROM age(CURRENT_DATE, NEW.birth_date));
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.calculate_age() OWNER TO postgres;

--
-- Name: get_most_watched_movies(date, date); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_most_watched_movies(start_date date, end_date date) RETURNS TABLE(movie_id integer, title character varying, view_count integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        wm.movie_id, 
        m.title, 
        COUNT(*)::INTEGER AS view_count 
    FROM watched_movies wm
    JOIN movies m ON wm.movie_id = m.movie_id
    WHERE wm.watching_date BETWEEN start_date AND end_date
    GROUP BY wm.movie_id, m.title
    ORDER BY view_count DESC
    LIMIT 10; -- (всего в базе данных 9 фильмов и сериалов)
END;
$$;


ALTER FUNCTION public.get_most_watched_movies(start_date date, end_date date) OWNER TO postgres;

--
-- Name: get_top_new_movies(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_top_new_movies() RETURNS TABLE(movie_id integer, title character varying, year_of_production integer, user_rating numeric, description text, duration integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT m.movie_id, m.title, m.year_of_production, m.user_rating, m.description, m.duration
    FROM movies m
    WHERE m.year_of_production IN (EXTRACT(YEAR FROM CURRENT_DATE), EXTRACT(YEAR FROM CURRENT_DATE) - 1)
    ORDER BY m.user_rating DESC
    LIMIT 10;  -- (тут таких всего три)
END;
$$;


ALTER FUNCTION public.get_top_new_movies() OWNER TO postgres;

--
-- Name: increment_view_count(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.increment_view_count() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE movies
    SET view_count = view_count + 1
    WHERE movie_id = NEW.movie_id;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.increment_view_count() OWNER TO postgres;

--
-- Name: update_user_rating(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_user_rating() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE movies
    SET user_rating = (
        SELECT ROUND(AVG(rating), 1)
        FROM reviews
        WHERE movie_id = NEW.movie_id
    )
    WHERE movie_id = NEW.movie_id;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_user_rating() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: countries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.countries (
    country_id integer NOT NULL,
    country_name character varying(255) NOT NULL
);


ALTER TABLE public.countries OWNER TO postgres;

--
-- Name: countries_country_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.countries_country_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.countries_country_id_seq OWNER TO postgres;

--
-- Name: countries_country_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.countries_country_id_seq OWNED BY public.countries.country_id;


--
-- Name: country_and_movie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.country_and_movie (
    country_and_movie_id integer NOT NULL,
    country_id integer NOT NULL,
    movie_id integer NOT NULL
);


ALTER TABLE public.country_and_movie OWNER TO postgres;

--
-- Name: country_and_movie_country_and_movie_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.country_and_movie_country_and_movie_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.country_and_movie_country_and_movie_id_seq OWNER TO postgres;

--
-- Name: country_and_movie_country_and_movie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.country_and_movie_country_and_movie_id_seq OWNED BY public.country_and_movie.country_and_movie_id;


--
-- Name: genre_and_movie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genre_and_movie (
    genre_and_movie_id integer NOT NULL,
    genre_id integer NOT NULL,
    movie_id integer NOT NULL
);


ALTER TABLE public.genre_and_movie OWNER TO postgres;

--
-- Name: genre_and_movie_genre_and_movie_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genre_and_movie_genre_and_movie_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.genre_and_movie_genre_and_movie_id_seq OWNER TO postgres;

--
-- Name: genre_and_movie_genre_and_movie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genre_and_movie_genre_and_movie_id_seq OWNED BY public.genre_and_movie.genre_and_movie_id;


--
-- Name: genres; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.genres (
    genre_id integer NOT NULL,
    genre_name character varying(255) NOT NULL
);


ALTER TABLE public.genres OWNER TO postgres;

--
-- Name: genres_genre_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.genres_genre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.genres_genre_id_seq OWNER TO postgres;

--
-- Name: genres_genre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.genres_genre_id_seq OWNED BY public.genres.genre_id;


--
-- Name: history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.history (
    history_id integer NOT NULL,
    movie_id integer NOT NULL,
    video_id integer NOT NULL,
    user_id integer NOT NULL,
    watching_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    stop_time integer
);


ALTER TABLE public.history OWNER TO postgres;

--
-- Name: history_history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.history_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.history_history_id_seq OWNER TO postgres;

--
-- Name: history_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.history_history_id_seq OWNED BY public.history.history_id;


--
-- Name: moviemaker_and_movie; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.moviemaker_and_movie (
    moviemaker_and_movie_id integer NOT NULL,
    moviemaker_id integer NOT NULL,
    movie_id integer NOT NULL,
    role character varying(255) NOT NULL,
    CONSTRAINT moviemaker_and_movie_role_check CHECK (((role)::text = ANY ((ARRAY['актер'::character varying, 'режиссер'::character varying, 'сценарист'::character varying])::text[])))
);


ALTER TABLE public.moviemaker_and_movie OWNER TO postgres;

--
-- Name: moviemaker_and_movie_moviemaker_and_movie_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.moviemaker_and_movie_moviemaker_and_movie_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.moviemaker_and_movie_moviemaker_and_movie_id_seq OWNER TO postgres;

--
-- Name: moviemaker_and_movie_moviemaker_and_movie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.moviemaker_and_movie_moviemaker_and_movie_id_seq OWNED BY public.moviemaker_and_movie.moviemaker_and_movie_id;


--
-- Name: moviemakers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.moviemakers (
    moviemaker_id integer NOT NULL,
    name character varying(255) NOT NULL,
    photo character varying(255) DEFAULT NULL::character varying,
    birth_date date,
    birth_place character varying(255) DEFAULT NULL::character varying,
    death_date date,
    death_place character varying(255) DEFAULT NULL::character varying,
    age integer,
    ts_description tsvector,
    CONSTRAINT moviemakers_age_check CHECK (((age >= 0) AND (age <= 150)))
);


ALTER TABLE public.moviemakers OWNER TO postgres;

--
-- Name: moviemakers_moviemaker_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.moviemakers_moviemaker_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.moviemakers_moviemaker_id_seq OWNER TO postgres;

--
-- Name: moviemakers_moviemaker_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.moviemakers_moviemaker_id_seq OWNED BY public.moviemakers.moviemaker_id;


--
-- Name: movies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movies (
    movie_id integer NOT NULL,
    title character varying(255) NOT NULL,
    poster character varying(255) DEFAULT NULL::character varying,
    type character varying(20) NOT NULL,
    description text,
    year_of_production integer,
    age_rating character varying(5) NOT NULL,
    duration integer NOT NULL,
    user_rating numeric(3,1) DEFAULT 0.0,
    view_count integer DEFAULT 0,
    subscription_id integer DEFAULT 3,
    ts_description tsvector,
    CONSTRAINT movies_age_rating_check CHECK (((age_rating)::text = ANY ((ARRAY['0+'::character varying, '6+'::character varying, '12+'::character varying, '16+'::character varying, '18+'::character varying])::text[]))),
    CONSTRAINT movies_duration_check CHECK (((duration >= 1) AND (duration <= 999))),
    CONSTRAINT movies_type_check CHECK (((type)::text = ANY ((ARRAY['фильм'::character varying, 'сериал'::character varying])::text[]))),
    CONSTRAINT movies_user_rating_check CHECK (((user_rating >= 0.0) AND (user_rating <= 10.0))),
    CONSTRAINT movies_view_count_check CHECK ((view_count >= 0)),
    CONSTRAINT movies_year_of_production_check CHECK (((year_of_production >= 1900) AND ((year_of_production)::double precision <= date_part('year'::text, CURRENT_DATE))))
);


ALTER TABLE public.movies OWNER TO postgres;

--
-- Name: movies_movie_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.movies_movie_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.movies_movie_id_seq OWNER TO postgres;

--
-- Name: movies_movie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.movies_movie_id_seq OWNED BY public.movies.movie_id;


--
-- Name: reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reviews (
    review_id integer NOT NULL,
    user_id integer NOT NULL,
    movie_id integer NOT NULL,
    rating smallint NOT NULL,
    review_text text,
    review_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT reviews_rating_check CHECK (((rating >= 1) AND (rating <= 10)))
);


ALTER TABLE public.reviews OWNER TO postgres;

--
-- Name: reviews_review_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reviews_review_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.reviews_review_id_seq OWNER TO postgres;

--
-- Name: reviews_review_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reviews_review_id_seq OWNED BY public.reviews.review_id;


--
-- Name: subscription_types; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subscription_types (
    subscription_id integer NOT NULL,
    subscription_type character varying(50) NOT NULL,
    subscription_duration smallint NOT NULL,
    subscription_cost numeric(6,2) NOT NULL,
    CONSTRAINT subscription_types_subscription_cost_check CHECK (((subscription_cost >= 0.00) AND (subscription_cost <= 9999.99))),
    CONSTRAINT subscription_types_subscription_duration_check CHECK (((subscription_duration >= 1) AND (subscription_duration <= 365)))
);


ALTER TABLE public.subscription_types OWNER TO postgres;

--
-- Name: subscription_types_subscription_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subscription_types_subscription_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.subscription_types_subscription_id_seq OWNER TO postgres;

--
-- Name: subscription_types_subscription_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subscription_types_subscription_id_seq OWNED BY public.subscription_types.subscription_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    username character varying(255) NOT NULL,
    photo character varying(255) DEFAULT NULL::character varying,
    gender character varying(20) NOT NULL,
    registration_date date DEFAULT CURRENT_DATE,
    country character varying(255) DEFAULT NULL::character varying,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    subscription_id integer DEFAULT 3,
    subscription_start_date date DEFAULT CURRENT_DATE,
    CONSTRAINT users_gender_check CHECK (((gender)::text = ANY ((ARRAY['мужской'::character varying, 'женский'::character varying, 'не указан'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_user_id_seq OWNER TO postgres;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: video; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.video (
    video_id integer NOT NULL,
    movie_id integer NOT NULL,
    video_link character varying(255) NOT NULL,
    video_name character varying(255) NOT NULL
);


ALTER TABLE public.video OWNER TO postgres;

--
-- Name: video_video_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.video_video_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.video_video_id_seq OWNER TO postgres;

--
-- Name: video_video_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.video_video_id_seq OWNED BY public.video.video_id;


--
-- Name: watched_movies; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.watched_movies (
    watched_movie_id integer NOT NULL,
    movie_id integer NOT NULL,
    user_id integer NOT NULL,
    watching_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.watched_movies OWNER TO postgres;

--
-- Name: watched_movies_watched_movie_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.watched_movies_watched_movie_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.watched_movies_watched_movie_id_seq OWNER TO postgres;

--
-- Name: watched_movies_watched_movie_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.watched_movies_watched_movie_id_seq OWNED BY public.watched_movies.watched_movie_id;


--
-- Name: countries country_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries ALTER COLUMN country_id SET DEFAULT nextval('public.countries_country_id_seq'::regclass);


--
-- Name: country_and_movie country_and_movie_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_and_movie ALTER COLUMN country_and_movie_id SET DEFAULT nextval('public.country_and_movie_country_and_movie_id_seq'::regclass);


--
-- Name: genre_and_movie genre_and_movie_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genre_and_movie ALTER COLUMN genre_and_movie_id SET DEFAULT nextval('public.genre_and_movie_genre_and_movie_id_seq'::regclass);


--
-- Name: genres genre_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres ALTER COLUMN genre_id SET DEFAULT nextval('public.genres_genre_id_seq'::regclass);


--
-- Name: history history_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history ALTER COLUMN history_id SET DEFAULT nextval('public.history_history_id_seq'::regclass);


--
-- Name: moviemaker_and_movie moviemaker_and_movie_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moviemaker_and_movie ALTER COLUMN moviemaker_and_movie_id SET DEFAULT nextval('public.moviemaker_and_movie_moviemaker_and_movie_id_seq'::regclass);


--
-- Name: moviemakers moviemaker_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moviemakers ALTER COLUMN moviemaker_id SET DEFAULT nextval('public.moviemakers_moviemaker_id_seq'::regclass);


--
-- Name: movies movie_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies ALTER COLUMN movie_id SET DEFAULT nextval('public.movies_movie_id_seq'::regclass);


--
-- Name: reviews review_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews ALTER COLUMN review_id SET DEFAULT nextval('public.reviews_review_id_seq'::regclass);


--
-- Name: subscription_types subscription_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription_types ALTER COLUMN subscription_id SET DEFAULT nextval('public.subscription_types_subscription_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: video video_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.video ALTER COLUMN video_id SET DEFAULT nextval('public.video_video_id_seq'::regclass);


--
-- Name: watched_movies watched_movie_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watched_movies ALTER COLUMN watched_movie_id SET DEFAULT nextval('public.watched_movies_watched_movie_id_seq'::regclass);


--
-- Data for Name: countries; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.countries (country_id, country_name) FROM stdin;
1	Новая Зеландия
2	США
3	Великобритания
4	Франция
5	Россия
6	Корея Южная
7	Япония
\.


--
-- Data for Name: country_and_movie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.country_and_movie (country_and_movie_id, country_id, movie_id) FROM stdin;
1	1	1
2	2	1
3	1	2
4	2	2
5	1	3
6	2	3
7	3	4
8	4	4
9	2	4
10	2	5
11	5	6
12	5	7
13	4	8
14	6	8
15	7	8
16	2	8
17	5	9
\.


--
-- Data for Name: genre_and_movie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.genre_and_movie (genre_and_movie_id, genre_id, movie_id) FROM stdin;
1	1	1
2	2	1
3	3	1
4	4	1
5	1	2
6	2	2
7	3	2
8	4	2
9	1	3
10	2	3
11	3	3
12	4	3
13	5	4
14	3	4
15	1	5
16	4	5
17	3	5
18	6	5
19	3	6
20	1	6
21	7	7
22	8	7
23	9	7
24	10	7
25	7	8
26	1	8
27	8	8
28	4	8
29	6	8
30	2	8
31	10	8
32	3	9
33	1	9
34	6	9
\.


--
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.genres (genre_id, genre_name) FROM stdin;
1	Фэнтези
2	Приключения
3	Драма
4	Боевик
5	Ужасы
6	Мелодрама
7	Мультфильм
8	Детский
9	Комедия
10	Семейный
\.


--
-- Data for Name: history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.history (history_id, movie_id, video_id, user_id, watching_date, stop_time) FROM stdin;
1	1	1	1	2024-04-11 00:00:00	105
2	6	8	2	2024-12-06 00:00:00	50
3	2	2	3	2024-07-15 00:00:00	179
4	3	3	4	2024-03-21 00:00:00	150
5	7	11	5	2024-09-02 00:00:00	6
6	4	4	6	2024-01-11 00:00:00	85
7	1	1	7	2024-06-25 00:00:00	178
8	5	5	8	2024-11-19 00:00:00	55
9	9	17	9	2024-05-31 00:00:00	157
10	8	14	10	2024-08-09 00:00:00	20
11	2	2	4	2024-07-15 00:00:00	179
\.


--
-- Data for Name: moviemaker_and_movie; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.moviemaker_and_movie (moviemaker_and_movie_id, moviemaker_id, movie_id, role) FROM stdin;
1	1	9	актер
2	2	9	актер
3	3	9	актер
4	4	9	режиссер
5	5	9	сценарист
6	6	1	режиссер
7	7	1	сценарист
8	8	1	актер
9	9	1	актер
10	6	2	режиссер
11	7	2	сценарист
12	8	2	актер
13	6	3	режиссер
14	7	3	сценарист
15	8	3	актер
16	9	3	актер
17	6	1	сценарист
\.


--
-- Data for Name: moviemakers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.moviemakers (moviemaker_id, name, photo, birth_date, birth_place, death_date, death_place, age, ts_description) FROM stdin;
1	Аугуст Диль	https://avatars.mds.yandex.net/get-kinopoisk-image/4303601/a7d7c595-fb7a-4205-98be-fb80e8730c0e/280x420	1976-01-04	Берлин, Германия	\N	\N	48	'аугуст':1 'дил':2
2	Юлия Снигирь	https://avatars.mds.yandex.net/get-kinopoisk-image/4774061/588243ab-6db0-4bd4-b285-106ae93e42ea/280x420	1983-06-02	Донской, Тульская область, СССР	\N	\N	41	'снигир':2 'юл':1
3	Евгений Цыганов	https://avatars.mds.yandex.net/get-kinopoisk-image/1777765/60829cde-1c2f-40f4-953f-f065e875c6b9/280x420	1979-03-15	Москва, СССР	\N	\N	45	'евген':1 'цыган':2
4	Михаил Локшин	https://avatars.mds.yandex.net/get-kinopoisk-image/4774061/1a1d5708-8d05-4a05-b64f-c77bc2bd7065/280x420	1981-06-14	США	\N	\N	43	'локшин':2 'миха':1
5	Роман Канто	https://avatars.mds.yandex.net/get-kinopoisk-image/1629390/34dda915-607d-468c-aec9-35655fdf0390/280x420	1984-04-29	Находка, СССР	\N	\N	40	'кант':2 'рома':1
6	Питер Джексон	https://avatars.mds.yandex.net/get-kinopoisk-image/1777765/489b2e6a-555c-40c2-82c3-942adee761e8/280x420	1961-10-31	Пукеруа Бэй, Новая Зеландия	\N	\N	63	'джексон':2 'питер':1
7	Фрэн Уолш	https://avatars.mds.yandex.net/get-kinopoisk-image/1777765/a258617d-ed09-46db-8eb0-521648e37a78/280x420	1959-01-10	Уэллингтон, Новая Зеландия	\N	\N	65	'уолш':2 'фрэн':1
8	Элайджа Вуд	https://avatars.mds.yandex.net/get-kinopoisk-image/4486454/5de2bdc6-b1fc-4c7a-8e91-71b869c4936d/280x420	1981-01-28	Сидар-Рапидс, Айова, США	\N	\N	43	'вуд':2 'элайдж':1
9	Иэн Холм	https://avatars.mds.yandex.net/get-kinopoisk-image/1898899/c92e8963-6676-4697-843d-e2a01405474d/280x420	1931-09-12	Гудмайес, Эссекс, Англия, Великобритания	2020-06-19	Лондон, Великобритания	88	'иэн':1 'холм':2
\.


--
-- Data for Name: movies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.movies (movie_id, title, poster, type, description, year_of_production, age_rating, duration, user_rating, view_count, subscription_id, ts_description) FROM stdin;
2	Властелин колец: Две крепости 	https://avatars.mds.yandex.net/get-kinopoisk-image/1599028/927d885e-ee18-4636-89d4-311bdcd9de0c/1920x	фильм	Братство распалось, но Кольцо Всевластья должно быть уничтожено...	2002	12+	179	10.0	2	2	'властелин':1 'две':3 'колец':2 'крепост':4
6	Король и Шут	https://avatars.mds.yandex.net/get-kinopoisk-image/6201401/1485ac9a-7796-470b-a3eb-85dc725d4ec0/300x450	сериал	Горшок, Князь и Шут — герои панк-сказки, в которой студенты реставрационного училища стали одной из главных рок-групп страны...	2023	18+	50	9.0	1	2	'корол':1 'шут':3
3	Властелин колец: Возвращение короля	https://avatars.mds.yandex.net/get-kinopoisk-image/4303601/e410c71f-baa1-4fe5-bb29-aedb4662f49b/300x450	фильм	Повелитель сил тьмы Саурон направляет свою бесчисленную армию под стены Минас-Тирита, крепости Последней Надежды…	2003	12+	179	8.0	1	2	'властелин':1 'возвращен':3 'колец':2 'корол':4
7	Смешарики	https://avatars.mds.yandex.net/get-kinopoisk-image/1898899/e46541cf-e9c0-429f-a8a7-2d427f1b7d22/300x450	сериал	Истории о дружбе и приключениях обаятельных круглых героев…	2003	0+	6	9.3	4	1	'смешарик':1
4	Субстанция	https://avatars.mds.yandex.net/get-kinopoisk-image/10703959/49123e40-fc14-4849-8d0a-aca4ed2bb0bb/300x450	фильм	Слава голливудской звезды Элизабет Спаркл осталась в прошлом, хотя она всё ещё ведёт фитнес-шоу на телевидении...	2024	18+	141	6.0	1	2	'субстанц':1
1	Властелин колец: Братство кольца 	https://avatars.mds.yandex.net/get-kinopoisk-image/6201401/a2d5bcae-a1a9-442f-8195-f5373a5ba77f/300x450	фильм	Сказания о Средиземье — это хроника Великой войны за Кольцо, длившейся не одну тысячу лет…	2001	12+	178	9.5	2	1	'братств':3 'властелин':1 'колец':2 'кольц':4
5	Дом Дракона	https://avatars.mds.yandex.net/get-kinopoisk-image/10592371/e81636b8-fb18-44fb-9074-11fffe9cfc4a/300x450	сериал	После смерти короля Визериса династия Таргариенов начинает бескомпромиссную борьбу за Железный трон…	2022	18+	60	7.0	1	4	'дом':1 'дракон':2
9	Мастер и Маргарита	https://avatars.mds.yandex.net/get-kinopoisk-image/10900341/fcff003a-9e57-4791-a38a-65acc18c99db/300x450	фильм	Москва, 1930-е годы. Популярный драматург обвиняется в антисоветчине: спектакль по его пьесе отменяют, а самого его выгоняют из союза литераторов…	2023	18+	157	7.0	1	4	'маргарит':3 'мастер':1
8	Леди Баг и Супер-Кот	https://avatars.mds.yandex.net/get-kinopoisk-image/10893610/a27fdbd4-b0f3-46b3-8f57-90f3d9e20fe5/300x450	сериал	С виду обычные старшеклассники Адриан и Маринетт при малейшей угрозе Парижу становятся Леди Баг и Супер-котом…	2015	6+	20	8.0	1	2	'баг':2 'кот':6 'лед':1 'супер':5 'супер-кот':4
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reviews (review_id, user_id, movie_id, rating, review_text, review_date) FROM stdin;
1	1	1	9	Потрясающая атмосфера и захватывающая история. Хотелось бы больше деталей о персонажах.	2024-04-11 03:45:22
2	2	6	9	Отличная атмосфера и актерская игра. Приятно удивлена уровнем исполнения.	2024-12-06 12:18:39
3	3	2	10	Эпические сражения и невероятные визуальные эффекты! Один из лучших фильмов.	2024-07-15 21:02:11
4	4	3	8	Финал трилогии восхитителен, но немного затянуто. В целом шикарная работа.	2024-03-21 06:57:56
5	5	7	10	Настоящий шедевр для детей и взрослых! Весело и поучительно. Любимый мультфильм.	2024-09-02 14:30:10
6	6	4	6	Идея интересная, но реализация местами провисает. Можно было лучше раскрыть сюжет.	2024-01-11 19:11:05
7	7	1	10	Классика! Этот фильм не стареет и остается эталоном жанра фэнтези.	2024-06-25 02:42:29
8	8	5	7	Красивая картинка и интриги, но слишком затянуто. Есть потенциал, но не шедевр.	2024-11-19 09:15:47
9	9	9	7	Визуально красиво, но не дотягивает до книги. Некоторые моменты запутаны.	2024-05-31 17:58:33
10	10	8	8	Забавный и яркий мультфильм, но местами сюжет немного предсказуем.	2024-08-09 23:06:54
11	2	7	10	Смешарики — это всегда радость и улыбки! Умный юмор, яркие персонажи и поучительные истории.	2024-12-23 10:12:45
12	6	7	9	Очень позитивный и добрый мультфильм. Идеально подходит для семейного просмотра. Копатыч просто лучший!	2024-12-23 11:04:30
13	8	7	8	Интересные приключения, но иногда чувствуется, что серии коротковаты. Хотелось бы больше развития сюжета.	2024-12-23 11:45:12
\.


--
-- Data for Name: subscription_types; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.subscription_types (subscription_id, subscription_type, subscription_duration, subscription_cost) FROM stdin;
1	Бесплатная	365	0.00
2	Стандартная	30	299.00
3	Стандартная	365	2999.00
4	Премиум	30	499.00
5	Премиум	365	4999.00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, username, photo, gender, registration_date, country, email, password, subscription_id, subscription_start_date) FROM stdin;
1	Иван Иванов	\N	мужской	2023-04-11	Россия	ivan.ivanov@mail.ru	ivan2023!	4	2023-04-11
2	Мария Петрова	\N	женский	2022-12-06	Россия	maria.petrovna@mail.ru	maria#2022	2	2022-12-06
3	Дмитрий Кузнецов	\N	мужской	2023-07-15	Россия	d.kuznetsov@mail.ru	dmitryStrong01	1	2023-07-15
4	Ольга Сидорова	\N	женский	2023-03-21	Россия	olga.sidorova@mail.ru	olgaSafe2023	4	2024-03-21
5	Алексей Смирнов	\N	мужской	2021-09-02	Россия	alexey.smirnov@mail.ru	alexey#0901	4	2021-09-02
6	Екатерина Орлова	\N	женский	2023-01-11	Россия	ekaterina.orlova@mail.ru	kateOrlova2023	2	2023-01-11
7	Сергей Федоров	\N	мужской	2023-06-25	Россия	sergey.fedorov@mail.ru	sergeyStrong25	1	2023-06-25
8	Анна Никитина	\N	женский	2022-11-19	Россия	anna.nikitina@mail.ru	annaSecure!18	1	2022-11-19
9	Владимир Егоров	\N	мужской	2023-05-31	Россия	vladimir.egorov@mail.ru	vladSafe2023!	1	2023-05-31
10	Елена Тихонова	\N	женский	2023-08-09	Россия	elena.tikhonova@mail.ru	elena#808	2	2024-08-09
\.


--
-- Data for Name: video; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.video (video_id, movie_id, video_link, video_name) FROM stdin;
1	1	https://www.kinopoisk.ru/film/328/	Видео Властелин колец: Братство кольца
2	2	https://www.kinopoisk.ru/film/328/	Видео Властелин колец: Две крепости
3	3	https://www.kinopoisk.ru/film/3498/	Видео Властелин колец: Возвращение короля
4	4	https://www.kinopoisk.ru/film/4860213/	Видео Субстанция
5	5	https://www.kinopoisk.ru/series/1316601/	Сериал Дом Дракона (серия 1)
6	5	https://www.kinopoisk.ru/series/1316601/	Сериал Дом Дракона (серия 2)
7	5	https://www.kinopoisk.ru/series/1316601/	Сериал Дом Дракона (серия 3)
8	6	https://www.kinopoisk.ru/series/4647040/	Сериал Король и Шут (серия 1)
9	6	https://www.kinopoisk.ru/series/4647040/	Сериал Король и Шут (серия 2)
10	6	https://www.kinopoisk.ru/series/4647040/	Сериал Король и Шут (серия 3)
11	7	https://www.kinopoisk.ru/series/256124/	Сериал Смешарики (серия 1)
12	7	https://www.kinopoisk.ru/series/256124/	Сериал Смешарики (серия 2)
13	7	https://www.kinopoisk.ru/series/256124/	Сериал Смешарики (серия 3)
14	8	https://www.kinopoisk.ru/series/958607/	Сериал Леди Баг и Супер-Кот (серия 1)
15	8	https://www.kinopoisk.ru/series/958607/	Сериал Леди Баг и Супер-Кот (серия 2)
16	8	https://www.kinopoisk.ru/series/958607/	Сериал Леди Баг и Супер-Кот (серия 3)
17	9	https://www.kinopoisk.ru/lists/movies/year--2023/?b=films	Видео Мастер и Маргарита
\.


--
-- Data for Name: watched_movies; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.watched_movies (watched_movie_id, movie_id, user_id, watching_date) FROM stdin;
1	1	1	2024-04-11 03:45:22
2	6	2	2024-12-06 12:18:39
3	2	3	2024-07-15 21:02:11
4	3	4	2024-03-21 06:57:56
5	7	5	2024-09-02 14:30:10
6	4	6	2024-01-11 19:11:05
7	1	7	2024-06-25 02:42:29
8	5	8	2024-11-19 09:15:47
9	9	9	2024-05-31 17:58:33
10	8	10	2024-08-09 23:06:54
14	2	4	2024-07-15 00:00:00
15	7	2	2024-12-23 10:12:45
16	7	6	2024-12-23 11:04:30
17	7	8	2024-12-23 11:45:12
\.


--
-- Name: countries_country_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.countries_country_id_seq', 7, true);


--
-- Name: country_and_movie_country_and_movie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.country_and_movie_country_and_movie_id_seq', 17, true);


--
-- Name: genre_and_movie_genre_and_movie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.genre_and_movie_genre_and_movie_id_seq', 34, true);


--
-- Name: genres_genre_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.genres_genre_id_seq', 10, true);


--
-- Name: history_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.history_history_id_seq', 11, true);


--
-- Name: moviemaker_and_movie_moviemaker_and_movie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.moviemaker_and_movie_moviemaker_and_movie_id_seq', 17, true);


--
-- Name: moviemakers_moviemaker_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.moviemakers_moviemaker_id_seq', 9, true);


--
-- Name: movies_movie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.movies_movie_id_seq', 9, true);


--
-- Name: reviews_review_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reviews_review_id_seq', 13, true);


--
-- Name: subscription_types_subscription_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.subscription_types_subscription_id_seq', 5, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.users_user_id_seq', 1, false);


--
-- Name: video_video_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.video_video_id_seq', 17, true);


--
-- Name: watched_movies_watched_movie_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.watched_movies_watched_movie_id_seq', 17, true);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (country_id);


--
-- Name: country_and_movie country_and_movie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_and_movie
    ADD CONSTRAINT country_and_movie_pkey PRIMARY KEY (country_and_movie_id);


--
-- Name: genre_and_movie genre_and_movie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genre_and_movie
    ADD CONSTRAINT genre_and_movie_pkey PRIMARY KEY (genre_and_movie_id);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);


--
-- Name: history history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_pkey PRIMARY KEY (history_id);


--
-- Name: moviemaker_and_movie moviemaker_and_movie_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moviemaker_and_movie
    ADD CONSTRAINT moviemaker_and_movie_pkey PRIMARY KEY (moviemaker_and_movie_id);


--
-- Name: moviemakers moviemakers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moviemakers
    ADD CONSTRAINT moviemakers_pkey PRIMARY KEY (moviemaker_id);


--
-- Name: movies movies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies
    ADD CONSTRAINT movies_pkey PRIMARY KEY (movie_id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (review_id);


--
-- Name: subscription_types subscription_types_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription_types
    ADD CONSTRAINT subscription_types_pkey PRIMARY KEY (subscription_id);


--
-- Name: country_and_movie unique_country_movie; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_and_movie
    ADD CONSTRAINT unique_country_movie UNIQUE (country_id, movie_id);


--
-- Name: countries unique_country_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT unique_country_name UNIQUE (country_name);


--
-- Name: genre_and_movie unique_genre_movie; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genre_and_movie
    ADD CONSTRAINT unique_genre_movie UNIQUE (genre_id, movie_id);


--
-- Name: genres unique_genre_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT unique_genre_name UNIQUE (genre_name);


--
-- Name: watched_movies unique_movie_video_user; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watched_movies
    ADD CONSTRAINT unique_movie_video_user UNIQUE (movie_id, user_id);


--
-- Name: moviemaker_and_movie unique_moviemaker_movie_role; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moviemaker_and_movie
    ADD CONSTRAINT unique_moviemaker_movie_role UNIQUE (moviemaker_id, movie_id, role);


--
-- Name: moviemakers unique_name_birth_date; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moviemakers
    ADD CONSTRAINT unique_name_birth_date UNIQUE (name, birth_date);


--
-- Name: subscription_types unique_subscription_type_duration; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subscription_types
    ADD CONSTRAINT unique_subscription_type_duration UNIQUE (subscription_type, subscription_duration);


--
-- Name: movies unique_title_year; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies
    ADD CONSTRAINT unique_title_year UNIQUE (title, year_of_production);


--
-- Name: reviews unique_user_movie_review; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT unique_user_movie_review UNIQUE (user_id, movie_id);


--
-- Name: users unique_username_email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT unique_username_email UNIQUE (username, email);


--
-- Name: history unique_video_movie; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT unique_video_movie UNIQUE (video_id, user_id, watching_date);


--
-- Name: video unique_video_name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.video
    ADD CONSTRAINT unique_video_name UNIQUE (video_name);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: video video_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.video
    ADD CONSTRAINT video_pkey PRIMARY KEY (video_id);


--
-- Name: watched_movies watched_movies_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watched_movies
    ADD CONSTRAINT watched_movies_pkey PRIMARY KEY (watched_movie_id);


--
-- Name: reviews add_review_to_watched; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER add_review_to_watched AFTER INSERT ON public.reviews FOR EACH ROW EXECUTE PROCEDURE public.add_to_watched_movies();


--
-- Name: moviemakers before_moviemakers_insert_or_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER before_moviemakers_insert_or_update BEFORE INSERT OR UPDATE ON public.moviemakers FOR EACH ROW EXECUTE PROCEDURE public.calculate_age();


--
-- Name: history check_history_completion; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER check_history_completion AFTER INSERT OR UPDATE ON public.history FOR EACH ROW EXECUTE PROCEDURE public.add_to_watched_movies();


--
-- Name: reviews recalculate_user_rating; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER recalculate_user_rating AFTER INSERT ON public.reviews FOR EACH ROW EXECUTE PROCEDURE public.update_user_rating();


--
-- Name: watched_movies update_view_count; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER update_view_count AFTER INSERT ON public.watched_movies FOR EACH ROW EXECUTE PROCEDURE public.increment_view_count();


--
-- Name: country_and_movie country_and_movie_country_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_and_movie
    ADD CONSTRAINT country_and_movie_country_id_fkey FOREIGN KEY (country_id) REFERENCES public.countries(country_id);


--
-- Name: country_and_movie country_and_movie_movie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.country_and_movie
    ADD CONSTRAINT country_and_movie_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(movie_id);


--
-- Name: genre_and_movie genre_and_movie_genre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genre_and_movie
    ADD CONSTRAINT genre_and_movie_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id);


--
-- Name: genre_and_movie genre_and_movie_movie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.genre_and_movie
    ADD CONSTRAINT genre_and_movie_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(movie_id);


--
-- Name: history history_movie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(movie_id);


--
-- Name: history history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: history history_video_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.history
    ADD CONSTRAINT history_video_id_fkey FOREIGN KEY (video_id) REFERENCES public.video(video_id);


--
-- Name: moviemaker_and_movie moviemaker_and_movie_movie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moviemaker_and_movie
    ADD CONSTRAINT moviemaker_and_movie_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(movie_id);


--
-- Name: moviemaker_and_movie moviemaker_and_movie_moviemaker_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.moviemaker_and_movie
    ADD CONSTRAINT moviemaker_and_movie_moviemaker_id_fkey FOREIGN KEY (moviemaker_id) REFERENCES public.moviemakers(moviemaker_id);


--
-- Name: movies movies_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movies
    ADD CONSTRAINT movies_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscription_types(subscription_id);


--
-- Name: reviews reviews_movie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(movie_id);


--
-- Name: reviews reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: users users_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.subscription_types(subscription_id);


--
-- Name: video video_movie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.video
    ADD CONSTRAINT video_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(movie_id);


--
-- Name: watched_movies watched_movies_movie_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watched_movies
    ADD CONSTRAINT watched_movies_movie_id_fkey FOREIGN KEY (movie_id) REFERENCES public.movies(movie_id);


--
-- Name: watched_movies watched_movies_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.watched_movies
    ADD CONSTRAINT watched_movies_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- PostgreSQL database dump complete
--

