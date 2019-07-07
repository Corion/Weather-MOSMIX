-- SQL DDL for creating the weather database
-- currently we need the JSON1 extensioin for SQLite (built-in with most SQLite libs since 3.9)
create table forecast (
      latitude double
    , longitude double
    , name varchar(64) not null unique primary key
    , description varchar(128) not null
    , forecasts varchar(65536) -- we store the parsed forecasts as JSON instead of row(s) currently
    -- as I don't imagine that we'll every query for them instead of locations
);

-- here we will store the last requests, which we will use to extract
-- and cache the forecasts around, instead of keeping all forecasts around
create forecast_requests (
      last_requested_at datetime not null
    , latitude double
    , longitude double
);