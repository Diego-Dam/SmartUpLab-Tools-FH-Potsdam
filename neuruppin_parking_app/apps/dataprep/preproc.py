# data manipulation
import pandas as pd
import geopandas as gpd
import numpy as np
from datetime import datetime

# managing the app folder structure
import pathlib

# data import and connection to postgis
import psycopg2
from sqlalchemy import create_engine, inspect
import base64
from flask_sqlalchemy import SQLAlchemy

# dash
from dash import html
from dash import dcc

# Connect to main app.py file
from app import app 

##############
##  Styling ##
##############
colors = {
    'background': '#ffffff', #white
    'background_buttons': '#d3d3d3', # light grey
    'alert': '#e01414', # deep red
    'text': '#444444' # dark grey
}

blackbold={
    'color':'black',
    'font-weight': 'bold'
}

small_font = '6px'

# define colors
inhabitants_color = '#ff00ff' # fuchsia
free_parking_color = '#90ee90' # lightgreen
garage_color = '#006400' # darkgreen
parking_building_color = '#006400' # darkgreen
one_hour_color = '#e5d7e7' # light lilla
two_hours_color = '#bb95c1' # light medium lilla
three_hours_color = '#96709c' # dark lilla
four_hours_color = '#ff8c00' # darkorange
borders_color = '#4a4f4d' # grey
parking_occupied_color = '#D02E26' # red
parking_free_color = '#0af248' # green
working_place_color = '#66ACE9' # light blue
living_place_color = '#E1E966' # light yellow
mixed_use_color = '#009900' # dark green
infrastructure_color = '#A0A0A0' # grey
visitors_not_working_color = '#f5b342' # orange
visitors_working_color = '#a4f542' # lime
residents_working_color = '#c842f5' # lilla
residents_not_working_color = '#f54284' # pink
black = '#050505' # black

# get relative data folder to img
PATH = pathlib.Path(__file__).parent
DATA_PATH = PATH.joinpath("../img").resolve()

# logos
image_filename = 'fhp.png' # fhp logo
encoded_image = base64.b64encode(open(DATA_PATH.joinpath(image_filename), 'rb').read())
image_filename2 = 'efre.png' # european fund regional development logo
encoded_image2 = base64.b64encode(open(DATA_PATH.joinpath(image_filename2), 'rb').read())
image_filename3 = 'smartuplab.png' # smartuplab logo
encoded_image3 = base64.b64encode(open(DATA_PATH.joinpath(image_filename3), 'rb').read())
#image agenda
image_filename5 = 'co-creation-ansatz.png' # vip tram
encoded_image5 = base64.b64encode(open(DATA_PATH.joinpath(image_filename5), 'rb').read())

# mapbox token and style
token = "XXX"
#selected_style = 'mapbox://styles/diegod17/ckrkszwxk24fh17ns9r8fqprs' # bornstedt layer
selected_style = 'mapbox://styles/diegod17/cl38e88k100em14p61gtc83ux' # neuruppin layer
selected_style_with_buildings = 'mapbox://styles/diegod17/cl4qsk7s8002g16o357iuiuob' # neuruppin layer2
#selected_style = 'mapbox://styles/diegod17/ckrc68e8817vg17n0p00v42v8' # dark layer


############################
##  Import and clean data ##
############################

#app.server.config["SQLALCHEMY_DATABASE_URI"] = "XXX"
app.server.config["SQLALCHEMY_DATABASE_URI"] = "XXX"

db = SQLAlchemy(app.server)

conn = db.engine

with conn.connect() as connection:
     #buildings = gpd.read_postgis('select gid, funktion, geom from "buildings_poly_epsg25833"',con=connection)
     parking_places = gpd.read_postgis('select gid, zonen, idstatbez, switch, geom  from "parkplaetze_poly_epsg25833"',con=connection)
     blocks = gpd.read_postgis('select idstatbez, geom from "statistische_bezirke_epsg25833"',con=connection)
     setting_names = pd.read_sql('select * from "overview_simulations"',con=connection)
     connection.close()
     
# # fix the geometries
# buildings.crs = "EPSG:25833"
# buildings = buildings.to_crs(epsg='4326')

