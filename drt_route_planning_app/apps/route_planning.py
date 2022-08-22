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
import dash  # (version 1.12.0) pip install dash
from dash import dcc
from dash import html
from dash.dependencies import Input, Output
from dash.exceptions import PreventUpdate

from app import app
from apps import route_planning, scenario_analysis, home
#, scenarios_overview

from .dataprep import routing_api
from .dataprep import preproc

create_driving_route = routing_api.create_driving_route
routing_res_df = routing_api.routing_res_df

stop_duration = preproc.stop_duration
total_duration = preproc.total_duration
total_distance = preproc.total_distance
display_time = preproc.display_time
durations = preproc.durations
distances = preproc.distances
living_building = preproc.living_building
future_building = preproc.future_building
edu = preproc.edu
building = preproc.building
blocks = preproc.blocks
nodes = preproc.nodes
tram_stops = preproc.tram_stops
blackbold = preproc.blackbold
blocks = preproc.blocks
bus_frequencies = preproc.bus_frequencies
bus_route_counter = preproc.bus_route_counter
capacity = preproc.capacity
n_of_stops = preproc.n_of_stops
df_node = preproc.df_node
df_node_inter = preproc.df_node_inter
df_node_viz = preproc.df_node_viz
house_types = preproc.house_types
hvk_frequency = preproc.hvk_frequency
list_of_inputs = preproc.list_of_inputs
metrics = preproc.metrics
metrics_blks = preproc.metrics_blks
night_frequency = preproc.night_frequency
nvk_frequency = preproc.nvk_frequency
rdt_general_timetable = preproc.rdt_general_timetable
token = preproc.token
selected_style = preproc.selected_style
generate_table = preproc.generate_table
colors = preproc.colors
blackbold = preproc.blackbold
small_font = preproc.small_font
perc_door_pick_up = preproc.perc_door_pick_up
total_duration_in_sec = preproc.total_duration_in_sec
blk_idz_list = preproc.blk_idz_list
to_be_sum_up = preproc.to_be_sum_up_passengers_flexi
travels = preproc.travels
to_be_sum_up_travels = preproc.to_be_sum_up_travels
modi = preproc.modi
leaving_the_area = preproc.leaving_the_area

# define colors
normal_node_color = preproc.normal_node_color
bus_stop_color = preproc.bus_stop_color
rdt_stop_color = preproc.rdt_stop_color
tram_stop_color = preproc.tram_stop_color
kindergarten_color = preproc.kindergarten_color
school_color = preproc.school_color
working_place_color = preproc.working_place_color
shopping_place_color = preproc.shopping_place_color
uninhabited_color = preproc.uninhabited_color
inhabited_color = preproc.inhabited_color
borders_color = preproc.borders_color
living_place_color = preproc.living_place_color

# to be sent to overview page
overview_options_df = pd.DataFrame()

# ------------------------------------------------------------------------------

######################
##  App HTML layout ##
######################
### documentation: https://dash.plotly.com/dash-html-components

