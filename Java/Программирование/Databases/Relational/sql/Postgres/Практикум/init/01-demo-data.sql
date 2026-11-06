-- Демо-данные для лабораторок.
-- Объём подобран так, чтобы инициализация занимала секунды,
-- но планы уже были «взрослыми» (seq scan vs index scan видно отчётливо).

SET search_path = lab, public;

CREATE SCHEMA IF NOT EXISTS lab;

-- ---------------------------------------------------------------------------
-- users: 100 000 строк
-- country и locale специально коррелируют (для лабораторки по кардинальности)
-- ---------------------------------------------------------------------------
CREATE TABLE lab.users (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  email       text        NOT NULL,
  country     text        NOT NULL,
  locale      text        NOT NULL,
  is_active   boolean     NOT NULL,
  created_at  timestamptz NOT NULL
);

INSERT INTO lab.users (email, country, locale, is_active, created_at)
SELECT 'user' || g || '@example.com',
       c.country,
       c.locale,
       (g % 10 <> 0),                       -- 90% активных
       now() - (random() * interval '730 days')
FROM generate_series(1, 100000) g
JOIN (VALUES ('RU','ru-RU'), ('US','en-US'), ('DE','de-DE'),
             ('BR','pt-BR'), ('IN','en-IN')) AS c(country, locale)
  ON c.country = (ARRAY['RU','US','DE','BR','IN'])[1 + (g % 5)];

-- ---------------------------------------------------------------------------
-- orders: 1 000 000 строк, перекошенный status (80/15/5)
-- ---------------------------------------------------------------------------
CREATE TABLE lab.orders (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id     bigint        NOT NULL REFERENCES lab.users(id),
  status      text          NOT NULL,
  total       numeric(12,2) NOT NULL,
  created_at  timestamptz   NOT NULL,
  payload     text
);

INSERT INTO lab.orders (user_id, status, total, created_at, payload)
SELECT 1 + (random() * 99999)::bigint,
       CASE
         WHEN random() < 0.80 THEN 'paid'
         WHEN random() < 0.75 THEN 'new'
         ELSE 'cancelled'
       END,
       round((random() * 1000)::numeric, 2),
       now() - (random() * interval '365 days'),
       md5(random()::text)
FROM generate_series(1, 1000000) g;

-- ---------------------------------------------------------------------------
-- events: 200 000 строк с jsonb (для GIN)
-- ---------------------------------------------------------------------------
CREATE TABLE lab.events (
  id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id     bigint      NOT NULL,
  kind        text        NOT NULL,
  data        jsonb       NOT NULL,
  created_at  timestamptz NOT NULL
);

INSERT INTO lab.events (user_id, kind, data, created_at)
SELECT 1 + (random() * 99999)::bigint,
       (ARRAY['click','view','purchase','signup'])[1 + floor(random() * 4)::int],
       jsonb_build_object(
         'status', (ARRAY['new','paid','cancelled'])[1 + (random() * 2)::int],
         'amount', round((random() * 500)::numeric, 2),
         'source', (ARRAY['web','ios','android'])[1 + (random() * 2)::int]
       ),
       now() - (random() * interval '180 days')
FROM generate_series(1, 200000);

-- ---------------------------------------------------------------------------
-- Индексы: часть есть сразу, часть создаётся в лабораторках
-- ---------------------------------------------------------------------------
CREATE INDEX orders_user_created_idx ON lab.orders (user_id, created_at DESC);
CREATE INDEX orders_created_idx      ON lab.orders (created_at);

CREATE INDEX events_data_gin ON lab.events USING gin (data jsonb_path_ops);
CREATE INDEX events_kind_idx ON lab.events (kind);

ANALYZE lab.users;
ANALYZE lab.orders;
ANALYZE lab.events;

SELECT pg_stat_statements_reset();
