CREATE database youtube;
\connect youtube
CREATE SCHEMA stats;

CREATE TABLE youtube.stats.channels(
  serial CHAR(24) PRIMARY KEY NOT NULL
);
CREATE UNIQUE INDEX channels_serial_uindex ON youtube.stats.channels (serial);

CREATE TABLE youtube.stats.subs
(
    time TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    serial CHAR(24) NOT NULL,
    subs BIGSERIAL NOT NULL
);

SELECT create_hypertable('youtube.stats.subs', 'time', 'serial', 8);

CREATE TABLE youtube.stats.views
(
    time TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    serial CHAR(24) NOT NULL,
    views BIGSERIAL NOT NULL
);

SELECT create_hypertable('youtube.stats.views', 'time', 'serial', 8);

CREATE TABLE youtube.stats.videos
(
    time TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    serial CHAR(24) NOT NULL,
    videos BIGSERIAL NOT NULL
);

SELECT create_hypertable('youtube.stats.videos', 'time', 'serial', 8);

create view space_usage as SELECT *, pg_size_pretty(total_bytes) AS total
 , pg_size_pretty(index_bytes) AS INDEX
 , pg_size_pretty(toast_bytes) AS toast
 , pg_size_pretty(table_bytes) AS TABLE
 FROM (
SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes FROM (
SELECT c.oid,nspname AS table_schema, relname AS TABLE_NAME
, c.reltuples AS row_estimate
, pg_total_relation_size(c.oid) AS total_bytes
, pg_indexes_size(c.oid) AS index_bytes
, pg_total_relation_size(reltoastrelid) AS toast_bytes
FROM pg_class c
 LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relkind = 'r'
) a
) a order by total_bytes desc;
