CREATE database youtube;
\connect youtube
CREATE SCHEMA stats;

CREATE TABLE youtube.stats.channels(
  serial CHAR(24) PRIMARY KEY NOT NULL
);
CREATE UNIQUE INDEX channels_serial_uindex ON youtube.stats.channels (serial);

CREATE TABLE youtube.stats.chan_subs
(
  time timestamptz DEFAULT now() NOT NULL,
  serial char(24) NOT NULL,
  subs bigint NOT NULL
);

SELECT create_hypertable('youtube.stats.chan_subs', 'time', 'serial', 32767);

CREATE TABLE youtube.stats.chan_videos
(
  time timestamptz DEFAULT now() NOT NULL,
  serial char(24) NOT NULL,
  videos int NOT NULL
);

SELECT create_hypertable('youtube.stats.chan_videos', 'time', 'serial', 32767);

CREATE TABLE youtube.stats.chan_views
(
  time timestamptz DEFAULT now() NOT NULL,
  serial char(24) NOT NULL,
  views bigint NOT NULL
);

SELECT create_hypertable('youtube.stats.chan_views', 'time', 'serial', 32767);

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
