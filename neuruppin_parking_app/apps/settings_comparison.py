########################################## ROUTE PLANNING TOOL ##########################################
# data manipulation
import pandas as pd
import geopandas as gpd
import numpy as np
import datetime
import math

# managing the app folder structure
import pathlib
from pathlib import Path

# data import and connection to postgis
import psycopg2
import os
import base64

# visualization
import plotly.express as px  # (version 4.7.0)
from plotly.subplots import make_subplots
import plotly.figure_factory as ff
import dash  # (version 1.12.0) pip install dash
from dash import dcc, html, dash_table
import dash_daq as daq
from dash.dependencies import Input, Output, State
from dash.exceptions import PreventUpdate

# data import and connection to postgis
import psycopg2
from sqlalchemy import create_engine, inspect
import base64
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.pool import NullPool

from app import app
from apps import setting_analysis, settings_comparison, home
#, scenarios_overview

from .dataprep import preproc

colors = preproc.colors
blackbold = preproc.blackbold
blocks = preproc.blocks
parking_places = preproc.parking_places
b_dict = preproc.b_dict
t_dict = preproc.t_dict
time_of_the_day = preproc.time_of_the_day
token = preproc.token
selected_style = preproc.selected_style
# define colors
borders_color = preproc.borders_color
inhabitants_color = preproc.inhabitants_color
free_parking_color = preproc.free_parking_color
garage_color = preproc.garage_color
parking_building_color = preproc.parking_building_color
one_hour_color = preproc.one_hour_color
two_hours_color = preproc.two_hours_color
three_hours_color = preproc.three_hours_color
four_hours_color = preproc.four_hours_color
setting_names_list = preproc.setting_names_list
setting_names = preproc.setting_names

db = preproc.db
conn = preproc.conn

