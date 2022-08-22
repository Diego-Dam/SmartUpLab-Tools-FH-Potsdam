
# data manipulation
import pandas as pd
import geopandas as gpd
import numpy as np
from datetime import datetime

# managing the app folder structure
import pathlib

# data import and connection to postgis
import psycopg2
from sqlalchemy import create_engine
import base64
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.pool import NullPool

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
normal_node_color = '#e6bcc0' # light red
bus_stop_color = '#99297D' # dark lilla
#bus_stop_color = '#cbf7cb' # light green
rdt_stop_color = '#fcba03'# orange
tram_stop_color = '#D02E26' # red
kindergarten_color = '#f5dfdc' # reddish
school_color = '#8800ff' # red
working_place_color = '#5B6AF3' # blue
shopping_place_color = '#0af248' # green
uninhabited_color = '#d8dfeb' # light blue
inhabited_color = '#dcebd8' # light green
borders_color = '#4a4f4d' # grey
living_place_color = '#E9E6E6' # light grey

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
#image tram
image_filename4 = 'vip_tram.png' # vip tram
encoded_image4 = base64.b64encode(open(DATA_PATH.joinpath(image_filename4), 'rb').read())
#image agenda
image_filename5 = 'co-creation-ansatz.png' # vip tram
encoded_image5 = base64.b64encode(open(DATA_PATH.joinpath(image_filename5), 'rb').read())
#flexi_area_bornstedt_only.png
#image classic_bornbusfig
image_filename6 = 'classic_bornbusfig.png' # vip tram
encoded_image6 = base64.b64encode(open(DATA_PATH.joinpath(image_filename6), 'rb').read())
#image flexi_bornbusfig
image_filename7 = 'flexi_area_bornstedt_only.png' # vip tram
encoded_image7 = base64.b64encode(open(DATA_PATH.joinpath(image_filename7), 'rb').read())
#logo-verkehrsbetriebe-stadtwerke-potsdam.png
image_filename8 = 'logo-verkehrsbetriebe-stadtwerke-potsdam.png' # vip tram
encoded_image8 = base64.b64encode(open(DATA_PATH.joinpath(image_filename8), 'rb').read())
#area blank
image_filename9 = 'reasearch_area_blank.png' # vip tram
encoded_image9 = base64.b64encode(open(DATA_PATH.joinpath(image_filename9), 'rb').read())

#flexi_bornbusfig
image_filename9 = 'flexi_area_bornstedt_only_cutted.png' # vip tram
encoded_image9 = base64.b64encode(open(DATA_PATH.joinpath(image_filename9), 'rb').read())

#classic_bornbusfig
image_filename10 = 'classic_bornbusfig_cutted.png' # vip tram
encoded_image10 = base64.b64encode(open(DATA_PATH.joinpath(image_filename10), 'rb').read())

#######################
## GENERAL FUNCTIONS ##
#######################

# generate tables
def generate_table(dataframe, max_rows=50):
    dataframe = dataframe.sort_values(by=['Reihenfolge'])
    dataframe = dataframe[dataframe['Reihenfolge'] > 0]
    return html.Table([
        html.Thead(
            html.Tr([html.Th(col) for col in dataframe.columns])
        ),
        html.Tbody([
            html.Tr([
                html.Td(dataframe.iloc[i][col]) for col in dataframe.columns
            ]) for i in range(min(len(dataframe), max_rows))
        ])
    ])

# friendly time visualization
intervals = (
    ('Wochen', 604800),  # 60 * 60 * 24 * 7
    ('Tage', 86400),    # 60 * 60 * 24
    ('Std.', 3600),    # 60 * 60
    ('Min.', 60),
    ('Sek.', 1),
)

