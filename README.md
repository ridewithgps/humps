# Humps and Stuffs

Humps takes all the difficulty out of working with DEM files.

Humps expects your DEMs to be GridFloat, which is a simple binary grid of elevation values in row major order (x,y origin is upper left).  Looking up a specific elevation value is simple when you know the cellsize, number of cells and min lat/lng of each file.

This library is in use at [ridewithgps](http://ridewithgps.com) and is tailored towards our elevation datasets.  Meaning, there are a bunch of hardcoded things in here that may or may not apply to your elevation dataset. For example, we just updated our SRTM dataset and the number of rows/columns in each tile changed, necessitating the change of some hardcoded values used to lookup header files.  At some point that stuff will all be extracted out or made generic, but that day is not today.

# Run locally with Docker

```bash
docker build --no-cache -t humps -f Dockerfile.development .
docker run -it --rm --name humps -v ./server:/var/www/humps/current/server -p 127.0.0.1:4002:4002 humps
```

## GeoIP

Humps also does GeoIP queries using MaxMind's GeoIP2 City database [found here](https://www.maxmind.com/en/geoip2-city). The database is a binary file and needs to be manually added here: `server/db/geo-ip.mmdb`.

#### Request

`GET http://localhost:4002/geoip/74.120.152.136`

***Note:** The database supports both IPv4 and IPv6*

#### Response

```json
{
  "country_code": "US",
  "country": "United States",
  "admin_area": "Oregon",
  "admin_area_code": "OR",
  "city": "Portland",
  "lat": 45.5173,
  "lng": -122.6398
}
```
