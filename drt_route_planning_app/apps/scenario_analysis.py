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
from apps import route_planning, scenario_analysis, home
#, scenarios_overview

from .dataprep import routing_api

from .dataprep import preproc

colors = preproc.colors
encoded_image6 = preproc.encoded_image6
encoded_image7 = preproc.encoded_image7
encoded_image8 = preproc.encoded_image8
encoded_image9 = preproc.encoded_image9
encoded_image10 = preproc.encoded_image10
living_building = preproc.living_building
future_building = preproc.future_building
building = preproc.building
blocks = preproc.blocks
edu = preproc.edu
blocks_df_all_scenarios = preproc.blocks_df_all_scenarios
nodes = preproc.nodes
tram_stops = preproc.tram_stops
blackbold = preproc.blackbold
bus_frequencies = preproc.bus_frequencies
bus_route_counter = preproc.bus_route_counter
capacity = preproc.capacity
n_of_stops = preproc.n_of_stops
df_node_inter = preproc.df_node_inter
df_node_viz = preproc.df_node_viz
house_types = preproc.house_types
hvk_frequency = preproc.hvk_frequency
list_of_inputs = preproc.list_of_inputs
metrics = preproc.metrics
metrics_blks = preproc.metrics_blks
metrics_blks_res = preproc.metrics_blks_res
night_frequency = preproc.night_frequency
directions = preproc.directions
nvk_frequency = preproc.nvk_frequency
rdt_general_timetable = preproc.rdt_general_timetable
scatter_types = preproc.scatter_types
token = preproc.token
selected_style = preproc.selected_style
blackbold = preproc.blackbold
small_font = preproc.small_font
blk_idz_list = preproc.blk_idz_list
travels = preproc.travels_basic_scenario
travels_basic_scenario = preproc.travels_basic_scenario
travels_classic_route = preproc.travels_classic_route
travels_flexi_route = preproc.travels_flexi_route
operational_data_flexi_route = preproc.operational_data_flexi_route
modi = preproc.modi
leaving_the_area = preproc.leaving_the_area
trip_duration_pt = preproc.trip_duration_pt
passengers_flexi_route = preproc.passengers_flexi_route
to_be_sum_up = preproc.to_be_sum_up_travels
passengers_classic_route = preproc.passengers_classic_route
modal_share = preproc.modal_share

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

