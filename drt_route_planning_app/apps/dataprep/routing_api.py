import pandas as pd
import requests
import datetime
import json
from apps.dataprep import preproc 

token = preproc.token

routing_res_df = pd.DataFrame()
route_json = {}

def create_driving_route(row):
    """Get route JSON."""
    global route_json
    route_json = {}
    base_url = 'https://api.mapbox.com/directions/v5/mapbox/driving/'
    url = None
    url = base_url + str(row['origin_longitude']) + \
        ',' + str(row['origin_latitude']) + \
        ';' + str(row['destination_longitude']) + \
        ',' + str(row['destination_latitude'])
    params = {
        'geometries': 'geojson',
        'access_token': token
    }
    req = requests.get(url, params=params)
    route_json = req.json()['routes'][0]
    # create a friendly result df with distance and travelling time
    to_add = [route_json['duration'], route_json['distance']]
    global routing_res_df
    routing_res_df = pd.DataFrame(columns = ['Fahrzeit_zwischen_Haltestellen', 'Distanz_zwischen_Haltestellen_in_mt'])
    #routing_res_df['Fahrzeit_zwischen_Haltestellen'] = pd.to_datetime(routing_res_df['Fahrzeit_zwischen_Haltestellen'], format='%H:%M:%S')
    routing_res_df.loc[0] = to_add
    routing_res_df.to_csv("routing_res_df.csv")
    return routing_res_df