WITH country_name AS (
  SELECT 'Singapore' AS value
-- 'United States of America' AS value
),
last_updated AS (
  SELECT
    MAX(last_updated) AS value
  FROM `bigquery-public-data.worldpop.population_grid_1km` AS pop
    INNER JOIN country_name ON (pop.country_name = country_name.value)
),

population AS (
  SELECT
    SUM(sum_population) AS sum_population,
    ST_CONVEXHULL(st_union_agg(centr)) AS boundingbox
  FROM (
    SELECT
      SUM(population) AS sum_population,
      ST_CENTROID_AGG(ST_GEOGPOINT(longitude_centroid, latitude_centroid)) AS centr
    FROM
      `bigquery-public-data.worldpop.population_grid_1km` AS pop
      INNER JOIN country_name ON (pop.country_name = country_name.value)
      INNER JOIN last_updated ON (pop.last_updated = last_updated.value)
    GROUP BY SUBSTR(geo_id, 1, 6)
  )
),
hospitals AS (
  SELECT
    layer.geometry
  FROM
    `bigquery-public-data.geo_openstreetmap.planet_layers` AS layer
    INNER JOIN population ON ST_INTERSECTS(population.boundingbox, layer.geometry)
  WHERE
    -- See: https://download.geofabrik.de/osm-data-in-gis-formats-free.pdf
    -- BETWEEN 2100 AND 2199 # "health"
    -- = 2101                # "pharmacy"
    -- = 2110                # "hospital"
    -- = 2120                # "doctors"
    -- = 2121                # "dentist"
    -- = 2129                # "veterinary"
    layer.layer_code in (2110, 2120) --TODO
),
distances AS (
  SELECT
    pop.geo_id,
    pop.population,
    MIN(ST_DISTANCE(pop.geog, hospitals.geometry)) AS distance
  FROM
    `bigquery-public-data.worldpop.population_grid_1km` AS pop
      INNER JOIN country_name ON pop.country_name = country_name.value
      INNER JOIN last_updated ON pop.last_updated = last_updated.value  
      CROSS JOIN hospitals
  WHERE pop.population > 0
  GROUP BY geo_id, population
)

SELECT
  pd.distance,
  SUM(pd.population) AS population,
  SUM(pd.population)/p.sum_population AS pct_population
FROM
  distances pd
    CROSS JOIN population p
GROUP BY distance, sum_population
ORDER BY distance