######################
##  App HTML layout ##
######################
layout = html.Div([
    html.H2("Szenario-Analyse", style={'text-align': 'center', 'color': colors['text']}),
        html.H3(['Daten zum Gebiet'], style={'text-align': 'center', 'color': colors['text']}),
        html.Div([
        # Infos zum Gebiet        
        html.Ul([
            html.Li("ca. 12 Tsd. Einwohner*innen im gesamten Gebiet"),
            html.Li("ca. 1,3 Tsd. Einwohner*innen ziehen zukünftig dazu"),
            html.Li("ca. 3,7 Tsd. Einwohner*innen im RDT-Gebiet"),
            html.Ul([
                html.Li("16% ÖPNV Anteil bedeutet ca. 600 potenzielle Fahrgäste für ca. 2,0 Tsd. Beförderungen (3,4 Fahrten pro Person, Quelle: SrV 2018)"),
                html.Li("21% ÖPNV Anteil bedeutet ca. 780 potenzielle Fahrgäste für ca. 2,6 Tsd. Beförderungen (3,4 Fahrten pro Person, Quelle: SrV 2018)"),
                html.Li("26% ÖPNV Anteil bedeutet ca. 960 potenzielle Fahrgäste für ca. 3,2 Tsd. Beförderungen (3,4 Fahrten pro Person, Quelle: SrV 2018)"),
            ])
            ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}
        )], style={'width': '100%', 'float': 'center', 'display':'flex', 'justify-content':'center', 'align-items':'center', 'color': colors['text']}),
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
                html.Li("Wohngebäude", style={'background': living_place_color,'color':'black',
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
            html.Label(children=['Fahrzeit mit ÖPNV nach Blöcken:'], style=blackbold),
            html.Div([
                dcc.Dropdown(id="slct_kpi_blk",
                             options=[
                                 {"label": i, "value": i} for i in metrics_blks_res],
                             multi=False,
                             value=metrics_blks_res[0],
                             style={'width': "100%"}
                             ),
                html.Br(),
            ],style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}),
            html.Br(),
            html.Label(children=['ÖPNV Anteil:'], style=blackbold),
            html.Div([
                dcc.RadioItems(id='slct_modal_share_map',
                        options=[{'label':str(x),'value':x} for x in modal_share],
                        value=modal_share[1],
                        labelStyle={'width': "100%"}
                ),
                html.Br(),
            ],style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px'}),
            html.Br(),
        ], style = {'width':'22%'}
        ),

        # Map
        html.Div([
            dcc.Graph(id='choropleth_res', clickData=None, hoverData=None, config={'displayModeBar': False,
                                                                               'staticPlot': False,
                                                                               'watermark': False,
                                                                               'showTips': False, 
                                                                               'doubleClick': False,  # 'reset', 'autosize' or 'reset+autosize', False
                                                                               'scrollZoom': True},
                style={'padding-bottom':'2px','padding-left':'2px','height':'110vh'}
            )
        ], style={'width':'74%'}
    ),
    html.Br(),
    ], style={'width': '100%', 'margin-left':'0px', 'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px',
                                           'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Br(),
    # All trips
    html.Div([
        html.H2("Fahrzeiten - Alle Strecke", style={'text-align': 'center', 'color': colors['text']}),
    html.Br(),
    # Checkbox button
    html.Div([
        html.Div([
            html.Label(children=['Verkehrsmittel:'], style=blackbold),
                dcc.RadioItems(id='slct_modi_all_trip',
                        options=[{'label':str(x),'value':x} for x in modi],
                        value=modi[3],
                        labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
                ),
            ], style={'width': '33%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            html.Label(children=['Fahrgäste des neuen Busses?'], style=blackbold),
                dcc.RadioItems(id='slct_drt_passenger',
                        options=[{'label': 'Ja', 'value': 'True'},
                                  {'label': 'Nein', 'value': 'False'},],
                        value='False',
                        labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
                ),
            ], style={'width': '33%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            html.Label(children=['Ziel der Fahrt:'], style=blackbold),
                dcc.RadioItems(id='destination_all_trip',
                        options=[{'label':str(x),'value':x} for x in leaving_the_area],
                        value=leaving_the_area[0],
                        labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
                ),
            ],style={'width': '33%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
    ], style={'width': '100%', 'margin-left':'0px', 'border-bottom': 'dotted 1px', 'border-color':borders_color,'padding-top': '6px', 'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    ]),
   # Block data viz
    html.Div([
        html.Div([
            dcc.Graph(id="fig_selected_trips",
                      config={'displayModeBar': False,
                        'staticPlot': False,
                        'watermark': False,
                        'showTips': False, 
                        'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                        'scrollZoom': False},
                  figure={"layout": {
                "height": 500
            }})
            ],style={'width': '100%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
        ),
    ]),
    html.Br(),
    # Scneario names
    html.Div([
        html.H2("Fahrzeiten nach Block", style={'text-align': 'center', 'color': colors['text']}),
        html.Div(id='hover_data_display_res', children=[], style={'display':'flex', 'justify-content':'center', 'align-items':'center'}),
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
            ], style={'width': '33%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            html.Label(children=['ÖPNV Anteil:'], style=blackbold),
                dcc.RadioItems(id='slct_modal_share',
                        options=[{'label':str(x),'value':x} for x in modal_share],
                        value=modal_share[1],
                        labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
                ),
            ], style={'width': '33%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            html.Label(children=['Ziel der Fahrt:'], style=blackbold),
                dcc.RadioItems(id='destination',
                        options=[{'label':str(x),'value':x} for x in leaving_the_area],
                        value=leaving_the_area[0],
                        labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
                ),
            ],style={'width': '33%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
    ], style={'width': '100%', 'margin-left':'0px', 'border-bottom': 'dotted 1px', 'border-color':borders_color,'padding-top': '6px', 'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Div([
        html.H4("Baseline Szenario", style={'text-align': 'center', 'color': colors['text']}),
        #html.Img(src='data:image/png;base64,{}'.format(encoded_image8.decode()), style = {'border-color': borders_color, 'width':'90%', 'heigth':'800px', 'border':'0px', 'margin':'auto'}),  
        ], style={'width': '33%', 'height': '60px', 'float': 'left', 'display': 'inline-block', 'color': colors['text']}),
    html.Div([
        html.H4("Klassik Bornbus", style={'text-align': 'center', 'color': colors['text']}),
        #html.Img(src='data:image/png;base64,{}'.format(encoded_image6.decode()), style = {'width':'90%', 'heigth':'800px', 'border':'0px', 'margin':'auto'}),
        ], style={'width': '33%', 'height': '60px', 'float': 'left', 'display': 'inline-block', 'color': colors['text']}
        ),
    html.Div([
        html.H4("Flexi Bornbus", style={'text-align': 'center', 'color': colors['text']}),
        #html.Img(src='data:image/png;base64,{}'.format(encoded_image7.decode()), style = {'width':'90%', 'heigth':'800px', 'border':'0px', 'margin':'auto'}),
        ], style={'width': '33%', 'height': '60px', 'float': 'left', 'display': 'inline-block', 'color': colors['text']}
        ),
    ]),
   # Block data viz by scenario    
   # Block data viz
    html.Div([
        html.Div([
            dcc.Graph(id="segmented_trip_res_basic",
                      config={'displayModeBar': False,
                        'staticPlot': False,
                        'watermark': False,
                        'showTips': False, 
                        'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                        'scrollZoom': False},
                  figure={"layout": {
                "height": 500
            }})
            ],style={'width': '33%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            dcc.Graph(id="segmented_trip_res_classic",
                      config={'displayModeBar': False,
                        'staticPlot': False,
                        'watermark': False,
                        'showTips': False, 
                        'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                        'scrollZoom': False},
                  figure={"layout": {
                "height": 500
            }})
            ],style={'width': '33%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            dcc.Graph(id="segmented_trip_res_flexi",
                      config={'displayModeBar': False,
                        'staticPlot': False,
                        'watermark': False,
                        'showTips': False, 
                        'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                        'scrollZoom': False},
                  figure={"layout": {
                "height": 500
            }})
            ],style={'width': '33%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
        ),
    ]),
    ]),
    html.Br(),
    html.Div([
    html.H2("Fahrgäste nach Tageszeit", style={'text-align': 'center', 'color': colors['text']}),
    html.Div([
    html.H4("Klassik Bornbus", style={'text-align': 'center', 'color': colors['text']}),
    #html.Img(src='data:image/png;base64,{}'.format(encoded_image6.decode()), style = {'width':'90%', 'heigth':'800px', 'border':'0px', 'margin':'auto'}),
    ], style={'width': '50%', 'height': '60px', 'float': 'center', 'display': 'inline-block', 'color': colors['text']}
    ),
    html.Div([
    html.H4("Flexi Bornbus", style={'text-align': 'center', 'color': colors['text']}),
    #html.Img(src='data:image/png;base64,{}'.format(encoded_image7.decode()), style = {'width':'90%', 'heigth':'800px', 'border':'0px', 'margin':'auto'}),
    ], style={'width': '50%', 'height': '60px', 'float': 'center', 'display': 'inline-block', 'color': colors['text']}    
    ),
    ]),
    html.Div([
        html.Div([
        #html.Img(src='data:image/png;base64,{}'.format(encoded_image6.decode()), style = {'width':'90%', 'heigth':'800px', 'border':'0px', 'margin':'auto'}),
        html.Img(src='data:image/png;base64,{}'.format(encoded_image9.decode()), style = {'width':'300px', 'heigth':'300px', 'border':'0px', 'rigth':'0px', 'top':'0px', 'left':'0px', 'margin':'auto'}),          
        ], style={'width': '50%', 'float': 'right', 'height': '400px', 'display': 'flex', "justify-content": "center",  'color': colors['text']}
        ),
        html.Div([
        html.Img(src='data:image/png;base64,{}'.format(encoded_image10.decode()), style = {'width':'300px', 'heigth':'300px', 'border':'0px', 'rigth':'0px', 'top':'0px', 'left':'0px', 'margin':'auto'}),          
        #html.Img(src='data:image/png;base64,{}'.format(encoded_image7.decode()), style = {'width':'90%', 'heigth':'800px', 'border':'0px', 'margin':'auto'}),
        ], style={'width': '50%', 'float': 'right', 'height': '400px', 'display': 'flex', "justify-content": "center", 'color': colors['text']}    
        ),
    ]),
    html.Div([
        html.Div([
            html.Label(children=['Fahrichtung:'], style=blackbold),
                dcc.RadioItems(id='direction',
                        options=[{'label':str(x),'value':x} for x in directions],
                        value=directions[0],
                        labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
                ),
            ],style={'width': '50%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
        html.Div([
            html.Label(children=['ÖPNV Anteil:'], style=blackbold),
                dcc.RadioItems(id='slct_modal_share_2',
                        options=[{'label':str(x),'value':x} for x in modal_share],
                        value=modal_share[1],
                        labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
                ),
            ], style={'width': '50%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
        ),
    ], style={'width': '100%', 'margin-left':'0px', 'border-bottom': 'dotted 1px', 'border-color':borders_color,'padding-top': '6px', 'display':'flex', 'justify-content':'center', 'align-items':'center'}),
    html.Div([                    
    html.Div([
        dcc.Graph(id="passengers_classic_route",
                  config={'displayModeBar': False,
                    'staticPlot': False,
                    'watermark': False,
                    'showTips': False, 
                    'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                    'scrollZoom': False},
              figure={"layout": {
            "height": 500
        }})
        ],style={'width': '50%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
    ),
    html.Div([
        dcc.Graph(id="passengers_flexi_route",
                  config={'displayModeBar': False,
                    'staticPlot': False,
                    'watermark': False,
                    'showTips': False, 
                    'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                    'scrollZoom': False},
              figure={"layout": {
            "height": 500
        }})
        ],style={'width': '50%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
    ),
    ]),
    html.Div([
    html.H2("Fahrdauer nach Tageszeit", style={'text-align': 'center', 'color': colors['text']}),
    html.Div([
        html.Label(children=['ÖPNV Anteil:'], style=blackbold),
            dcc.RadioItems(id='slct_modal_share_3',
                    options=[{'label':str(x),'value':x} for x in modal_share],
                    value=modal_share[1],
                    labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
            ),
        ], style={'width': '100%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
    ),
    html.Div([
    dcc.Graph(id="trip_duration_classic_route",
              config={'displayModeBar': False,
                'staticPlot': False,
                'watermark': False,
                'showTips': False, 
                'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                'scrollZoom': False},
          figure={"layout": {
        "height": 500
    }})
    ],style={'width': '50%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
    ),
    html.Div([
    dcc.Graph(id="trip_duration_flexi_route",
              config={'displayModeBar': False,
                'staticPlot': False,
                'watermark': False,
                'showTips': False, 
                'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                'scrollZoom': False},
          figure={"layout": {
        "height": 500
    }})
    ],style={'width': '50%', 'float': 'right', 'display': 'inline-block', 'color': colors['text']}
    ),
    ]),
    html.Div([
    html.H2("Gefahrene Km und Wartezeit am Endehaltestelle", style={'text-align': 'center', 'color': colors['text']}),
    html.Div([
        html.Label(children=['ÖPNV Anteil:'], style=blackbold),
            dcc.RadioItems(id='slct_modal_share_4',
                    options=[{'label':str(x),'value':x} for x in modal_share],
                    value=modal_share[1],
                    labelStyle={'display': 'inline-block', 'float': 'center', 'text-align': 'center', 'color': colors['text']}
            ),
        ], style={'width': '100%', 'text-align': 'center','float': 'center', 'display': 'inline-block', 'color': colors['text']}
    ),
    html.Div([
    dcc.Graph(id="Km_and_waiting_time_flexi",
              config={'displayModeBar': False,
                'staticPlot': False,
                'watermark': False,
                'showTips': False, 
                'doubleClick': 'autosize',  # 'reset', 'autosize' or 'reset+autosize', False
                'scrollZoom': False},
          figure={"layout": {
        "height": 500
    }})
    ],style={'width': '100%', 'float': 'center', 'display': 'inline-block', 'color': colors['text']}
    )
    ])
    ])
#####################
##  App Callbacks ##
####################
# Connect the Plotly graphs with Dash Components
### each element with an identifier must be referenced here as output or input

#### callback for map > display and update the map
@app.callback(
    Output(component_id='choropleth_res', component_property='figure'),
    Input(component_id='slct_kpi_blk', component_property='value'),
    Input(component_id='slct_modal_share_map', component_property='value'),
    Input(component_id='choropleth_res', component_property='clickData'),
    Input(component_id='viz_blocks', component_property='value'),
    Input(component_id='viz_future_buildings', component_property='value')
    #Input(component_id='node_types', component_property='value')
)

def update_graph(slct_kpi_blk, slct_modal_share_map, clickData, viz_blocks, viz_future_buildings):
                 #option_slct_house_types,
                 #option_slct_nodes):
    global fig_custom
    global blocks_df_all_scenarios
    global blocks
    global trip_duration_pt
    #------------1st layer BLOCKS------------#
    opacity_blks = viz_blocks 
    blocks_data = blocks_df_all_scenarios[blocks_df_all_scenarios['scenario'] == slct_modal_share_map]
    
    # Plotly shape map with mapbox background - static - working buildings
    fig_custom = px.choropleth_mapbox(
        data_frame=blocks_data,
        geojson=blocks_data.geometry,
        locations=blocks_data.index,
        center={"lat": 52.42241, "lon": 13.04000},
        zoom=13,
        opacity= opacity_blks,
        color= slct_kpi_blk,
        range_color=(0, 51), # hardcoded for comparability between scenarios
        color_continuous_scale='OrRd',
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
        coloraxis_colorbar=dict(ticksuffix=" Min"))
        
#------------2nd layer LIVING BUILDING------------#

    # Plotly choropleth map with mapbox background - static - living buildings
    
    # Plotly map with mapbox background - selecting columns
    fig_living = px.choropleth_mapbox(
        data_frame=living_building,
        geojson=living_building.geometry,
        color='tram_cost',
        locations=living_building.index,
        color_continuous_scale='OrRd_r',
        center={"lat": 52.42241, "lon": 13.04000},
        zoom=14,
        range_color=[0, max(living_building['tram_cost'])])

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
        color='tram_cost',
        locations=future_building.index,
        color_continuous_scale='OrRd_r',
        center={"lat": 52.42241, "lon": 13.04000},
        zoom=14,
        opacity= opacity_future_buildings,
        range_color=[0, max(future_building['tram_cost'])])

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

### callback for visualizing the basci scenrio data by block
@app.callback(
    Output(component_id="segmented_trip_res_basic", component_property='figure'),
    Output(component_id='segmented_trip_res_classic', component_property='figure'),
    Output(component_id='segmented_trip_res_flexi', component_property='figure'),
    Input(component_id='choropleth_res', component_property='hoverData'),
    Input(component_id='slct_modi', component_property='value'),
    Input(component_id='slct_modal_share', component_property='value'),
    Input(component_id='destination', component_property='value')
)

### keep on working here > goal is to visualize data for the blocks > the data and data prep steps on modifie sql block table should be added and than the data from pointing on it
def blocks_basic_scenario_data(hoverData_res, slct_modi, slct_modal_share, destination):
    global blk_idz_list
    if hoverData_res is None:
        raise PreventUpdate
    else:
        slct_blk = hoverData_res['points'][0]['hovertext']
        
        #### data from different modal share should be merged in a single dataframe
        ### with a column modal share and than filtered correspondly
        
        # basic scenario
        plot_df_basic = travels_basic_scenario[(travels_basic_scenario['modi'] == slct_modi) &
                                               (travels_basic_scenario['block'] == slct_blk) &
                                               (travels_basic_scenario['leaving_the_area'] == destination) &
                                               (travels_basic_scenario['scenario'] == slct_modal_share)]
        fig_trip_segmented_basic = px.bar(plot_df_basic, x="start_trip_time", y=to_be_sum_up, 
              labels={'start_trip_time':'Tageszeit - basic', 'Gesamte Fahrzeit':'Fahrzeit in Min.'})
        fig_trip_segmented_basic.update_layout(
            xaxis_title='Tageszeit',
            yaxis_title='Fahrzeit in Min.',
            legend_title="Phasen",
                font=dict(
                    size=10,
                ),
            xaxis={
                "rangeslider": {"visible": True}
            })
        fig_trip_segmented_basic.update_yaxes(range = [0,60])
        # classic route
        plot_df_classic = travels_classic_route[(travels_classic_route['modi'] == slct_modi) &
                                                (travels_classic_route['block'] == slct_blk) &
                                                (travels_classic_route['leaving_the_area'] == destination) &
                                                (travels_classic_route['scenario'] == slct_modal_share)]
        fig_trip_segmented_classic = px.bar(plot_df_classic, x="start_trip_time", y=to_be_sum_up, 
              labels={'start_trip_time':'Tageszeit - classic', 'Gesamte Fahrzeit':'Fahrzeit in Min.'})
        fig_trip_segmented_classic.update_layout(
            xaxis_title='Tageszeit',
            yaxis_title='Fahrzeit in Min.',
            legend_title="Phasen",
                font=dict(
                    size=10,
                ),
            xaxis={
                "rangeslider": {"visible": True},
            })
        fig_trip_segmented_classic.update_yaxes(range = [0,60])
        # flexi
        plot_df_flexi = travels_flexi_route[(travels_flexi_route['modi'] == slct_modi) &
                                            (travels_flexi_route['block'] == slct_blk) &
                                            (travels_flexi_route['leaving_the_area'] == destination) &
                                            (travels_flexi_route['scenario'] == slct_modal_share)]
        fig_trip_segmented_flexi = px.bar(plot_df_flexi, x="start_trip_time", y=to_be_sum_up, 
              labels={'start_trip_time':'Tageszeit - flexi', 'Gesamte Fahrzeit':'Fahrzeit in Min.'})
        fig_trip_segmented_flexi.update_layout(
            xaxis_title='Tageszeit',
            yaxis_title='Fahrzeit in Min.',
            legend_title="Phasen",
                font=dict(
                    size=10,
                ),
            xaxis={
                "rangeslider": {"visible": True},
            })
        fig_trip_segmented_flexi.update_yaxes(range = [0,60])
        return fig_trip_segmented_flexi, fig_trip_segmented_classic,  fig_trip_segmented_basic,

### callback for visualizing the basci scenrio data by block
@app.callback(
    Output(component_id="fig_selected_trips", component_property='figure'),
    Input(component_id='slct_kpi_blk', component_property='value'),
    Input(component_id='slct_drt_passenger', component_property='value'),    
    Input(component_id='slct_modi_all_trip', component_property='value'),
    Input(component_id='slct_modal_share_map', component_property='value'),
    Input(component_id='destination_all_trip', component_property='value')
)

### keep on working here > goal is to visualize data for the blocks > the data and data prep steps on modifie sql block table should be added and than the data from pointing on it
def blocks_scenario_data_all_trip(slct_kpi_blk, slct_drt_passenger, slct_modi, slct_modal_share, destination):
    #### data from different modal share should be merged in a single dataframe
    ### with a column modal share and than filtered correspondly
    #slct_kpi_blk
    # basic scenario
    if slct_kpi_blk == 'basisszenario':
        df = travels_basic_scenario
    elif slct_kpi_blk == 'szenario_klassische_route':
        df = travels_classic_route
    elif slct_kpi_blk == 'szenario_flexi_route':
        df = travels_flexi_route
    
    plot_df_basic = df[(df['modi'] == slct_modi) &
                        (df['rdt_passenger'] == slct_drt_passenger) &
                        (df['leaving_the_area'] == destination) &
                        (df['scenario'] == slct_modal_share)]
    fig_selected_trips = px.bar(plot_df_basic, x="start_trip_time", y=to_be_sum_up, 
          labels={'start_trip_time':'Tageszeit - basic', 'Gesamte Fahrzeit':'Fahrzeit in Min.'})
    fig_selected_trips.update_layout(
        xaxis_title='Tageszeit',
        yaxis_title='Fahrzeit in Min.',
        legend_title="Phasen",
            font=dict(
                size=10,
            ),
        xaxis={
            "rangeslider": {"visible": True}
        })
    fig_selected_trips.update_yaxes(range = [0,60])
    
    return fig_selected_trips

### callback for visualizing the basci scenrio data by block
@app.callback(
    Output(component_id="passengers_classic_route", component_property='figure'),
    Output(component_id='passengers_flexi_route', component_property='figure'),
    Output(component_id="trip_duration_classic_route", component_property='figure'),
    Output(component_id='trip_duration_flexi_route', component_property='figure'),
    Output(component_id='Km_and_waiting_time_flexi', component_property='figure'),
    Input(component_id='direction', component_property='value'),
    Input(component_id='slct_modal_share_2', component_property='value'),
    Input(component_id='slct_modal_share_3', component_property='value'),
    Input(component_id='slct_modal_share_4', component_property='value')     
)

def passengers_data(direction, modal_share_scenario_2, modal_share_scenario_3, modal_share_scenario_4):
    # classic route
    passengers_classic_route_prov = passengers_classic_route[(passengers_classic_route['Richtung'] == direction) & (passengers_classic_route['scenario'] == modal_share_scenario_2)]
    
    passengers_classic_route_prov = passengers_classic_route_prov.drop(columns=["trip_duration", "Richtung", "scenario"])
    
    passengers_classic_route_prov['start_trip_time'] = passengers_classic_route_prov['start_trip_time'].astype(str)

    passengers_classic_route_prov.set_index('start_trip_time', inplace=True)
    
    passengers_classic_route_transposed = passengers_classic_route_prov.T
    
    passengers_classic_route_transposed = passengers_classic_route_transposed.iloc[::-1]  
    
    fig_passengers_classic = px.imshow(passengers_classic_route_transposed, color_continuous_scale=px.colors.sequential.Reds)
    
    # axis and title text
    fig_passengers_classic.update_layout(yaxis = dict(scaleanchor = 'y'), yaxis_title='Haltestelle', yaxis_nticks=13, xaxis_title='Tageszeit', margin=dict(
        l=0,
        r=0,
        b=0,
        t=0), coloraxis_colorbar=dict(
            title="Fahrgäste"))

    passengers_flexi_route_prov = passengers_flexi_route[passengers_flexi_route['scenario'] == modal_share_scenario_2]
    
    passengers_flexi_route_prov = passengers_flexi_route_prov.drop(columns=["trip_duration", "scenario"])
    
    passengers_flexi_route_prov['start_trip_time'] = passengers_flexi_route_prov['start_trip_time'].astype(str)

    passengers_flexi_route_prov.set_index('start_trip_time', inplace=True)
    
    passengers_flexi_route_prov_transposed = passengers_flexi_route_prov.T
    
    passengers_flexi_route_prov_transposed = passengers_flexi_route_prov_transposed.iloc[::-1]  
    
    fig_passengers_flexi = px.imshow(passengers_flexi_route_prov_transposed, color_continuous_scale=px.colors.sequential.Reds)
    
    # axis and title text
    fig_passengers_flexi.update_layout(yaxis = dict(scaleanchor = 'x'), yaxis_title='Haltestelle', yaxis_nticks=13, xaxis_title='Tageszeit', margin=dict(
        l=0,
        r=0,
        b=0,
        t=0), coloraxis_colorbar=dict(
            title="Fahrgäste"))

    passengers_flexi_route_by_scenario = passengers_flexi_route[passengers_flexi_route['scenario'] == modal_share_scenario_3]
    passengers_classic_route_by_scenario = passengers_classic_route[passengers_classic_route['scenario'] == modal_share_scenario_3]
    
    fig_trip_duration_classic = px.line(passengers_classic_route_by_scenario, x="start_trip_time", y="trip_duration")
    fig_trip_duration_classic.update_layout(
            xaxis_title='Tageszeit',
            yaxis_title='Fahrzeit in Min.',
            legend_title="Haltestellen",
                    font=dict(
                        size=10,
                    ))
    fig_trip_duration_flexi = px.line(passengers_flexi_route_by_scenario, x="start_trip_time", y="trip_duration")
    fig_trip_duration_flexi.update_layout(
                xaxis_title='Tageszeit',
                yaxis_title='Fahrzeit in Min.',
                legend_title="Haltestellen",
                        font=dict(
                            size=10,
                        ))
    
    operational_data_flexi_route_prov = operational_data_flexi_route[operational_data_flexi_route['scenario'] == modal_share_scenario_4]
    
    base_fig = make_subplots(specs=[[{"secondary_y": True}]])
    
    driven_distance_fig = px.bar(operational_data_flexi_route_prov, x="start_trip_time", y='driven_distance', title="Gefahrene Km nach Tageszeiten", 
             labels={'hour':'Tageszeit', 'driven_distance':'Gefahrene Km nach Tageszeiten'})
    
    pause_fig = px.line(x=operational_data_flexi_route_prov['start_trip_time'], y=operational_data_flexi_route_prov['previous_pause_duration']) # , color = bus_frequencies['label_vehicles']
    
    pause_fig.update_traces(yaxis="y2")
    
    base_fig.add_traces(driven_distance_fig.data + pause_fig.data)
    
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
    
    base_fig.layout.xaxis.title="Tageszeit"
    base_fig.layout.yaxis.title="Gefahren Km"
    base_fig.layout.yaxis2.title="Wartezeit am Endhaltestelle in Min."
    
    return fig_passengers_flexi, fig_passengers_classic, fig_trip_duration_flexi, fig_trip_duration_classic, base_fig


### callback for visualizing the distribution of blocks
@app.callback(
    Output(component_id="hover_data_display_res", component_property='children'),
    Input(component_id='choropleth_res', component_property='hoverData')
)

### keep on working here > goal is to visualize data for the blocks > the data and data prep steps on modifie sql block table should be added and than the data from pointing on it
def blocks_infos(hoverData):
    global blk_idz_list
    if hoverData is None:
        raise PreventUpdate
    else:
        slct_blk = hoverData['points'][0]['hovertext']
        if slct_blk not in blk_idz_list:
            raise PreventUpdate
        else:            
            tot_pop = str(int(blocks.loc[blocks['blk_idz'] == slct_blk, 'tot'].values))
            area = str(round(float(blocks.loc[blocks['blk_idz'] == slct_blk, 'area'].values), 2))
            density = str(round(float(blocks.loc[blocks['blk_idz'] == slct_blk, 'density'].values), 2))
            overall_block_infos = 'Im Block {} wohnen {} Personen auf einer Fläche von {} qkm, was in einer Dichte von {} Personen pro qkm entspricht'.format(slct_blk, tot_pop, area, density)
    return overall_block_infos