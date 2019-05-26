CREATE database youtube;
\connect youtube
CREATE SCHEMA stats;

CREATE TABLE youtube.stats.channels
(
    id SERIAL PRIMARY KEY NOT NULL,
    serial CHAR(24) NOT NULL
);

CREATE UNIQUE INDEX channels_id_uindex
    ON youtube.stats.channels (id);

CREATE UNIQUE INDEX channels_serial_uindex
    ON youtube.stats.channels (serial);

CREATE TABLE youtube.stats.metric_subs
(
    time TIMESTAMPTZ DEFAULT NOW() PRIMARY KEY NOT NULL,
    channel_id SERIAL NOT NULL
        CONSTRAINT metrics_channels_id_fk
            REFERENCES youtube.stats.channels
            ON DELETE CASCADE,
    subs youtube.stats.uint4 NOT NULL
);

CREATE UNIQUE INDEX metric_subs_time_uindex
    ON youtube.stats.metric_subs (time);

SELECT create_hypertable('youtube.stats.metric_subs', 'time');

CREATE TABLE youtube.stats.metric_views
(
    time TIMESTAMPTZ DEFAULT NOW() PRIMARY KEY NOT NULL,
    channel_id SERIAL NOT NULL
        CONSTRAINT metrics_channels_id_fk
            REFERENCES youtube.stats.channels
            ON DELETE CASCADE,
    views youtube.stats.uint8 NOT NULL
);

CREATE UNIQUE INDEX metric_views_time_uindex
    ON youtube.stats.metric_views (time);

SELECT create_hypertable('youtube.stats.metric_views', 'time');

CREATE TABLE youtube.stats.metric_videos
(
    time TIMESTAMPTZ DEFAULT NOW() PRIMARY KEY NOT NULL,
    channel_id SERIAL NOT NULL
        CONSTRAINT metrics_channels_id_fk
            REFERENCES youtube.stats.channels
            ON DELETE CASCADE,
    videos youtube.stats.uint4 NOT NULL
);

CREATE UNIQUE INDEX metric_videos_time_uindex
    ON youtube.stats.metric_videos (time);

SELECT create_hypertable('youtube.stats.metric_videos', 'time');

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
