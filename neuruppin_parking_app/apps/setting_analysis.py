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
from dash import dcc
from dash import html
import dash_daq as daq
from dash.dependencies import Input, Output
from dash.exceptions import PreventUpdate

from app import app
from apps import setting_analysis, settings_comparison, home
#, scenarios_overview


from .dataprep import preproc

colors = preproc.colors
blackbold = preproc.blackbold
#buildings = preproc.buildings
blocks = preproc.blocks
parking_places = preproc.parking_places
d = preproc.d
t_dict = preproc.t_dict
z_dict = preproc.z_dict
time_of_the_day = preproc.time_of_the_day
token = preproc.token
selected_style_with_buildings = preproc.selected_style_with_buildings
# define colors
borders_color = preproc.borders_color
parking_occupied_color = preproc.parking_occupied_color
parking_free_color = preproc.parking_free_color
working_place_color = preproc.working_place_color
living_place_color = preproc.living_place_color
mixed_use_color = preproc.mixed_use_color
infrastructure_color = preproc.infrastructure_color
visitors_not_working_color = preproc.visitors_not_working_color
visitors_working_color = preproc.visitors_working_color
residents_working_color = preproc.residents_working_color
residents_not_working_color = preproc.residents_not_working_color
setting_names_list = preproc.setting_names_list

db = preproc.db

updated = 0