layout = html.Div([

#---------------------------------------------------------------
# Map_legen + Borough_checklist + Recycling_type_checklist + Web_link + Map
    html.H2("Routeplanungs-Tool für Bedarfsverkehr im Bornstedter Feld", style={'text-align': 'center', 'color': colors['text']}),
    html.Div([
        html.Div([
            html.Div([
            # Map-legend for buildings
            html.Label(['Gebäude:'],style=blackbold),
            html.Ul([
                html.Li("Arbeitsort", style={'background': working_place_color,'color':'black',
                    'list-style':'none','text-indent': '20px', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Einkaufsort", style={'background': shopping_place_color,'color':'black',
                    'list-style':'none','text-indent': '20px','white-space':'nowrap', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Kindergarten", style={'background': kindergarten_color,'color':'black',
                    'list-style':'none','text-indent': '20px', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Schule", style={'background': school_color,'color':'black',
                    'list-style':'none','text-indent': '20px', 'width': '18px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Zukünftige_Wohngebäude", style={'background': 'white', 'border': '1px solid black','color':'black',
                    'list-style':'none','text-indent': '20px', 'width': '16px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'})
            ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}
            ),
            # Map-legend for nodes
            html.Label(['Knoten:'],style=blackbold),
            html.Ul([
                html.Li("Knoten", style={'background': normal_node_color,'color':'black',
                    'list-style':'none','text-indent': '20px', 'white-space':'nowrap','width': '13px', 'height': '13px',  'border-radius': '50%',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Bushaltestelle", style={'background': bus_stop_color,'color':'black',
                    'list-style':'none','text-indent': '20px','white-space':'nowrap', 'width': '13px', 'height': '13px',  'border-radius': '50%',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Tramhaltestelle", style={'background': tram_stop_color,'color':'black',
                    'list-style':'none','text-indent': '20px', 'white-space':'nowrap', 'width': '13px', 'height': '13px',  'font-size': '12px',  'line-height': '15px'}),
                html.Li("Haltestelle Bedarfsverkehr", style={'background': rdt_stop_color,'color':'black', 'text-align':'center',
                    'list-style':'none','text-indent': '20px', 'white-space':'nowrap', 'width': '13px', 'height': '13px',  'border-radius': '50%',  'font-size': '12px',  'line-height': '15px'})
            ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}
            ),
            # Map-legend for streets
            html.Label(['Straßen:'],style=blackbold),
            html.Ul([
                html.Li("Einbahnstraße", style={'background': colors['background'],'color':'black',
                    'list-style':'none','text-indent': '6.5px', 'white-space':'nowrap','width': '0', 'height': '0',  'border-top': '5px solid transparent', 'border-left': '13px solid grey', 'border-bottom': '5px solid transparent', 'font-size': '12px',  'line-height': '15px'}),
                html.Li("Verkehrsverbot für Autos", style={'background': 'solid grey','color':'black', 'text-align':'center',
                    'list-style':'none','text-indent': '20px','white-space':'nowrap', 'width': '13px', 'height': '13px',  'border': '0', 'border-top': '1px dashed #C5BCBA', 'font-size': '12px',  'line-height': '15px'}),
            ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}
            ),
            # manage block visualization
            html.Label(children=['Mögliche zukünftige Bebauung: '], style=blackbold),
            html.Div([
                 dcc.RadioItems(id='viz_future_buildings',
                    options=[{'label':'Einblenden', 'value': 1.0},
                             {'label':'Ausblenden', 'value': 0.0}],
                    value=0.0,
                    labelStyle={'display': 'inline-block', 'color': colors['text']}
                ),
                html.Br(),
            ],style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}),
            html.Br(),
            # Building metrics Dropdown
            html.Label(children=['Metriken für die Gebäude: '], style=blackbold),
            html.Div([
                dcc.Dropdown(id="slct_kpi",
                             options=[
                                 {"label": i, "value": i} for i in metrics],
                             multi=False,
                             value=metrics[0],
                             style={'width': "100%"}
                             ),
                html.Br(),
            ],style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}),
            html.Br(),
            # manage block visualization
            html.Label(children=['Darstellung nach statistischen Blöcken: '], style=blackbold),
            html.Div([
                 dcc.RadioItems(id='viz_blocks',
                    options=[{'label':'Einblenden', 'value': 1.0},
                             {'label':'Ausblenden', 'value': 0.0}],
                    value=0.0,
                    labelStyle={'display': 'inline-block', 'color': colors['text']}
                ),
                html.Br(),
            ],style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}),
            html.Br(),
            # blocks metrics Dropdown
            html.Label(children=['Metriken für die Blöcke: '], style=blackbold),
            html.Div([
                dcc.Dropdown(id="slct_kpi_blk",
                             options=[
                                 {"label": i, "value": i} for i in metrics_blks],
                             multi=False,
                             value=metrics_blks[0],
                             style={'width': "100%"}
                             ),
                html.Br(),
            ],style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}),
            html.Br(),
            # Haltestelle auswählen
            html.Div([
                html.Label(children=["Haltestelle auswählen"], style=blackbold),
                html.P(children=['Um eine Haltestelle auszuwählen klicken Sie auf einen der Knoten auf der Karte.']),
                html.Pre(id='click_data'),
                 ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}),
            html.Br(),
            
        ], className='three columns'
        ),

        # Map
        html.Div([
            dcc.Graph(id='choropleth', clickData=None, hoverData=None, config={'displayModeBar': True,
                                                                               'staticPlot': False,
                                                                               'watermark': False,
                                                                               'showTips': False, 
                                                                               'doubleClick': False,  # 'reset', 'autosize' or 'reset+autosize', False
                                                                               'scrollZoom': True},
                style={'padding-bottom':'2px','padding-left':'2px','height':'110vh'}
            )
        ], className='nine columns'
    ),
    html.Br(),
    ], className='twelwe columns', style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px',
                                           'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    # Block data viz
    html.Div([
    html.H3(children=["Daten zum ausgewählten Block"], style={'text-align': 'center', 'color': colors['text']}),
    html.Div(id='hover_data_display', children=[], style={'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Div([
        dcc.Graph(id='age_group_distribution', config={'displayModeBar': False,
                                                                               'staticPlot': False,
                                                                               'watermark': False,
                                                                               'showTips': False, 
                                                                               'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                                                                               'scrollZoom': False}),
        ], style={'width': '25%', 'float': 'left', 'display': 'inline-block', 'color': colors['text']}
    ),
    html.Div([
        dcc.Graph(id='buildings_typology_distribution', config={'displayModeBar': False,
                                                                           'staticPlot': False,
                                                                           'watermark': False,
                                                                           'showTips': False, 
                                                                           'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                                                                           'scrollZoom': False})
        ],style={'width': '25%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
    ),
    html.Div([
        dcc.Graph(id='household_distribution', config={'displayModeBar': False,
                                                                               'staticPlot': False,
                                                                               'watermark': False,
                                                                               'showTips': False, 
                                                                               'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                                                                               'scrollZoom': False}),
        ], style={'width': '25%', 'float': 'left', 'display': 'inline-block', 'color': colors['text']}
    ),
    html.Div([
        dcc.Graph(id='house_typology_distribution', config={'displayModeBar': False,
                                                                           'staticPlot': False,
                                                                           'watermark': False,
                                                                           'showTips': False, 
                                                                           'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                                                                           'scrollZoom': False})
        ],style={'width': '25%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
    ),
    ]),
    html.Br(),
    # Checkbox button
    html.Div([
        html.Div([
            html.Label(children=['Verkehrsmittel:'], style=blackbold),
                dcc.RadioItems(id='slct_modi',
                        options=[{'label':str(x),'value':x} for x in modi],
                        value=modi[3],
                        labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
                ),
            ], style={'width': '50%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            html.Label(children=['Ziel:'], style=blackbold),
                dcc.RadioItems(id='destination',
                        options=[{'label':str(x),'value':x} for x in leaving_the_area],
                        value=leaving_the_area[0],
                        labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
                ),
            ],style={'width': '50%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
    ]),

    html.Div([
        html.Div([
            dcc.Graph(id="total_trip_duration",
                     config={'displayModeBar': False,
                        'staticPlot': False,
                        'watermark': False,
                        'showTips': False, 
                        'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                        'scrollZoom': False},
                  figure={"layout": {
                "title": "Gesamte Fahrzeiten",
                "height": 500
            }})
            ], style={'width': '50%', 'float': 'left', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            dcc.Graph(id="segmented_trip",
                      config={'displayModeBar': False,
                        'staticPlot': False,
                        'watermark': False,
                        'showTips': False, 
                        'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                        'scrollZoom': False},
                  figure={"layout": {
                "title": "Segmentierte Fahrzeiten",
                "height": 500
            }})
            ],style={'width': '50%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
        ),
    ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px',
                                           'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),    
    # Table
    html.H3(children='Reihenfolge der Haltestellen', style={'margin-top': '20px', 'text-align': 'center', 'color': colors['text']}),
        html.Div(id="table", children=[
                generate_table(df_node_viz)
            ], className='row', style={'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    # display total duration and distance
    html.Div(id='display_totals', style={'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    # Delete last stop
    html.Div(children=[
            html.Button('Letzte Haltestelle löschen', id='delete_last_entry'),
        ], style={'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Div(id='confirm_deletion', style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px',
                                           'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    # Histogramm für die Visualisierung des Taktes
    html.H3(children='Definieren Sie Takt und Betriebszeiten', style={'text-align': 'center', 'color': colors['text']}),
    html.Div([
    dcc.Graph(id='frequencies_graph', config={'displayModeBar': False,
                                                                               'staticPlot': False,
                                                                               'watermark': False,
                                                                               'showTips': False, 
                                                                               'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                                                                               'scrollZoom': False})
    ], className='row'),
    html.Div([
    dcc.Graph(id='buffer_graph', config={'displayModeBar': False,
                                                                               'staticPlot': False,
                                                                               'watermark': False,
                                                                               'showTips': False, 
                                                                               'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                                                                               'scrollZoom': False})
    ], className='row'),
    html.Br(),
    # Service Zeiten definieren
    html.Label(children=["Definieren Sie bitte die Betriebszeit"], style=blackbold),            
    html.Div([
        dcc.RangeSlider(
                id='service-range-slider',
                min=0,
                max=23,
                value=[5,23],
                marks={
                    0: {'label': '0', 'style': {'font-size': small_font}},
                    1: {'label': '1', 'style': {'font-size': small_font}},
                    2: {'label': '2', 'style': {'font-size': small_font}},
                    3: {'label': '3', 'style': {'font-size': small_font}},
                    4: {'label': '4', 'style': {'font-size': small_font}},
                    5: {'label': '5', 'style': {'font-size': small_font}},
                    6: {'label': '6', 'style': {'font-size': small_font}},
                    7: {'label': '7', 'style': {'font-size': small_font}},
                    8: {'label': '8', 'style': {'font-size': small_font}},
                    9: {'label': '9', 'style': {'font-size': small_font}},
                    10: {'label': '10', 'style': {'font-size': small_font}},
                    11: {'label': '11', 'style': {'font-size': small_font}},
                    12: {'label': '12', 'style': {'font-size': small_font}},
                    13: {'label': '13', 'style': {'font-size': small_font}},
                    14: {'label': '14', 'style': {'font-size': small_font}},
                    15: {'label': '15', 'style': {'font-size': small_font}},
                    16: {'label': '16', 'style': {'font-size': small_font}},
                    17: {'label': '17', 'style': {'font-size': small_font}},
                    18: {'label': '18', 'style': {'font-size': small_font}},
                    19: {'label': '19', 'style': {'font-size': small_font}},
                    20: {'label': '20', 'style': {'font-size': small_font}},
                    21: {'label': '21', 'style': {'font-size': small_font}},
                    22: {'label': '22', 'style': {'font-size': small_font}},
                    23: {'label': '23', 'style': {'font-size': small_font}}},
                allowCross=False
            ),
            html.Div(id='service-slider-output-container')
        ]),
    html.Br(),
    ### First column > HVK
    html.Div([
        html.H4(["Hauptverkehrszeit"]),
        html.Label(children=["Definieren Sie bitte die HVZ // Vormittag"], style=blackbold),            
        html.Div([
            dcc.RangeSlider(
                    id='hvk-range-slider',
                    min=0,
                    max=23,
                    value=[8,11],
                    marks={
                        0: {'label': '0', 'style': {'font-size': small_font}},
                        1: {'label': '1', 'style': {'font-size': small_font}},
                        2: {'label': '2', 'style': {'font-size': small_font}},
                        3: {'label': '3', 'style': {'font-size': small_font}},
                        4: {'label': '4', 'style': {'font-size': small_font}},
                        5: {'label': '5', 'style': {'font-size': small_font}},
                        6: {'label': '6', 'style': {'font-size': small_font}},
                        7: {'label': '7', 'style': {'font-size': small_font}},
                        8: {'label': '8', 'style': {'font-size': small_font}},
                        9: {'label': '9', 'style': {'font-size': small_font}},
                        10: {'label': '10', 'style': {'font-size': small_font}},
                        11: {'label': '11', 'style': {'font-size': small_font}},
                        12: {'label': '12', 'style': {'font-size': small_font}},
                        13: {'label': '13', 'style': {'font-size': small_font}},
                        14: {'label': '14', 'style': {'font-size': small_font}},
                        15: {'label': '15', 'style': {'font-size': small_font}},
                        16: {'label': '16', 'style': {'font-size': small_font}},
                        17: {'label': '17', 'style': {'font-size': small_font}},
                        18: {'label': '18', 'style': {'font-size': small_font}},
                        19: {'label': '19', 'style': {'font-size': small_font}},
                        20: {'label': '20', 'style': {'font-size': small_font}},
                        21: {'label': '21', 'style': {'font-size': small_font}},
                        22: {'label': '22', 'style': {'font-size': small_font}},
                        23: {'label': '23', 'style': {'font-size': small_font}}},
                    allowCross=False
                ),
                html.Div(id='hvk-slider-output-container'),
                html.Br(),
                # HVK und NVK Zeiten definieren
                html.Label(children=["Definieren Sie bitte die HVZ // Nachmittag"], style=blackbold),            
                html.Div([
                    dcc.RangeSlider(
                            id='hvk2-range-slider',
                            min=0,
                            max=23,
                            value=[14,19],
                            marks={
                                0: {'label': '0', 'style': {'font-size': small_font}},
                                1: {'label': '1', 'style': {'font-size': small_font}},
                                2: {'label': '2', 'style': {'font-size': small_font}},
                                3: {'label': '3', 'style': {'font-size': small_font}},
                                4: {'label': '4', 'style': {'font-size': small_font}},
                                5: {'label': '5', 'style': {'font-size': small_font}},
                                6: {'label': '6', 'style': {'font-size': small_font}},
                                7: {'label': '7', 'style': {'font-size': small_font}},
                                8: {'label': '8', 'style': {'font-size': small_font}},
                                9: {'label': '9', 'style': {'font-size': small_font}},
                                10: {'label': '10', 'style': {'font-size': small_font}},
                                11: {'label': '11', 'style': {'font-size': small_font}},
                                12: {'label': '12', 'style': {'font-size': small_font}},
                                13: {'label': '13', 'style': {'font-size': small_font}},
                                14: {'label': '14', 'style': {'font-size': small_font}},
                                15: {'label': '15', 'style': {'font-size': small_font}},
                                16: {'label': '16', 'style': {'font-size': small_font}},
                                17: {'label': '17', 'style': {'font-size': small_font}},
                                18: {'label': '18', 'style': {'font-size': small_font}},
                                19: {'label': '19', 'style': {'font-size': small_font}},
                                20: {'label': '20', 'style': {'font-size': small_font}},
                                21: {'label': '21', 'style': {'font-size': small_font}},
                                22: {'label': '22', 'style': {'font-size': small_font}},
                                23: {'label': '23', 'style': {'font-size': small_font}}},
                            allowCross=False
                        ),
            html.Div(id='hvk2-slider-output-container'),
            html.Br(),
            # HVK Route takt definieren
            html.Label(children=["Definieren Sie bitte den Takt für die HVZ"], style=blackbold),
            html.Div([
            dcc.Slider(
                    id='hvk-frequency-slider',
                    min=1,
                    max=59,
                    step=1,
                    value=20,
                    marks={
                        1: {'label': '1'},
                        10: {'label': '10'},
                        20: {'label': '20'},
                        30: {'label': '30'},
                        40: {'label': '40'},
                        50: {'label': '50'},
                        59: {'label': '59'}},
                    updatemode='drag',
                    included=False
                ),
                html.Div(id='hvk-frequency-slider-output-container')
            ]),
            ])
        ]),
    ], style = {'vertical-align':'bottom', 'width': '33%', 'display': 'inline-block'}),
    ### Second column > NVK
    html.Div([
        html.H4(["Nebensverkehrszeit"]),
        # NVK Route takt definieren
        html.Label(children=["Definieren Sie bitte den Takt für die NVZ"], style=blackbold),
        html.Div([
        dcc.Slider(
                id='nvk-frequency-slider',
                min=1,
                max=59,
                step=1,
                value=20,
                marks={
                    1: {'label': '1'},
                    10: {'label': '10'},
                    20: {'label': '20'},
                    30: {'label': '30'},
                    40: {'label': '40'},
                    50: {'label': '50'},
                    59: {'label': '59'}},
                updatemode='drag',
                included=False
            ),
            html.Div(id='nvk-frequency-slider-output-container')
        ])
    ], style = {'vertical-align':'top', 'width': '33%', 'display': 'inline-block', 'float': 'center'}),
    html.Div([
   # Nacht Service definieren
        html.Div([
            html.H4(["Nachtverkehrszeit"]),
            html.Label(children=["Definieren Sie bitte den Anfang der NaVZ"], style=blackbold),            
            dcc.Slider(
                    id='night-range-slider',
                    min=0,
                    max=23,
                    value=21,
                    marks={
                        0: {'label': '0', 'style': {'font-size': small_font}},
                        1: {'label': '1', 'style': {'font-size': small_font}},
                        2: {'label': '2', 'style': {'font-size': small_font}},
                        3: {'label': '3', 'style': {'font-size': small_font}},
                        4: {'label': '4', 'style': {'font-size': small_font}},
                        5: {'label': '5', 'style': {'font-size': small_font}},
                        6: {'label': '6', 'style': {'font-size': small_font}},
                        7: {'label': '7', 'style': {'font-size': small_font}},
                        8: {'label': '8', 'style': {'font-size': small_font}},
                        9: {'label': '9', 'style': {'font-size': small_font}},
                        10: {'label': '10', 'style': {'font-size': small_font}},
                        11: {'label': '11', 'style': {'font-size': small_font}},
                        12: {'label': '12', 'style': {'font-size': small_font}},
                        13: {'label': '13', 'style': {'font-size': small_font}},
                        14: {'label': '14', 'style': {'font-size': small_font}},
                        15: {'label': '15', 'style': {'font-size': small_font}},
                        16: {'label': '16', 'style': {'font-size': small_font}},
                        17: {'label': '17', 'style': {'font-size': small_font}},
                        18: {'label': '18', 'style': {'font-size': small_font}},
                        19: {'label': '19', 'style': {'font-size': small_font}},
                        20: {'label': '20', 'style': {'font-size': small_font}},
                        21: {'label': '21', 'style': {'font-size': small_font}},
                        22: {'label': '22', 'style': {'font-size': small_font}},
                        23: {'label': '23', 'style': {'font-size': small_font}}},
                updatemode='drag',
                included=False
                ),
                html.Div(id='night-slider-output-container'),
                html.Br(),
                # Night Route takt definieren
                html.Label(children=["Definieren Sie bitte den Takt für die NaVZ"], style=blackbold),
                html.Div([
                dcc.Slider(
                        id='night-frequency-slider',
                        min=1,
                        max=59,
                        step=1,
                        value=20,
                        marks={
                            1: {'label': '1'},
                            10: {'label': '10'},
                            20: {'label': '20'},
                            30: {'label': '30'},
                            40: {'label': '40'},
                            50: {'label': '50'},
                            59: {'label': '59'}},
                        updatemode='drag',
                        included=False
                    ),
                    html.Div(id='night-frequency-slider-output-container')
                ]),
            ]),
    ], style = {'vertical-align':'top', 'width': '33%', 'display': 'inline-block', 'float': 'right'}),
    html.Br(), 
    html.Br(),
    html.Br(),
    # Kapazität RDT definieren
    html.Label(children=["Bitte wählen Sie die Gefäßgröße aus"], style=blackbold),
    html.Div([
    dcc.Slider(
            id='capacity-slider',
            min=6,
            max=60,
            step=None,
            value=8,
            marks={
                6: {'label': 'T6'},
                8: {'label': 'Van', 'style': {'text-indent': '20px'}},
                30: {'label': 'Kleinbus'},
                60: {'label': 'Solobus'}},
            updatemode='drag',
            included=False
        ),
        html.Div(id='capacity-slider-output-container')
    ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'})]),
    html.Br(),
    # demand criteria
    html.H3("Nachfragesteuerung", style={'text-align': 'center', 'color': colors['text']}),
    html.Label(children=["Bitte definieren Sie den Anteil der Fahrgäste, der an der Tür abgeholt werden kann"], style={'text-align': 'center', 'color':'black', 'font-weight': 'bold'}),            
    html.Div([
            dcc.Slider(
                    id='perc-home-pick-up-range-slider',
                    min=0,
                    max=100,
                    step=1,
                    value = 8,
                    marks={
                        0: {'label': '0 %', 'style': {'font-size': small_font}},
                        8: {'label': '8 %', 'style': {'font-size': small_font}},
                        10: {'label': '10 %', 'style': {'font-size': small_font}},
                        20: {'label': '20 %', 'style': {'font-size': small_font}},
                        30: {'label': '30 %', 'style': {'font-size': small_font}},
                        40: {'label': '40 %', 'style': {'font-size': small_font}},
                        50: {'label': '50 %', 'style': {'font-size': small_font}},
                        60: {'label': '60 %', 'style': {'font-size': small_font}},
                        70: {'label': '70 %', 'style': {'font-size': small_font}},
                        80: {'label': '80 %', 'style': {'font-size': small_font}},
                        90: {'label': '90 %', 'style': {'font-size': small_font}},
                        100: {'label': '100 %', 'style': {'font-size': small_font}}}
                    ),
                html.Div(id='perc-home-pick-up-output-container')
            ]),
    html.Div(children = [],style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px',
                                        'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    # Route name angeben
    html.H3(children='Route benennen und speichern', style={'text-align': 'center', 'color': colors['text']}),
    html.Label(children=["Geben Sie bitte der Route einen Name"], style={'text-align': 'center', 'color':'black', 'font-weight': 'bold'}),
    html.Div(["Name: ",
              dcc.Input(id='my-input', value='initial value', type='text'),
              ], style={'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    html.Div(id='my-output', style={'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    # Save Button
    html.Div(children=[
        html.Button('Route speichern', id='save_data'),
        ], style={'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    html.Div(id='confirm_save', style={'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    html.Div(id="temp_div"),
    html.Div(children=[
        html.Div(children = [], id='next_step_left', style = {'float':'left', 'width':'33%', 'display':'flex', 'justify-content':'center', 'align-items':'center'}),
        html.Div(children = [], id='next_step_right', style = {'float':'right', 'width':'33%', 'display':'flex', 'justify-content':'center', 'align-items':'center'})
        ], style={'display':'flex', 'justify-content':'center', 'align-items':'center', 'width':"100%", 'float':'center'}),
    html.Div(id='next_step2', style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px',
                                        'display':'flex', 'justify-content':'center', 'align-items':'center'})
], className='twelwe columns'
)

#####################
##  App Callbacks ##
####################
# Connect the Plotly graphs with Dash Components
### each element with an identifier must be referenced here as output or input

#### callback for map > display and update the map
@app.callback(
    Output(component_id='choropleth', component_property='figure'),
    Input(component_id='slct_kpi', component_property='value'),
    Input(component_id='slct_kpi_blk', component_property='value'),
    Input(component_id='choropleth', component_property='clickData'),
    Input(component_id='viz_blocks', component_property='value'),
    Input(component_id='viz_future_buildings', component_property='value')
    #Input(component_id='node_types', component_property='value')
)

def update_graph(slct_kpi, slct_kpi_blk, clickData, viz_blocks, viz_future_buildings):
                 #option_slct_house_types,
                 #option_slct_nodes):
    global fig_custom
                     
    #------------1st layer BLOCKS------------#
    opacity_blks = viz_blocks
        
    # Plotly shape map with mapbox background - static - working buildings
    fig_custom = px.choropleth_mapbox(
        data_frame=blocks,
        geojson=blocks.geometry,
        locations=blocks.index,
        center={"lat": 52.42241, "lon": 13.04000},
        zoom=13,
        opacity= opacity_blks,
        color= slct_kpi_blk,
        color_continuous_scale='OrRd_r',
        #color_discrete_map={'bewohnt':inhabited_color ,'unbewohnt':uninhabited_color},
        hover_name="blk_idz")

    # define layout
    fig_custom.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'],
        showlegend=False,
        coloraxis_colorbar=dict(ticksuffix=" mt"))
        
    #------------2nd layer LIVING BUILDING------------#

    # Plotly choropleth map with mapbox background - static - living buildings
    
    # Plotly map with mapbox background - selecting columns
    fig_living = px.choropleth_mapbox(
        data_frame=living_building,
        geojson=living_building.geometry,
        color=slct_kpi,
        locations=living_building.index,
        color_continuous_scale='OrRd_r',
        center={"lat": 52.42241, "lon": 13.04000},
        zoom=14,
        range_color=[0, max(living_building[slct_kpi])])

    # define layout
    fig_living.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'],
        coloraxis_colorbar=dict(ticksuffix=" mt"))

    # remove buildings borders
    fig_living.update_traces(marker_line_width=0)
        
    ## add shape trace
    fig_custom.add_trace(fig_living.data[0]) 

    #------------3rd layer EDUCATION BUILDING------------#

    # Plotly shape map with mapbox background - static - educational buildings
    fig_custom_edu = px.choropleth_mapbox(
        data_frame=edu,
        geojson=edu.geometry,
        color="type",
        locations=edu.index,
        center={"lat": 52.42241, "lon": 13.03000},
        zoom=14,
        color_discrete_map={'Kindergarten':kindergarten_color,'Schule':school_color})
    
    # define layout
    fig_custom_edu.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'],
        showlegend=False)
    
    # remove buildings borders
    fig_custom_edu.update_traces(marker_line_width=0)

    ## add shape trace
    fig_custom.add_trace(fig_custom_edu.data[0])    
    fig_custom.add_trace(fig_custom_edu.data[1])

    #------------4th layer WORKING BUILDING------------#

    # Plotly shape map with mapbox background - static - working buildings
    fig_custom_build = px.choropleth_mapbox(
        data_frame=building,
        geojson=building.geometry,
        color='type',
        locations=building.index,
        center={"lat": 52.42241, "lon": 13.04000},
        zoom=14,
        color_discrete_map={'working_place':working_place_color,'shopping_place':shopping_place_color})

    # define layout
    fig_custom_build.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'],
        showlegend=False)

    # remove buildings borders
    fig_custom_build.update_traces(marker_line_width=0)

    ## add shape trace
    fig_custom.add_trace(fig_custom_build.data[0]) 
    fig_custom.add_trace(fig_custom_build.data[1])

    #------------5th layer NODES------------#

    # Plotly scatterplot for nodes
    
    if clickData is None:
        nodes_sub = preproc.nodes
    else:
        global fid
        fid = clickData['points'][0]['pointNumber'] + 1
        nodes.loc[(nodes['fid'] == fid), 'color'] = rdt_stop_color
        nodes.loc[(nodes['fid'] == fid), 'size'] = 5
        nodes_sub = nodes
    #nodes_sub = nodes[(nodes['type'].isin(option_slct_nodes))]
    nodes_sub = nodes
    
    fig_scatter = px.scatter_mapbox(nodes_sub,
                            color_discrete_sequence=[nodes_sub.color],
                            lat='lon',
                            lon='lat',
                            size='size',
                            opacity=nodes_sub.opacity,
                            hover_name="fid",
                            center={"lat": 52.42241, "lon": 13.04000},
                            zoom=14)
    
    fig_scatter.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'])

    ## add scatter trace
    fig_custom.add_trace(fig_scatter.data[0])

    #------------6th layer TRAM STOPS------------#

    # Plotly scatterplot for tramstop
    fig_scatter_tram = px.scatter_mapbox(tram_stops,
                            lat='lon',
                            lon='lat',
                            size='size',
                            color_discrete_sequence=[tram_stops.color],
                            hover_name="name",
                            opacity  = 0.0,
                            center={"lat": 52.42241, "lon": 13.04000},
                            zoom=14)
    
    fig_scatter_tram.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'])

    ## add scatter trace
    fig_custom.add_trace(fig_scatter_tram.data[0])

     #------------7th layer BUILDING LIVING------------#

    # Plotly choropleth map with mapbox background - static - living buildings
    opacity_future_buildings = viz_future_buildings
    
    # Plotly map with mapbox background - selecting columns
    fig_future_living = px.choropleth_mapbox(
        data_frame=future_building,
        geojson=future_building.geometry,
        color=slct_kpi,
        locations=future_building.index,
        color_continuous_scale='OrRd_r',
        center={"lat": 52.42241, "lon": 13.04000},
        zoom=14,
        opacity= opacity_future_buildings,
        range_color=[0, max(future_building[slct_kpi])])

    # define layout
    fig_future_living.update_layout(
        margin={"r":0,"t":0,"l":0,"b":0},
        mapbox_accesstoken=token,
        mapbox_style = selected_style,
        plot_bgcolor=colors['background'],
        paper_bgcolor=colors['background'],
        font_color=colors['text'],
        coloraxis_colorbar=dict(ticksuffix=" mt"))

    # highlight buildings borders
    fig_future_living.update_traces(marker_line_width=2)
        
    ## add shape trace
    fig_custom.add_trace(fig_future_living.data[0]) 
    
    # the n of returnerd element must match the n of output elements in the app.callback
    return fig_custom

### callback for visualizing the distribution of blocks
@app.callback(
    Output(component_id="house_typology_distribution", component_property='figure'),
    Output(component_id='household_distribution', component_property='figure'),
    Output(component_id="age_group_distribution", component_property='figure'),
    Output(component_id='buildings_typology_distribution', component_property='figure'),
    Output(component_id="hover_data_display", component_property='children'),
    Input(component_id='choropleth', component_property='hoverData')
)

### keep on working here > goal is to visualize data for the blocks > the data and data prep steps on modifie sql block table should be added and than the data from pointing on it
def blocks_histo1(hoverData):
    global blk_idz_list
    if hoverData is None:
        raise PreventUpdate
    else:
        slct_blk = hoverData['points'][0]['hovertext']
        if slct_blk not in blk_idz_list:
            raise PreventUpdate
        else:
            str_temp = str(blocks.loc[blocks['blk_idz'] == slct_blk, 'house_types_in_block'].values)
            str_temp = str_temp.replace("[", "")
            str_temp = str_temp.replace("]", "")
            str_temp = str_temp.replace('"', "")
            li = list(str_temp.split(","))
            df_li_1 = pd.DataFrame(li, columns = ['house_types_in_block'])
            df_li_1 = df_li_1.rename(columns={'house_types_in_block': 'Wohngebäuden'})
            fig_histo_blocks1 = px.histogram(df_li_1, x='Wohngebäuden',  title="Wohngebäude nach Typologien", labels=dict(y = "Anzahl"))
            fig_histo_blocks1.update_traces(
                marker_color='rgb(158,202,225)', marker_line_color='rgb(8,48,107)',
                      marker_line_width=1.5, opacity=0.6)
            
            str_temp2 = str(blocks.loc[blocks['blk_idz'] == slct_blk, 'household_categories_in_block'].values)
            str_temp2 = str_temp2.replace("[", "")
            str_temp2 = str_temp2.replace("]", "")
            str_temp2 = str_temp2.replace('"', "")
            li2 = list(str_temp2.split(","))
            df_li_2 = pd.DataFrame(li2, columns = ['Haushalte'])
            df_li_2 = df_li_2.rename(columns={'household_categories_in_block': 'Haushalte'})
            fig_histo_blocks2 = px.histogram(df_li_2, x='Haushalte',  title="Haushalte nach Typologien", labels=dict(y = "Anzahl", x="Haushalte"))
            fig_histo_blocks2.update_traces(
                marker_color='rgb(158,202,225)', marker_line_color='rgb(8,48,107)',
                      marker_line_width=1.5, opacity=0.6)
                    
            hist_age_data = (blocks.loc[blocks['blk_idz'] == slct_blk, '0-to-3':'85+']).T
            fig_age_dist = px.bar(x = hist_age_data.index, y = hist_age_data.iloc[:,0],  title="Personen nach Altersgruppen", labels=dict(y = "Anzahl", x="Personen"))
            fig_age_dist.update_traces(
                marker_color='rgb(158,202,225)', marker_line_color='rgb(8,48,107)',
                      marker_line_width=1.5, opacity=0.6)
            
            hist_building_data = (blocks.loc[blocks['blk_idz'] == slct_blk, 'Arbeitsorte':'Schulen']).T
            fig_buildings_dist = px.bar(x = hist_building_data.index, y = hist_building_data.iloc[:,0], title="Gebäude nach Nutzungszweck", labels=dict(y = "Anzahl", x="Gebäuden"))
            fig_buildings_dist.update_traces(
                marker_color='rgb(158,202,225)', marker_line_color='rgb(8,48,107)',
                      marker_line_width=1.5, opacity=0.6)
            
            tot_pop = str(int(blocks.loc[blocks['blk_idz'] == slct_blk, 'tot'].values))
            area = str(round(float(blocks.loc[blocks['blk_idz'] == slct_blk, 'area'].values), 2))
            density = str(round(float(blocks.loc[blocks['blk_idz'] == slct_blk, 'density'].values), 2))
            overall_block_infos = 'Im Block {} wohnen {} Personen auf einer Fläche von {} qkm, was in einer Dichte von {} Personen pro qkm entspricht'.format(slct_blk, tot_pop, area, density)
    return fig_histo_blocks1, fig_histo_blocks2, fig_age_dist, fig_buildings_dist, overall_block_infos

### callback for visualizing the basci scenrio data by block
@app.callback(
    Output(component_id="total_trip_duration", component_property='figure'),
    Output(component_id='segmented_trip', component_property='figure'),
    Input(component_id='choropleth', component_property='hoverData'),
    Input(component_id='slct_modi', component_property='value'),
    Input(component_id='destination', component_property='value')
)

### keep on working here > goal is to visualize data for the blocks > the data and data prep steps on modifie sql block table should be added and than the data from pointing on it
def blocks_basic_scenario_data(hoverData, slct_modi, destination):
    global blk_idz_list
    if hoverData is None:
        raise PreventUpdate
    else:
        slct_blk = hoverData['points'][0]['hovertext']
        plot_df = travels[(travels['modi'] == slct_modi) & (travels['block'] == slct_blk) & (travels['leaving_the_area'] == destination)]
        fig_trip_segmented = px.bar(plot_df, x="start_trip_time", y=to_be_sum_up_travels, 
              labels={'start_trip_time':'Tageszeit', 'Fahrzeit':'Fahrzeit in Min.'})
        fig_trip_segmented.update_layout(
            xaxis={
                "rangeslider": {"visible": True},
            })
        
        fig_total_duration = px.scatter(plot_df, x="start_trip_time", y="trip_duration", color = "modi",
                          hover_name="trip_duration2", hover_data=["trip_duration2"], 
              labels={'start_trip_time':'Tageszeit', 'trip_duration':'Fahrzeit in Min.'})
        return fig_total_duration, fig_trip_segmented

#### callback for the clicks on map > display id of the clicked node and update table
@app.callback(
    Output(component_id='click_data', component_property='children'),
    Output(component_id='table', component_property='children'),
    Output(component_id='display_totals', component_property='children'),
    Input(component_id='choropleth', component_property='clickData')
)

def display_click_data(clickData):
    if clickData is None:
        raise PreventUpdate
    else:
        global df_node_inter
        global bus_route_counter
        global df_node_viz
        global fid
        global n_of_stops
        global durations
        global distances
        global total_duration
        global total_distance
        global total_duration_in_sec
        # the if of the clicked point is increased by one to match the fid column
        fid = clickData['points'][0]['pointNumber'] + 1
        # a temp df is created by slicing the df_node by fid
        temp = df_node[df_node.fid == fid]
        # an incremental value is added for visualizing the sequence of stops
        temp.new_bus_line = bus_route_counter
        # the sequence value is increased
        bus_route_counter += 1
        # the new stop is added to a second df
        df_node_inter = df_node_inter.append(temp)
        # the second df is sliced to get only relevant columns
        df_node_viz = df_node_inter[['fid', 'lat', 'lon', 'new_bus_line']]
        # friendly column names are defined
        df_node_viz.columns = ['ID', 'Lat', 'Lon', 'Reihenfolge']
        # the n of stops is calculated as the length of the dataframe
        n_of_stops = len(df_node_viz)
        # the output string is defined for the case that more only one stop has been designated
        overall_infos = 'Die geplante Route enthält 1 Haltestelle'
        if len(df_node_viz) > 1:
            # select lat lon cols
            latlon = df_node_viz[["Lat", "Lon"]]
            # select last two rows
            latlon = latlon.iloc[[-2, -1]]
            # stack from 2x2 to 4x1
            latlon = latlon.stack()
            # transform col in a series
            to_append = list(latlon)
            routing_df = pd.DataFrame(columns = ["origin_longitude", "origin_latitude", "destination_longitude", "destination_latitude"])
            a_series = pd.Series(to_append, index = routing_df.columns)
            # append and transform to 1x4
            routing_df = routing_df.append(a_series, ignore_index=True)
            routing_df = routing_df.astype('float64')
            # apply the function that call the api
            routing_df.apply(create_driving_route, axis=1)
            # the function save a csv that is read again here (can be optimized...)            
            routing_res_df = pd.read_csv('routing_res_df.csv',index_col=0)
            # values are appended to the list of durations and distances(initially filled with only a zero for the first stop...)
            durations.append(routing_res_df.iloc[0]['Fahrzeit_zwischen_Haltestellen'].round())
            distances.append(routing_res_df.iloc[0]['Distanz_zwischen_Haltestellen_in_mt'])
            # two empty columns for distance and duration is added to df_node_viz
            df_node_viz['Distanz zwischen Haltestellen in mt'] = np.nan
            df_node_viz['Fahrzeit zwischen Haltestellen'] = np.nan
            # the columns are filled with values coming from the lists
            df_node_viz['Distanz zwischen Haltestellen in mt'] = distances
            df_node_viz['Fahrzeit zwischen Haltestellen'] = durations
            # function for friendly time visualization are applied
            df_node_viz['Fahrzeit zwischen Haltestellen'] = df_node_viz['Fahrzeit zwischen Haltestellen'].map(display_time)
            # total distance and duration are calculated on the corresponding lists
            total_distance = int(sum(distances))
            total_duration_in_sec = sum(durations) + (n_of_stops - 1) * stop_duration
            total_duration = display_time(total_duration_in_sec)
            # the output string is defined for the case that more than two stops have been designated
            overall_infos = 'Die geplante Route enthält {} Haltestellen mit einer gesamten Streckenlänge von {} Meter und einer Dauer von {} (inkl. 20 Sek. pro Stopp)'.format(len(df_node_viz), total_distance, total_duration)
        return 'ID des angeklickten Knotens:{}'.format(fid), generate_table(df_node_viz), overall_infos
    
#### callback for the button > send route to postgres
@app.callback(
    Output(component_id='confirm_save', component_property='children'),
    Output(component_id='next_step_left', component_property='children'),
    Output(component_id='next_step_right', component_property='children'),
    Input(component_id='save_data', component_property='n_clicks')
)
def save_button(n_clicks):
    if n_clicks is None:
        raise PreventUpdate
    else:
        global list_of_inputs
        global table_name
        global hvk_frequency
        global nvk_frequency
        global night_frequency
        global capacity
        global n_of_stops
        global rdt_general_timetable
        global bus_frequencies
        global df_node_inter
        global overview_options_df
        global total_duration
        global total_distance
        global perc_door_pick_up
        # save a df with the options to postgres
        list_of_inputs.insert(0, table_name)
        list_of_inputs.insert(1, hvk_frequency)
        list_of_inputs.insert(2, nvk_frequency)
        list_of_inputs.insert(3, night_frequency)
        list_of_inputs.insert(4, capacity)
        list_of_inputs.insert(5, n_of_stops)
        list_of_inputs.insert(6, total_duration)
        list_of_inputs.insert(7, total_distance)
        list_of_inputs.insert(8, perc_door_pick_up)
        rdt_options_df = pd.DataFrame([list_of_inputs], columns=['scenario', 'hvk_frequency', 'nvk_frequency', 'night_frequency', 'capacity', 'n_of_stops', 'total_duration', 'total_distance', 'perc_of_door_pick_up'])
        overview_options_df = overview_options_df.append(rdt_options_df, ignore_index = True)
        overview_options_df.to_sql('overview_options_df', engine, if_exists='replace')
        rdt_options_df.to_sql(str(table_name + '_options_df'), engine, if_exists='replace')
        
        # save a df with the node ids of the rdt bus stops
        temp = df_node_inter[['fid', 'new_bus_line']]
        temp.to_sql(str(table_name + '_nodes_df'), engine, if_exists='replace')
        nodes_res = pd.DataFrame()
        nodes_res = nodes.merge(temp, on='fid', how='left')
        nodes_res = nodes_res.drop(columns=['bus_stop', 'lon', 'lat', 'color', 'size'])
        nodes_res = nodes_res.to_crs(epsg='25833')
        nodes_res.to_postgis(str(table_name + '_nodes'), engine, if_exists='replace')



        # save the figure
        fig_custom.write_image(str("apps/img/" + table_name + "fig.png"))

        # create a short bus_frequencies df
        bus_frequencies_short = bus_frequencies.iloc[:, 0:3]
        
        # save a df with the timetable
        for index, row in bus_frequencies_short.iterrows():
            timetable_out = pd.DataFrame(index=np.arange(bus_frequencies_short.bus_per_hour[index]), columns=['route_short_name', 'departure_hour', 'departure_minute'])
            timetable_out.departure_hour = bus_frequencies_short.hour[index]
            timetable_out.route_short_name = 'new_bus_a'
            timetable_out.departure_minute = bus_frequencies_short.takt[index] * range(bus_frequencies_short.bus_per_hour[index])      
            timetable_back = timetable_out
            timetable_back.route_short_name = 'new_bus_b'
            rdt_general_timetable = rdt_general_timetable.append(timetable_out, ignore_index=True)
            rdt_general_timetable = rdt_general_timetable.append(timetable_back, ignore_index=True)
            rdt_general_timetable = rdt_general_timetable.sort_values(by=['departure_hour', 'departure_minute', 'route_short_name'])
        
        rdt_general_timetable.to_sql(str(table_name + '_rdt_timetable'), engine, if_exists='replace')
        #rdt_general_timetable.to_csv(str('/output/' + table_name + '_rdt_timetable.csv'), index=False)
        rdt_general_timetable.to_csv(str(table_name + '_rdt_timetable.csv'), index=False)
        reset_dataframes()
        #return 'Route erfolgreich gespeichert!', html.A(html.Button('Ein weiteres Szenario definieren', id='show_next_steps_left'), href='/apps/route_planning'), html.A(html.Button('Geh zum Überblick der Szenarien', id='show_next_steps_right'), href='/apps/scenarios_overview')
        return 'Route erfolgreich gespeichert!', html.A(html.Button('Ein weiteres Szenario definieren', id='show_next_steps_left'), href='/apps/route_planning'), html.A(html.Button('Geh zu den Ergebnissen', id='show_next_steps_right'), href='/apps/scenarios_analysis')
def reset_dataframes():
    global rdt_general_timetable
    global df_node_inter
    global bus_route_counter
    global df_node_viz
    global nodes
    global list_of_inputs
    global hvk_frequency
    global nvk_frequency
    global night_frequency
    global capacity
    global n_of_stops
    global total_distance
    global total_duration
    global distances
    global durations
    global perc_door_pick_up
    global bus_frequencies
    global table_name
    list_of_inputs = []
    table_name = None
    hvk_frequency = None
    nvk_frequency = None
    night_frequency = None
    capacity = None
    n_of_stops = None
    perc_door_pick_up = None
    nodes = preproc.nodes
    rdt_general_timetable = preproc.rdt_general_timetable
    bus_frequencies = preproc.bus_frequencies
    df_node_inter = pd.DataFrame()
    bus_route_counter = preproc.bus_route_counter
    df_node_viz = preproc.df_node_viz
    total_distance = []
    total_duration = []
    distances = [0]
    durations = [0]
    generate_table(df_node_viz)

                    
#### callback for the input form > route name
@app.callback(
    Output(component_id='my-output', component_property='children'),
    Input(component_id='my-input', component_property='value')
)
def update_output_div(input_value):
    global table_name
    global list_of_inputs
    table_name = input_value
    return 'Der Name der Route lautet: {}'.format(input_value)

#### callback for the slider > define hvk frequency
@app.callback(
    Output(component_id='hvk-frequency-slider-output-container', component_property='children'),
    Input(component_id='hvk-frequency-slider', component_property='value')
    )
def update_slider_hvk_frequency(value):
    global hvk_frequency
    hvk_frequency = value
    return 'Der Takt des Bedarfsverkehrs in der HVZ ist auf "{}" Minuten gesetzt'.format(value)

#### callback for the slider > define nvk frequency
@app.callback(
    Output(component_id='nvk-frequency-slider-output-container', component_property='children'),
    Input(component_id='nvk-frequency-slider', component_property='value')
    )
def update_slider_nvk_frequency(value):
    global nvk_frequency
    nvk_frequency = value
    return 'Der Takt des Bedarfsverkehrs in der NVZ ist auf "{}" Minuten gesetzt'.format(value)

#### callback for the slider > define night frequency
@app.callback(
    Output(component_id='night-frequency-slider-output-container', component_property='children'),
    Input(component_id='night-frequency-slider', component_property='value')
    )
def update_slider_night_frequency(value):
    global night_frequency
    night_frequency = value
    return 'Der Takt des Bedarfsverkehrs in der NaVZ ist auf "{}" Minuten gesetzt'.format(value)

#### callback for the slider > define capacity of rdt busses
@app.callback(
    Output(component_id='capacity-slider-output-container', component_property='children'),
    Input(component_id='capacity-slider', component_property='value')
    )
def update_slider_capacity(value):
    global capacity
    capacity = value
    return 'Die maximale Kapazität des Busses ist auf "{}" Fahrgäste gesetzt'.format(value)

#### callback for the button delete last entry
@app.callback(
    Output(component_id='confirm_deletion', component_property='children'),
    Input(component_id='delete_last_entry', component_property='n_clicks')
    )
def delete_button(n_clicks):
    if n_clicks is None:
        raise PreventUpdate
    else:
        global df_node_inter
        global bus_route_counter
        global df_node_viz
        global nodes
        global durations
        global distances
        fid = df_node_inter['fid'].loc[df_node_inter['new_bus_line']==df_node_inter['new_bus_line'].max()].values[0].item()
        nodes.loc[(nodes['fid'] == fid), 'color'] = normal_node_color
        nodes.loc[(nodes['fid'] == fid), 'size'] = 0.1
        df_node_inter = df_node_inter.loc[df_node_inter['new_bus_line']!=df_node_inter['new_bus_line'].max()]
        bus_route_counter -= 1
        df_node_viz = df_node_inter[['fid', 'lat', 'lon', 'new_bus_line']]
        df_node_viz.columns = ['ID', 'Lat', 'Lon', 'Reihenfolge']
        del durations[-1]
        del distances[-1]
        generate_table(df_node_viz)
        return 'Letzter Eintrag erfolgreich gelöscht! Die Tabelle und die Karte werden beim Klicken auf der nächsten Haltestelle aktualisiert'

#### callback for the slider > define service times
@app.callback(
    Output(component_id='service-slider-output-container', component_property='children'),
    Input(component_id='service-range-slider', component_property='value'))
def update_service_time_slider(value):
    return 'Die Fahrte starten um {} und enden um {} Uhr'.format(value[0], value[1])

#### callback for the slider > define hvk time (morning)
@app.callback(
    Output(component_id='hvk-slider-output-container', component_property='children'),
    Input(component_id='hvk-range-slider', component_property='value'))
def update_hvk_time_slider(value):
    return 'Die Hauptverkehrzeit am morgen startet um {} und endet um {} Uhr'.format(value[0], value[1])

#### callback for the slider > define hvk time (afternoon)
@app.callback(
    Output(component_id='hvk2-slider-output-container', component_property='children'),
    Input(component_id='hvk2-range-slider', component_property='value'))
def update_hvk2_time_slider(value):
    return 'Die Hauptverkehrzeit am Nachmittag startet um {} und endet um {} Uhr'.format(value[0], value[1])

#### callback for the slider > define service times
@app.callback(
    Output(component_id='night-slider-output-container', component_property='children'),
    Input(component_id='night-range-slider', component_property='value'))
def update_night_time_slider(value):
    return 'Der Nachverkehr startet um {} Uhr'.format(value)

##### for the percentage of pick up at home services
@app.callback(
    Output(component_id='perc-home-pick-up-output-container', component_property='children'),
    Input(component_id='perc-home-pick-up-range-slider', component_property='value'))
def update_pick_up_perc_slider(value):
    global perc_door_pick_up
    perc_door_pick_up = value
    return 'Es werden {}% der Fahrgäste auf Anfrage abgeholt'.format(value)

#### callback for the visualization of the frequencies
@app.callback(
    Output(component_id='frequencies_graph', component_property='figure'),
    Output(component_id='buffer_graph', component_property='figure'),
    Input(component_id='hvk-frequency-slider', component_property='value'),
    Input(component_id='nvk-frequency-slider', component_property='value'),
    Input(component_id='night-frequency-slider', component_property='value'),
    Input(component_id='service-range-slider', component_property='value'),
    Input(component_id='hvk-range-slider', component_property='value'),
    Input(component_id='hvk2-range-slider', component_property='value'),
    Input(component_id='night-range-slider', component_property='value'))

def update_frequency_viz(hvk_frequency_slider, nvk_frequency_slider, night_frequency_slider, service_range, hvk_range, hvk2_range, night_range):
    global bus_frequencies
    global hvk_frequency
    global nvk_frequency
    global night_frequency
    global total_duration_in_sec
    global durations
    if len(durations) == 1:
        hvk_frequency = hvk_frequency_slider
        nvk_frequency = nvk_frequency_slider
        night_frequency = night_frequency_slider
        bus_frequencies.loc[(bus_frequencies['hour'] >= service_range[0]), 'takt'] = nvk_frequency
        bus_frequencies.loc[(bus_frequencies['hour'] >= hvk_range[0]) & (bus_frequencies['hour'] <= hvk_range[1]), 'takt'] = hvk_frequency
        bus_frequencies.loc[(bus_frequencies['hour'] >= hvk2_range[0]) & (bus_frequencies['hour'] <= hvk2_range[1]), 'takt'] = hvk_frequency
        bus_frequencies.loc[(bus_frequencies['hour'] >= night_range) & (bus_frequencies['hour'] <= service_range[1]), 'takt'] = night_frequency
        bus_frequencies.loc[(bus_frequencies['hour'] > service_range[1]), 'takt'] = 0
        bus_frequencies = bus_frequencies.assign(
            bus_per_hour = lambda dataframe: dataframe['takt'].map(lambda takt: int(60/takt) if takt >= 1 else 0) 
            )
        
        base_fig = px.bar(bus_frequencies, x="hour", y='bus_per_hour', title="Bedienhäufigkeit nach Tageszeit", 
                 labels={'hour':'Tageszeit', 'bus_per_hour':'Bedienhäufigkeit der Haltestellen pro Stunden'})
        
        base_fig.update_layout(
            title_x=0.5,
            title_font_color=colors['text'],
            xaxis = dict(
                tickmode = 'linear',
                tick0 = 0,
                dtick = 1)
            )
        base_fig.update_traces(
                marker_color='rgb(158,202,225)', marker_line_color='rgb(8,48,107)',
                      marker_line_width=1.5, opacity=0.6
        )
        
        buffer_fig = px.line(bus_frequencies, x='hour', y='buffer_time', color = bus_frequencies['label_buffer'], title="Zeitpuffer zwischen den Fahrten", 
                 labels={'hour':'Tageszeit', 'buffer_time':'Zeitpuffer'})
        
        buffer_fig.update_layout(
            title_x=0.5,
            title_font_color=colors['text'],
            legend_yanchor='top',
            legend_xanchor='left',
            xaxis = dict(
                tickmode = 'linear',
                tick0 = 0,
                dtick = 1)
            ) 
    else:
        hvk_frequency = hvk_frequency_slider
        nvk_frequency = nvk_frequency_slider
        night_frequency = night_frequency_slider
        bus_frequencies.loc[(bus_frequencies['hour'] >= service_range[0]), 'takt'] = nvk_frequency
        bus_frequencies.loc[(bus_frequencies['hour'] >= hvk_range[0]) & (bus_frequencies['hour'] <= hvk_range[1]), 'takt'] = hvk_frequency
        bus_frequencies.loc[(bus_frequencies['hour'] >= hvk2_range[0]) & (bus_frequencies['hour'] <= hvk2_range[1]), 'takt'] = hvk_frequency
        bus_frequencies.loc[(bus_frequencies['hour'] >= night_range) & (bus_frequencies['hour'] <= service_range[1]), 'takt'] = night_frequency
        bus_frequencies.loc[(bus_frequencies['hour'] > service_range[1]), 'takt'] = 0
        bus_frequencies = bus_frequencies.assign(
            bus_per_hour = lambda dataframe: dataframe['takt'].map(lambda takt: int(60/takt) if takt >= 1 else 0) 
            )
        bus_frequencies['vehicles'] = bus_frequencies.apply(lambda row: 0 if row['takt'] == 0 else (int(total_duration_in_sec / (row['takt']*60)) + 1)*2, axis=1)
        
        ### keep on working hier
        bus_frequencies['buffer_time'] = ((bus_frequencies['takt'].astype(int)*60 - total_duration_in_sec)/60)
        bus_frequencies.loc[(bus_frequencies['buffer_time'] < 0), 'buffer_time'] = -((bus_frequencies['takt'].astype(int)*60 - (total_duration_in_sec*2))/60)
        
        base_fig = px.bar(bus_frequencies, x="hour", y='bus_per_hour', title="Bedienhäufigkeit nach Tageszeiten", 
                 labels={'hour':'Tageszeit', 'bus_per_hour':'Bedienhäufigkeit der Haltestellen pro Stunden'})
        
        fig_vehicles_per_hour = px.line(x=bus_frequencies['hour'], y=bus_frequencies['vehicles'], color = bus_frequencies['label_vehicles'])
        
        base_fig.add_trace(fig_vehicles_per_hour.data[0])  
        
        base_fig.update_layout(
            title_x=0.5,
            title_font_color=colors['text'],
            legend_yanchor='top',
            legend_xanchor='left',
            xaxis = dict(
                tickmode = 'linear',
                tick0 = 0,
                dtick = 1)
            )        
        base_fig.update_traces(
                marker_color='rgb(158,202,225)', marker_line_color='rgb(8,48,107)',
                      marker_line_width=1.5, opacity=0.6
        )
        
        buffer_fig = px.line(bus_frequencies, x='hour', y='buffer_time', color = bus_frequencies['label_buffer'], title="Zeitpuffer zwischen den Fahrten", 
                 labels={'hour':'Tageszeit', 'buffer_time':'Zeitpuffer'})
        
        buffer_fig.update_layout(
            title_x=0.5,
            title_font_color=colors['text'],
            legend_yanchor='top',
            legend_xanchor='left',
            xaxis = dict(
                tickmode = 'linear',
                tick0 = 0,
                dtick = 1)
            )  
        
    return base_fig, buffer_fig