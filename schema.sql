CREATE database youtube;
\connect youtube
CREATE SCHEMA stats;

CREATE TABLE youtube.stats.channels
(
    id SERIAL PRIMARY KEY NOT NULL,
    serial CHAR(24) NOT NULL
);

CREATE UNIQUE INDEX channels_id_uindex
    ON stats.channels (id);

CREATE UNIQUE INDEX channels_serial_uindex
    ON stats.channels (serial);

CREATE TABLE stats.metrics
(
    time TIMESTAMPTZ DEFAULT NOW() PRIMARY KEY NOT NULL,
    channel_id SERIAL NOT NULL
        CONSTRAINT metrics_channels_id_fk
            REFERENCES stats.channels
            ON DELETE CASCADE,
    subs stats.uint4 NOT NULL,
    views stats.uint8 NOT NULL,
    videos stats.uint4 NOT NULL
);

CREATE UNIQUE INDEX metrics_time_uindex
    ON stats.metrics (time);

SELECT create_hypertable('youtube.stats.metrics', 'time');

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