######################
##  App HTML layout ##
######################
layout = html.Div([
    html.H2("Setting-Analyse", style={'text-align': 'center', 'color': colors['text']}),
    html.Div([
        html.Div([
            html.Label(children=['Uhrzeit und Szenario auswählen'], style = {'text-align': 'center', 'color':'black', 'font-weight': 'bold'})
            ]),
        html.Div([
            html.Div([
            dcc.Dropdown(
                    # value dynamically coming from callback
                    id = "setting"
                )], style = {'width':'80%', 'text-align': 'center','float': 'left', 'display': 'inline-block'}),
            html.Div([
            html.A(html.Button('Update', id='update_table', style={'color':colors['text']}), style={'background-color': colors['background_buttons'], 'margin-right':'15px'}),
            ], style = {'width':'20%', 'text-align': 'center', 'display': 'inline-block'}),
            dcc.Slider(
                0,
                119,
                step=1,
                value= 24,
                id='hour-slider',
                marks = {i : {'label' : time_of_the_day[i], 'style':{'transform':'rotate(45deg)', 'font-size':'8px'}} for i in range(0,120) if i %6== 0}
            )], style={'width': '85%', 'display': 'block', 'margin-left': 'auto', 'margin-right': 'auto'}),
        html.Br(),
        html.Div([
            # Legend and options - Left side of the screen
            html.Div([
            # Map-legend for parking places
            html.Label(['Parkplätze:'],style=blackbold),
            html.Ul([
                html.Li("Parkplatz besetzt", style={'background': parking_occupied_color,'color':'black', 'white-space':'nowrap',
                    'list-style':'none','text-indent': '20px', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Parkplatz frei", style={'background': parking_free_color,'color':'black',
                    'list-style':'none','text-indent': '20px','white-space':'nowrap', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}
                ),
            # Map-legend for buildings
            html.Label(['Gebäude:'],style=blackbold),
            html.Ul([
                html.Li("Wohngebäude", style={'background': living_place_color,'color':'black',
                    'list-style':'none','text-indent': '20px', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Gebäude für Gewerbe", style={'background': working_place_color,'color':'black',
                    'list-style':'none','text-indent': '20px','white-space':'nowrap', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Mischnutzung", style={'background': mixed_use_color,'color':'black',
                    'list-style':'none','text-indent': '20px', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Infrastrukturgebäude", style={'background': infrastructure_color,'color':'black',
                    'list-style':'none','text-indent': '20px','white-space':'nowrap', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'})
                ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}
                ),
            ], style = {'width':'22%'}),    
            # Map - Right side of the screen
            html.Div([
                dcc.Graph(id='choropleth_res', clickData=None, hoverData=None, config={'displayModeBar': False,
                                                                                   'staticPlot': False,
                                                                                   'watermark': False,
                                                                                   'showTips': False, 
                                                                                   'doubleClick': False,  # 'reset', 'autosize' or 'reset+autosize', False
                                                                                   'scrollZoom': True},
                    style={'padding-bottom':'2px','padding-left':'2px','height':'75vh'}
                )
            ], style={'width':'74%'}
        ),
        html.Br(),
        ], style={'width': '100%', 'margin-left':'0px', 'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px',
                                               'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    html.Div([
        html.H3("Belastung des Parkangebots nach Typologie", style={'text-align': 'center', 'color': colors['text']}),
        html.Div([
                dcc.Graph(id='graph1_res', clickData=None, hoverData=None, config={'displayModeBar': False,
                                                                                   'staticPlot': False,
                                                                                   'watermark': False,
                                                                                   'showTips': False, 
                                                                                   'doubleClick': False,  # 'reset', 'autosize' or 'reset+autosize', False
                                                                                   'scrollZoom': True},
                    style={'padding-bottom':'2px','padding-left':'2px','height':'75vh'}
                )
            ], style={'width':'100%'}
        ),
        ], style={'width': '100%', 'margin-left':'0px', 'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px',
                                               'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Div([
        html.Div([
                dcc.Graph(id='graph2_res', clickData=None, hoverData=None, config={'displayModeBar': False,
                                                                                   'staticPlot': False,
                                                                                   'watermark': False,
                                                                                   'showTips': False, 
                                                                                   'doubleClick': False,  # 'reset', 'autosize' or 'reset+autosize', False
                                                                                   'scrollZoom': True},
                    style={'padding-bottom':'2px','padding-left':'2px','height':'75vh'}
                )
            ], style={'width':'100%'}
        ),
        html.H3("Distanz zum Zielgebäude nach Zielgruppen", style={'text-align': 'center', 'color': colors['text']})
        ], style={'width': '100%', 'margin-left':'0px', 'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px',
                                               'display':'flex', 'justify-content':'center', 'align-items':'center'}),
      
    ]),
    html.Div(id='confirm_update', style={'padding-top': '6px', 'display':'flex', 'justify-content':'center', 'align-items':'center'}),
  ])
#####################
##  App Callbacks ##
####################


#### callback for map > display and update the map
@app.callback(
    Output(component_id='choropleth_res', component_property='figure'),
    Output(component_id='graph1_res', component_property='figure'),
    Output(component_id='graph2_res', component_property='figure'),
    Input(component_id='hour-slider', component_property='value'),
    Input(component_id='setting', component_property='value')
)

def update_graph(hour_slider, setting):

    global d, time_of_the_day, t_dict
        
    parking_places = d[setting]
    
    ############## MAP #######################
    
    #------------1st ayer BUILDINGS------------#

    # fig_custom = px.choropleth_mapbox(
    #     data_frame=buildings,
    #     geojson=buildings.geometry,
    #     locations=buildings.index,
    #     center={"lat": 52.92510, "lon": 12.80720}, 
    #     zoom=15,
    #     #opacity= opacity_blks,
    #     color= 'Gebäude Typologie',
    #     #range_color=(0, 51), # hardcoded for comparability between scenarios
    #     #color_continuous_scale='OrRd',
    #     color_discrete_map={'Wohngebäude':living_place_color,
    #                         'Gewerbe- und Bürogebäude':working_place_color,
    #                         'Mischnutzung':mixed_use_color,
    #                         'Instrastruktur':infrastructure_color})

    # # define layout
    # fig_custom.update_layout(
    #     margin={"r":0,"t":0,"l":0,"b":0},
    #     mapbox_accesstoken=token,
    #     mapbox_style = selected_style_with_buildings,
    #     plot_bgcolor=colors['background'],
    #     paper_bgcolor=colors['background'],
    #     font_color=colors['text'],
    #     showlegend=False,
    #     coloraxis_colorbar=dict(ticksuffix=" Min"))
    
#------------2nd layer PARKING------------#
    
    # Plotly map with mapbox background - selecting columns
    fig_custom = px.choropleth_mapbox(
        data_frame=parking_places,
        geojson=parking_places.geometry,
        locations=parking_places.index,
        #color_continuous_scale='OrRd_r',
        color= time_of_the_day[hour_slider],
        center={"lat": 52.92510, "lon": 12.80720},
        zoom=14,
        color_discrete_map={True:parking_occupied_color,
                            False:parking_free_color})

    # define layout
    fig_custom.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style_with_buildings,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'],
        coloraxis_colorbar=dict(ticksuffix=" mt"),
        showlegend=False)

    # remove  borders
    fig_custom.update_traces(marker_line_width=0)
        
    # ## add shape trace (for color discrete map must be added one layer for each color category > in this case 8)
    # fig_custom.add_trace(fig_parking1.data[0]) 
    # fig_custom.add_trace(fig_parking1.data[1])

    ############## GRAPH OF PARKING TYPOLOGY BY HOUR #######################

    # select data by parking typology from the corresponding dict
    types = t_dict[setting]
    
    # remove cols not related to the selected time
    selected_cols = time_of_the_day.delete(hour_slider)
    
    # remove cols not related to the selected time
    types = types.drop(selected_cols, axis=1)
    
    # rename the remaining data col to Uhrzeit
    types = types.set_axis([*types.columns[:-1], 'Besetzte Parkplätze'], axis=1, inplace=False)
    
    types['Freie Parkplätze'] = types['n_of_parking_places'] - types['Besetzte Parkplätze']
    
    types = types.sort_values(by=['n_of_parking_places'])
    
    fig_types = px.bar(types, x="Typologie", y=["Freie Parkplätze", "Besetzte Parkplätze"],
                       color_discrete_map = {"Besetzte Parkplätze":parking_occupied_color, "Freie Parkplätze":parking_free_color})

    fig_types.update_traces(marker_line_color='rgb(8,48,107)',
                  marker_line_width=1.5, opacity=0.6)
    fig_types.update_layout(title_text= "Setting: " + str(setting) + " um " + time_of_the_day[hour_slider], title_x=0.5, yaxis_range=[0,750])

    ############## GRAPH OF DISTANCE BY HOUR #######################
    
    # select data from the corresponding dict
    target_groups = z_dict[setting]
    
    # filter by the selected time of the day
    target_groups = target_groups[target_groups["Uhrzeit"] == time_of_the_day[hour_slider]]

    # create the bar graph for the avg    
    fig_tg = px.bar(target_groups, x="Zielgruppe", y="Durch. Distanz zum Zielort", color = "Zielgruppe",
                        color_discrete_map = {"Besucher*in":visitors_not_working_color, "Berufstätige Besucher*in":visitors_working_color,
                                              "Nicht berufstätige Bewohner*in":residents_not_working_color, "Berufstätige Bewohner*in":residents_working_color})   

    fig_tg.update_traces(marker_line_color='rgb(8,48,107)',
                  marker_line_width=1.5, opacity=0.6)
    fig_tg.update_layout(title_text= "Setting: " + str(setting) + " um " + time_of_the_day[hour_slider], title_x=0.5)
    
    # create a line graph for the n of cases
    fig_tg2 = px.line(target_groups,  x="Zielgruppe", y=["Anzahl der Personen"])
    # locate it on a secondary axis
    fig_tg2.update_traces(yaxis="y1", line_color='#404040', line_width=3)
    fig_tg.add_traces(fig_tg2.data[0])

    # the n of returnerd element must match the n of output elements in the app.callback
    return fig_custom, fig_types, fig_tg

#### callback for the update the table button
@app.callback(
    Output(component_id='confirm_update', component_property='children'),
    Input(component_id='update_table', component_property='n_clicks')
)
def update_data (n_clicks):
    if n_clicks is None:
        raise PreventUpdate
    else:
        global updated, d, t_dict, z_dict, setting_names_list, parking_places, conn
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
    Output("setting", "options"),
    Input("confirm_update", "search_value"),
    Input("confirm_update", "children")
)
def dropdown_list(search_value, updated):
    # if not search_value:
    #     raise PreventUpdate
    return [{'label': x, 'value': x} for x in setting_names_list]

@app.callback(
    Output("setting", "value"),
    Input("setting", "search_value"),
    Input("confirm_update", "children")
)
def dropdown_value(search_value, updated):
    # if not search_value:
    #     raise PreventUpdate
    return setting_names_list[0]