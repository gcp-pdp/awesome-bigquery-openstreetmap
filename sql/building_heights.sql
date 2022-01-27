WITH cities AS (
  SELECT geometry
  FROM `bigquery-public-data.geo_openstreetmap.planet_layers` JOIN UNNEST(all_tags) AS tags
  WHERE layer_name = 'city'
  AND tags.key = 'name'
  AND tags.value = 'New York'
)
SELECT ST_CENTROID(objs.geometry) AS centroid, objs.geometry, SAFE_CAST(tags.value AS INT64) AS levels
FROM `bigquery-public-data.geo_openstreetmap.planet_layers` AS objs JOIN UNNEST(all_tags) AS tags, cities
WHERE layer_class = 'building'
  AND EXISTS (SELECT key FROM UNNEST(all_tags) WHERE key = 'building:levels')
  AND tags.key = 'building:levels'
  AND tags.value IS NOT NULL
  AND ST_WITHIN(objs.geometry, cities.geometry)