# # define list of buildings typologies
# list_living_building = ['Wohnhaus', 'Wohngebäude']
# list_mixed_building = ['Wohngebäude mit Gewerbe und Industrie', 'Wohngebäude mit Handel und Dienstleistungen', 'Wohn- und Geschäftsgebäude', 'Gebäude für Gewerbe und Industrie mit Wohnen']
# list_infrastructures= ['Durchfahrt an überbauter Verkehrsstraße', 'Durchfahrt im Gebäude', 'Heizwerk', 'Keller', 'Land- und forstwirtschaftliches Betriebsgebäude', 'Nach Quellenlage nicht zu spezifizieren', 'Pumpstation', 'Stall', 'Schuppen', 'Stall', 'Tiefgarage', 'Überdachung', 'Umformer']

# # fill a coll with the aggreegated typologies
# conditions =  [buildings['funktion'].isin(list_living_building), buildings['funktion'].isin(list_infrastructures), buildings['funktion'].isin(list_mixed_building)]
# output = ["Wohngebäude", 'Instrastruktur', 'Mischnutzung' ]
# buildings["Gebäude Typologie"] = np.select(conditions, output, default="Gewerbe- und Bürogebäude")
# # remove funktion col
# buildings = buildings.drop(['funktion'], axis = 1)


parking_places.crs = "EPSG:25833"
parking_places = parking_places.to_crs(epsg='4326')
parking_places.rename(columns={'zonen':'Typologie'}, inplace=True)

blocks.crs = "EPSG:25833"
blocks = blocks.to_crs(epsg='4326')

# read the result data based on the strings from the overview
setting_names['string'] = "results_" + setting_names['setting_name'].str.lower() + "_" + setting_names['scenario_name'].str.lower() + "_parking_places_by_hour"

# create lists for the dropdowns
setting_names['friendly_string'] = setting_names['string']
setting_names['friendly_string'] = setting_names['friendly_string'].str.replace('results_', '', regex=False)
setting_names['friendly_string'] = setting_names['friendly_string'].str.replace('_parking_places_by_hour', '', regex=False)
setting_names['friendly_string'] = setting_names['friendly_string'].str.replace('_', ' ', regex=False)
setting_names_list = list(setting_names.friendly_string.unique())

# read the result data based on the strings from the overview
setting_names['string'] = "results_" + setting_names['setting_name'].str.lower() + "_" + setting_names['scenario_name'].str.lower() + "_parking_places_by_hour"

# create a list for reading the results
to_be_read = list(setting_names['string'])

# read the queries in a dictionnary and extract all dataframes in a single dataframe with the id as column
d = {}
for i in to_be_read:
    with conn.connect() as connection:
        query = 'select * from ' + '"' + i + '"'
        temp = pd.read_sql(query,con=connection)
        d[i] = pd.DataFrame(temp)
        connection.close()
        
for key, df in d.items():
    # create a column called "key name"
    df['setting_scenario_name'] = key

lst = list(d.values())
results = pd.concat(lst)

# count max parking by block
parking_by_blocks = parking_places.groupby(['idstatbez']).size().to_frame('n_of_parking_places').reset_index()
parking_by_type = parking_places.groupby(['Typologie']).size().to_frame('n_of_parking_places').reset_index()

blocks = pd.merge(blocks, parking_by_blocks)

# # merge parking and initial setting
results["osm_id"] = pd.to_numeric(results["osm_id"])

# create a list of unique setting_scenarios_names
setting_scenario_names = results['setting_scenario_name'].unique()

d = {}
for list_element in setting_scenario_names:
    df_name = "parking_places" + str(list_element)
    temp_results = results.copy()
    temp_parking_places = parking_places.copy()
    
    temp_parking_places = temp_parking_places.drop(['switch'], axis = 1)
    temp_results = temp_results[temp_results['setting_scenario_name'] == list_element]
    # create a copy
    temp_parking_places2 = temp_parking_places.copy()
    
    # loop and fill two dfs one for true and one for false
    for i in range(4,24):
        for j in [0,10,20,30,40,50]:
            col_names_str = str(i) + ":" + str(j) + "_Uhr" 
            temp_parking_places[col_names_str] = temp_parking_places['gid'].map(pd.merge(temp_parking_places[["gid"]], temp_results[(temp_results['occupied'] == True) & (temp_results['hour'] == i) & (temp_results['minute'] == j)], left_on='gid', right_on='osm_id').set_index('osm_id')['occupied'], na_action='None')
            temp_parking_places2[col_names_str] = temp_parking_places2['gid'].map(pd.merge(temp_parking_places2[["gid"]], temp_results[(temp_results['occupied'] == False) & (temp_results['hour'] == i) & (temp_results['minute'] == j)], left_on='gid', right_on='osm_id').set_index('osm_id')['occupied'], na_action='None')
            
    temp_parking_places.iloc[:,4] = temp_parking_places.iloc[:,4].fillna(False)
    temp_parking_places = temp_parking_places.fillna(temp_parking_places2)
    
    # # list of metrics
    time_of_the_day = temp_parking_places.columns[pd.Series(temp_parking_places.columns).str.contains('_Uhr')]
    
    temp_parking_places[time_of_the_day] = temp_parking_places[time_of_the_day].fillna(method="ffill", axis = 1)
    list_element = list_element.replace("results_", "")
    list_element = list_element.replace("_parking_places_by_hour", "")
    list_element = list_element.replace("_", " ")
    d[list_element] = temp_parking_places
    del temp_results, temp_parking_places, temp_parking_places2

