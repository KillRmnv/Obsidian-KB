-- Расширения, которые нужны для лабораторок.
-- Выполняется автоматически при первом старте контейнера.

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS pgstattuple;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pageinspect;
CREATE EXTENSION IF NOT EXISTS pg_visibility;
CREATE EXTENSION IF NOT EXISTS amcheck;

-- hypopg в официальный образ не входит — см. заметку «Расширения по теме».