updated = 0
######################
##  App HTML layout ##
######################
layout = html.Div([
        dcc.Store(id='session', storage_type='session'),
        html.Div([
        html.H2("Setting-Vergleich", style={'text-align': 'center', 'color': colors['text']}),
        html.Div([
            dash_table.DataTable(
                data = setting_names.to_dict('records'),
                #data = [ {col.split("|")[0]: val for col, val in row.items() } for row in setting_names.to_dict('records')],
                columns = [{"name": i.split("|",2), "id": i.split("|")[0]} for i in setting_names.columns],
                style_cell={'font_size': '8x', 'textAlign': 'right', 'padding': '2px', 'height': 'auto', 'whiteSpace': 'normal'},
                style_data={
                    'color': 'black',
                    'backgroundColor': 'white'},
                style_data_conditional=[{
                        'if': {'row_index': 'odd'},
                            'backgroundColor': 'rgb(224, 224, 224)'}],
                style_header={
                    'backgroundColor': 'rgb(48, 48, 48)',
                    'color': 'white',
                    'fontWeight': 'bold', 'font_size': '8x', 'textAlign': 'right',
                        'padding': '2px', 'height': 'auto', 'whiteSpace': 'normal'
                }
            )
            ], style={'display':'inline-block', 'justify-content':'center', 'align-items':'left'}),
        html.Div([
            html.A(html.Button('Update', id='update_table', style={'color':colors['text']}), style={'background-color': colors['background_buttons'], 'margin-right':'15px'}),
            html.Div(id='confirm_update2', style={'padding-top': '6px', 'display':'flex', 'justify-content':'center', 'align-items':'center'})
            ], style = {'text-align': 'center'}),
    html.Br(),
    # Checkbox button
    html.Div([
        html.Div([
            html.Label(children=['Setting 1:'], style=blackbold),
                dcc.Dropdown(
                    [{'label': x, 'value': x} for x in setting_names_list],
                    setting_names_list[0],
                    placeholder="Einen Setting auswählen",
                    id = "setting_2",
                ),
            ], style={'width': '49%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            html.Label(children=['Setting 2:'], style=blackbold),
                dcc.Dropdown(
                    [{'label': x, 'value': x} for x in setting_names_list],
                    setting_names_list[1],
                    placeholder="Einen Setting auswählen",
                    id = "setting_1",
                ),
            ], style={'width': '49%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
    ], style={'width': '100%', 'margin-left':'0px', 'border-bottom': 'dotted 1px', 'border-color':borders_color,'padding-top': '6px', 'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    ]),
    html.Br(),
    html.Div([
        html.Label(children=['Uhrzeit auswählen'], style = {'text-align': 'center', 'color':'black', 'font-weight': 'bold'})
        ]),
    html.Div([
        dcc.Slider(
            0,
            119,
            step=1,
            value= 24,
            id='hour-slider',
            marks = {i : {'label' : time_of_the_day[i], 'style':{'transform':'rotate(45deg)', 'font-size':'8px'}} for i in range(0,120) if i %6== 0}
        )], style={'width': '85%', 'display': 'block', 'margin-left': 'auto', 'margin-right': 'auto'}),
   # Block data viz by scenario    
   # Block data viz
   html.H3("Prozentuale Belastung des Parkplatzangebotes nach Blöcken", style={'text-align': 'center', 'color': colors['text']}),
   html.Br(),
    html.Div([
        html.Div([
            dcc.Graph(id='map1', clickData=None, hoverData=None, config={'displayModeBar': False,
                                                                                 'staticPlot': False,
                                                                                 'watermark': False,
                                                                                 'showTips': False, 
                                                                                 'doubleClick': False,  # 'reset', 'autosize' or 'reset+autosize', False
                                                                                 'scrollZoom': True},
                  style={'padding-bottom':'2px','padding-left':'2px','height':'75vh'}
              )
            ],style={'width': '49%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            dcc.Graph(id='map2', clickData=None, hoverData=None, config={'displayModeBar': False,
                                                                                 'staticPlot': False,
                                                                                 'watermark': False,
                                                                                 'showTips': False, 
                                                                                 'doubleClick': False,  # 'reset', 'autosize' or 'reset+autosize', False
                                                                                 'scrollZoom': True},
                  style={'padding-bottom':'2px','padding-left':'2px','height':'75vh'}
              )
            ],style={'width': '49%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
        ),
    ]),
  ]),

#####################
##  App Callbacks ##
####################


#### callback for map > display and update the map
@app.callback(
    Output(component_id='map1', component_property='figure'),
    Input(component_id='hour-slider', component_property='value'),
    Input(component_id='setting_1', component_property='value'),
    Input('session', 'modified_timestamp'),
    State('session', 'fig_custom1')
)

def update_graph(hour_slider, setting_1, timestamp, fig_custom1):
    
    if timestamp is None:
        raise PreventUpdate
    
    fig_custom1 = fig_custom1 or {}
    
    global b_dict, time_of_the_day
    
    # select block data from the corresponding dict
    blocks1 = b_dict[setting_1]
    
    # remove cols not related to the selected time
    selected_cols = time_of_the_day.delete(hour_slider)
    blocks1 = blocks1.drop(selected_cols, axis=1)
    
    # rename the remaining data col to Uhrzeit
    blocks1 = blocks1.set_axis([*blocks1.columns[:-1], 'Uhrzeit'], axis=1, inplace=False)
    
    ### MAP 1 ###
    
     #------------1st layer BLOCKS------------#
    
    fig_custom1 = px.choropleth_mapbox(
        data_frame=blocks1,
        geojson=blocks1.geometry,
        locations=blocks1.index,
        center={"lat": 52.92510, "lon": 12.80720}, 
        zoom=14,
        color= blocks1.Uhrzeit,
        range_color=(0, 1), # hardcoded for comparability between scenarios
        color_continuous_scale='OrRd',
        custom_data=['idstatbez', 'Uhrzeit'])

    # define layout
    fig_custom1.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'],
        showlegend=False,
        coloraxis_colorbar=dict(title = "besetzte<br>Parkplätze"))
    
    # remove blocks borders
    fig_custom1.update_traces(marker_line_width=0, hovertemplate="<br>".join([
        "Im statischen Bezirk: %{customdata[0]}",
        "sind %{customdata[1]} % der Parkplätze besetzt"
        ]))
    
# #------------2nd layer PARKING PLACES------------#
    
#     # Plotly map with mapbox background
#     fig_parking1 = px.choropleth_mapbox(
#         data_frame=parking_places,
#         geojson=parking_places.geometry,
#         color='Typologie',
#         locations=parking_places.index,
#         #color_continuous_scale='OrRd_r',
#         center={"lat": 52.92510, "lon": 12.80720},
#         zoom=14,
#         color_discrete_map={'reines Bewohnerparken':inhabitants_color, 'Parken frei':free_parking_color,
#                                 'Garage': garage_color,
#                                 'Tiefgarage': parking_building_color,
#                                 'Parkhaus': parking_building_color,
#                                 '1 Stunde':one_hour_color,
#                                 '2 Stunden': two_hours_color,
#                                 '3 Stunden': three_hours_color,
#                                 '4 Stunden': four_hours_color},
#         custom_data=['idstatbez', 'Typologie'])
#         #range_color=[0, max(living_building['tram_cost'])])

#     # define layout
#     fig_parking1.update_layout(
#         margin={"r":0,"t":0,"l":0,"b":0},
#         mapbox_accesstoken=token,
#         mapbox_style = selected_style,
#         plot_bgcolor=colors['background'],
#         paper_bgcolor=colors['background'],
#         font_color=colors['text'],
#         coloraxis_colorbar=dict(ticksuffix=" mt"),
#         showlegend=False)

#     # remove buildings borders
#     fig_parking1.update_traces(marker_line_width=0, hovertemplate="<br>".join([
#         "Der Parkplatz befindet sich im statischen Bezirk: %{customdata[0]}",
#         "und gehört zu folgender Typologie %{customdata[1]}"
#     ]))
        
#     ## add shape trace (for color discrete map must be added one layer for each color category > in this case 8)
#     fig_custom1.add_trace(fig_parking1.data[0]) 
#     fig_custom1.add_trace(fig_parking1.data[1])
#     fig_custom1.add_trace(fig_parking1.data[2]) 
#     fig_custom1.add_trace(fig_parking1.data[3]) 
#     fig_custom1.add_trace(fig_parking1.data[4])
#     fig_custom1.add_trace(fig_parking1.data[5])
#     fig_custom1.add_trace(fig_parking1.data[6]) 
#     fig_custom1.add_trace(fig_parking1.data[7])
    
    # the n of returnerd element must match the n of output elements in the app.callback
    return fig_custom1

#### callback for map > display and update the map
@app.callback(
    Output(component_id='map2', component_property='figure'),
    Input(component_id='hour-slider', component_property='value'),
    Input(component_id='setting_2', component_property='value'),
    Input('session', 'modified_timestamp'),
    State('session', 'fig_custom2')
)

def update_graph2(hour_slider, setting_2, timestamp, fig_custom2):
    
    if timestamp is None:
        raise PreventUpdate
    
    fig_custom2 = fig_custom2 or {}
    
    global b_dict, time_of_the_day
    
    # select block data from the corresponding dict
    blocks2 = b_dict[setting_2]
    
    # remove cols not related to the selected time
    selected_cols = time_of_the_day.delete(hour_slider)
    blocks2 = blocks2.drop(selected_cols, axis=1)
    
    # rename the remaining data col to Uhrzeit
    blocks2 = blocks2.set_axis([*blocks2.columns[:-1], 'Uhrzeit'], axis=1, inplace=False)
    
    
    ### MAP 2 ###
    
    
     #------------1st layer BLOCKS------------#
    
    fig_custom2 = px.choropleth_mapbox(
        data_frame=blocks2,
        geojson=blocks2.geometry,
        locations=blocks2.index,
        center={"lat": 52.92510, "lon": 12.80720}, 
        zoom=14,
        color= blocks2.Uhrzeit,
        range_color=(0, 1), # hardcoded for comparability between scenarios
        color_continuous_scale='OrRd',
        custom_data=['idstatbez', 'Uhrzeit'])

    # define layout
    fig_custom2.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'],
        showlegend=False)
    
    # remove blocks borders
    fig_custom2.update_coloraxes(showscale=False)
    fig_custom2.update_traces(marker_line_width=0, hovertemplate="<br>".join([
        "Im statischen Bezirk: %{customdata[0]}",
        "sind %{customdata[1]} der Parkplätze besetzt"
    ]))    
    
# #------------2nd layer PARKING PLACES------------#
    
#     # Plotly map with mapbox background
#     fig_parking2 = px.choropleth_mapbox(
#         data_frame=parking_places,
#         geojson=parking_places.geometry,
#         color='Typologie',
#         locations=parking_places.index,
#         #color_continuous_scale='OrRd_r',
#         center={"lat": 52.92510, "lon": 12.80720},
#         zoom=14,
#         color_discrete_map={'reines Bewohnerparken':inhabitants_color, 'Parken frei':free_parking_color,
#                                 'Garage': garage_color,
#                                 'Tiefgarage': parking_building_color,
#                                 'Parkhaus': parking_building_color,
#                                 '1 Stunde':one_hour_color,
#                                 '2 Stunden': two_hours_color,
#                                 '3 Stunden': three_hours_color,
#                                 '4 Stunden': four_hours_color},
#         custom_data=['idstatbez', 'Typologie'])
#         #range_color=[0, max(living_building['tram_cost'])])

#     # define layout
#     fig_parking2.update_layout(
#         margin={"r":0,"t":0,"l":0,"b":0},
#         mapbox_accesstoken=token,
#         mapbox_style = selected_style,
#         plot_bgcolor=colors['background'],
#         paper_bgcolor=colors['background'],
#         font_color=colors['text'],
#         coloraxis_colorbar=dict(ticksuffix=" mt"),
#         showlegend=False)

#     # remove buildings borders
#     fig_parking2.update_traces(marker_line_width=0, hovertemplate="<br>".join([
#         "Der Parkplatz befindet sich im statischen Bezirk: %{customdata[0]}",
#         "und gehört zu folgender Typologie %{customdata[1]}"
#     ]))
        
#     ## add shape trace (for color discrete map must be added one layer for each color category > in this case 8)
#     fig_custom2.add_trace(fig_parking2.data[0]) 
#     fig_custom2.add_trace(fig_parking2.data[1])
#     fig_custom2.add_trace(fig_parking2.data[2]) 
#     fig_custom2.add_trace(fig_parking2.data[3]) 
#     fig_custom2.add_trace(fig_parking2.data[4])
#     fig_custom2.add_trace(fig_parking2.data[5])
#     fig_custom2.add_trace(fig_parking2.data[6]) 
#     fig_custom2.add_trace(fig_parking2.data[7])
    
    # the n of returnerd element must match the n of output elements in the app.callback
    return fig_custom2

#### callback for the update the table button
@app.callback(
    Output(component_id='confirm_update2', component_property='children'),
    Input(component_id='update_table', component_property='n_clicks')
)
def update_data (n_clicks):
    if n_clicks is None:
        raise PreventUpdate
    else:        
        global b_dict, setting_names_list, blocks, updated, conn

        with conn.connect() as connection:
             setting_names = pd.read_sql('select * from "overview_simulations"',con=connection)
             connection.close()
                     
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
                
        for key, df in d.items():
            # create a column called "key name"
            df['setting_scenario_name'] = key
        
        lst = list(d.values())
        results = pd.concat(lst)
        
        # count max parking by block
        parking_by_blocks = parking_places.groupby(['idstatbez']).size().to_frame('n_of_parking_places').reset_index()
        parking_by_type = parking_places.groupby(['Typologie']).size().to_frame('n_of_parking_places').reset_index()
                
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
            
        
        # make setting_names df user friendly
        setting_names = setting_names.drop(["park_and_ride_location",'index', 'friendly_string', "string"], axis = 1)
        setting_names.columns = ['Setting', 'Tag', 'Event geplannt?', 'Standort', 'Dauer', 'Start', 'Anz. Besucher*innen', 'Anz. Einwohner*innen mit Parkschein', 'Aufdeckung des Baches', 'Erweiterung Parkplätze Töllerstr.', 'Abbau Parkplätze am Bahnhof', 'Diagonalparken Schinkelstr.', 'Aufhebung Parkzonen', 'Autofreie Straßen', 'Umbau Parkplätze', 'Park & Ride ', 'Anz. Parkplätze']
        updated = updated + 1
    return 'Anzahl Updates = "{}"'.format(updated)

@app.callback(
    Output("setting_1", "options"),
    Input("confirm_update", "search_value"),
    Input("confirm_update", "children")
)
def dropdown_list(search_value, updated):
    # if not search_value:
    #     raise PreventUpdate
    return [{'label': x, 'value': x} for x in setting_names_list]

@app.callback(
    Output("setting_1", "value"),
    Input("setting", "search_value"),
    Input("confirm_update", "children")
)
def dropdown_value(search_value, updated):
    # if not search_value:
    #     raise PreventUpdate
    return setting_names_list[1]

@app.callback(
    Output("setting_2", "options"),
    Input("confirm_update", "search_value"),
    Input("confirm_update", "children")
)
def dropdown_list(search_value, updated):
    # if not search_value:
    #     raise PreventUpdate
    return [{'label': x, 'value': x} for x in setting_names_list]

@app.callback(
    Output("setting_2", "value"),
    Input("setting", "search_value"),
    Input("confirm_update", "children")
)
def dropdown_value(search_value, updated):
    # if not search_value:
    #     raise PreventUpdate
    return setting_names_list[0]