def display_time(seconds, granularity=2):
    result = []

    for name, count in intervals:
        value = int(seconds // count)
        if value:
            seconds -= value * count
            if value == 1:
                name = name.rstrip('s')
            result.append("{} {}".format(value, name))
    return ', '.join(result[:granularity])


##############################################################################
############################  Route planning page ############################
##############################################################################

############################
##  Import and clean data ##
############################
# live Heroku PostgreSQL database
app.server.config["SQLALCHEMY_DATABASE_URI"] = "XXX"

db = SQLAlchemy(app.server)

conn = db.engine

with conn.connect() as connection:
     living_building = gpd.read_postgis('select *  from "living_building"',con=connection)
     future_building = gpd.read_postgis('select *  from "future_building"',con=connection)
     blocks = gpd.read_postgis('select *  from "blocks"',con=connection)
     edu = gpd.read_postgis('select *  from "edu"',con=connection)
     building = gpd.read_postgis('select * from "building"',con=connection)
     tram_stops = gpd.read_postgis('select * from "tram_stops"',con=connection)
     nodes = gpd.read_postgis('select * from "nodes"',con=connection)
     travels = pd.read_sql('select * from "travels"',con=connection)
     people = pd.read_sql('select Personal_ID, block, age_class, is_commuter, is_leisure_outside, is_shopping_outside from "people_2306"',con=connection)
     travels_basic_scenario = pd.read_sql('select * from "travels_basic_scenario"',con=connection)
     travels_classic_route = pd.read_sql('select * from "travels_classic_route"',con=connection)
     passengers_classic_route = pd.read_sql('select * from "passengers_classic_route"',con=connection)
     travels_classic_route = pd.read_sql('select * from "travels_classic_route"',con=connection)
     passengers_classic_route = pd.read_sql('select * from "passengers_classic_route"',con=connection)
     travels_flexi_route = pd.read_sql('select * from "travels_flexi_route"',con=connection)
     passengers_flexi_route = pd.read_sql('select * from "passengers_flexi_route"',con=connection)
     travels_flexi_route = pd.read_sql('select * from "travels_flexi_route"',con=connection)
     passengers_flexi_route = pd.read_sql('select * from "passengers_flexi_route"',con=connection)
     operational_data_flexi_route = pd.read_sql('select * from "operational_data_flexi_route"',con=connection)
     trip_duration_pt = pd.read_sql('select * from "trip_duration_pt"',con=connection)
     connection.close()
# define database names for results
table_name   = "new_node_table";

# read the tables to geopandas df
# living buildings layer
# living_building = gpd.read_postgis('select *  from "living_building"',con=conn)

# # future buildings layer
# future_building = gpd.read_postgis('select *  from "future_building"',con=conn)

# # blocks
# blocks = gpd.read_postgis('select *  from "blocks"',con=conn)

# # educational buildings
# edu = gpd.read_postgis('select *  from "edu"',con=conn)

# # working / recreational buildings
# building = gpd.read_postgis('select * from "building"',con=conn)

# # tram stops
# tram_stops = gpd.read_postgis('select * from "tram_stops"',con=conn)

# # nodes
# nodes = gpd.read_postgis('select * from "nodes"',con=conn)
nodes["new_bus_line"] = -1

# define colors
normal_node_color = '#e6bcc0' # light red
bus_stop_color = '#99297D' # dark lilla
#bus_stop_color = '#cbf7cb' # light green
rdt_stop_color = '#fcba03'# orange
tram_stop_color = '#D02E26' # red
kindergarten_color = '#f5dfdc' # reddish
school_color = '#eb2009' # red
working_place_color = '#5B6AF3' # blue
shopping_place_color = '#0af248' # green
uninhabited_color = '#d8dfeb' # light blue
inhabited_color = '#dcebd8' # light green
borders_color = '#4a4f4d' # grey

# for interaction with the map
df_node_inter = pd.DataFrame()
bus_route_counter = 1

### create a list of ids that are blk_idz
blk_idz_list = blocks.blk_idz.to_list()

# create a node df for visualization purpose
df_node = pd.DataFrame(nodes)
df_node = df_node.drop(columns=['geom'])
df_node["new_bus_line"] = -1

df_node_viz = df_node[['fid', 'lat', 'lon', 'new_bus_line']]
df_node_viz.columns = ['ID', 'Lat', 'Lon', 'Reihenfolge']

# create a df for sending frequency and capacity to sql
list_of_inputs = []
hvk_frequency = None
nvk_frequency = None
night_frequency = None
capacity = None
n_of_stops = None
perc_door_pick_up = None

# create a df for visualizing the frequencies
bus_frequencies = pd.DataFrame({'hour':range(24),
                   'takt':0,
                   'bus_per_hour':0,
                   'label_vehicles':'Benötigte Fahrzeuge<br>pro Stunde<br>für beide Richtungen',
                   'label_buffer':'Zeitpuffer pro Bus<br>zwischen den Fahrten'})

# create a df for exporting the timetable
rdt_general_timetable = pd.DataFrame(columns=['route_short_name', 'departure_hour', 'departure_minute'])

# create lists for the dropdowns
house_types = list(living_building.housetyp.unique())
scatter_types = list(nodes['type'].unique())


# list of metrics
metrics = living_building.columns[pd.Series(living_building.columns).str.contains('cost')]
metrics_blks = blocks.columns[pd.Series(blocks.columns).str.contains('avg')]
# metrics_blks_dict = dict(zip(list(metrics_blks_labels), list(metrics_blks)))
modal_share = ['16%', '21%', '26%',]


# mapbox token and style
token = "XXX"
selected_style = 'mapbox://styles/diegod17/ckrkszwxk24fh17ns9r8fqprs' # roys layer

# routing results with list containing a zero for the first row (since it is the first stop, there is no distance and duration from the previous one)
durations = [0]
distances = [0]

# empty lists for the overall duration and distance
total_duration = []
total_duration_in_sec = []
total_distance = []

# definition of stop duration
stop_duration = 10

# # result basic scenario (for route planning page)
# travels = pd.read_sql('select * from "travels"',con=conn)

# people = pd.read_sql('select Personal_ID, block, age_class, is_commuter, is_leisure_outside, is_shopping_outside from "people_2306"',con=conn)
people = people.astype({"personal_id": str})

# metrics
leaving_the_area = travels['leaving_the_area'].unique()

# define cols that have to be sum up
to_be_sum_up_travels = travels.iloc[:,8:14].columns.values

##################################################################################
############################  Scenarios analysis page ############################
##################################################################################

#####################
##  Basic scenario ##
#####################

# travels_basic_scenario = pd.read_sql('select * from "travels_basic_scenario"',con=conn)
#modal_split_basic_scenario_slim = pd.read_sql('select * from "modal_split_basic_scenario"',con=conn)
# people = pd.read_sql('select Personal_ID, block, age_class, is_commuter, is_leisure_outside, is_shopping_outside from "people_2306"',con=conn)

modi = travels_basic_scenario['modi'].unique()

####################
##  Classic route ##
####################

# travels_classic_route = pd.read_sql('select * from "travels_classic_route"',con=conn)
# #modal_split_slim_classic_route = pd.read_sql('select * from "modal_split_slim_classic_route"',con=conn)
# passengers_classic_route = pd.read_sql('select * from "passengers_classic_route"',con=conn)
passengers_classic_route = passengers_classic_route.drop(columns=['index'])
##################
##  Flexi route ##
##################

# travels_flexi_route = pd.read_sql('select * from "travels_flexi_route"',con=conn)
# #modal_split_slim_flexi_route = pd.read_sql('select * from "modal_split_slim_flexi_route"',con=conn)
# passengers_flexi_route = pd.read_sql('select * from "passengers_flexi_route"',con=conn)
passengers_flexi_route = passengers_flexi_route.drop(columns=['index'])

# operational_data_flexi_route = pd.read_sql('select * from "operational_data_flexi_route"',con=conn)


# # data for öpnv travel by block
# trip_duration_pt = pd.read_sql('select * from "trip_duration_pt"',con=conn)

blocks_df_all_scenarios = pd.merge(blocks, trip_duration_pt,  how='left', left_on=['blk_idz'], right_on = ['block'])

# list of metrics
metrics_blks_res = trip_duration_pt.columns[pd.Series(trip_duration_pt.columns).str.contains('Szenario', case=False)]

# metrics for rdt passengers
directions = list(passengers_classic_route.Richtung.unique())
to_be_sum_up_passengers_flexi = passengers_flexi_route.iloc[:,3:40].columns.values