# create two lists for slicing
blk_and_time = time_of_the_day.insert(0,"idstatbez")
type_and_time = time_of_the_day.insert(0,"Typologie")
b_dict = {}
t_dict = {}
for key in d:
    df = d[key]
    
    ### parking by blocks
    temp_blocks = blocks.copy()
    # sum up true and false grouped by block
    blocks_parking_count = df[blk_and_time].groupby(['idstatbez']).sum().reset_index()
    # merge with block df
    temp_blocks = pd.merge(temp_blocks, blocks_parking_count)
    # divide by max capacity
    temp_blocks[time_of_the_day] = temp_blocks[time_of_the_day].div(temp_blocks.n_of_parking_places, axis=0).round(2)
    # add to dict
    b_dict[key] = temp_blocks
    
    ### parking by typology
    temp_parking_by_type = parking_by_type.copy()
    # sum up true and false grouped by type
    parking_by_type_count = df[type_and_time].groupby(['Typologie']).sum().reset_index()
    # merge with parking by type
    temp_parking_by_type = pd.merge(temp_parking_by_type, parking_by_type_count)
    # add to dict
    t_dict[key] = temp_parking_by_type

    del blocks_parking_count, temp_blocks, parking_by_type_count, temp_parking_by_type
    
z_dict = {}
for key in setting_names['string'].unique():
    # slice by setting scenario name
    df = results[(results['setting_scenario_name'] == key) & (results['occupied'] == True)]
    #adapt the key to a friendly string
    key_adjusted = key.replace("results_", "")
    key_adjusted = key_adjusted.replace("_parking_places_by_hour", "")
    key_adjusted = key_adjusted.replace("_", " ")
    # create a col that can match the interface slider
    df['Uhrzeit'] = df['hour'].astype("string") + ":" + df['minute'].astype("string") + "_Uhr"
    # avg and n of cases grouped by target group and hour
    df2 = pd.DataFrame()
    df2['Durch. Distanz zum Zielort'] = df.groupby(['occupied_by', 'Uhrzeit'])['distance_to_goal'].mean().to_frame()
    df2['Anzahl der Personen'] = df.groupby(['occupied_by', 'Uhrzeit'])['distance_to_goal'].count().to_frame()
    df2 = df2.reset_index()
    # rename value in col and rename the col
    df2['occupied_by'] = df2['occupied_by'].str.replace('not_working_inhabitant', 'Nicht berufstätige Bewohner*in', regex=True)
    df2['occupied_by'] = df2['occupied_by'].str.replace('working_inhabitant', 'Berufstätige Bewohner*in', regex=True)
    df2['occupied_by'] = df2['occupied_by'].str.replace('worker', 'Berufstätige Besucher*in', regex=True)
    df2['occupied_by'] = df2['occupied_by'].str.replace('freetime', 'Besucher*in', regex=True)
    df2.rename(columns={'occupied_by':'Zielgruppe'}, inplace=True)
    # add to dict
    z_dict[key_adjusted] = df2

conn.connect().close()

# make setting_names df user friendly
setting_names = setting_names.drop(["park_and_ride_location",'index', 'friendly_string', "string"], axis = 1)
setting_names.columns = ['Setting', 'Tag', 'Event geplannt?', 'Standort', 'Dauer', 'Start', 'Anz. Besucher*innen', 'Anz. Einwohner*innen mit Parkschein', 'Aufdeckung des Baches', 'Erweiterung Parkplätze Töllerstr.', 'Abbau Parkplätze am Bahnhof', 'Diagonalparken Schinkelstr.', 'Aufhebung Parkzonen', 'Autofreie Straßen', 'Umbau Parkplätze', 'Park & Ride ', 'Anz. Parkplätze']