import dash  # (version 1.12.0) pip install dash
from dash import dcc
from dash import html
from dash.dependencies import Input, Output
from dash.exceptions import PreventUpdate
from app import app

from .dataprep import preproc

colors = preproc.colors
encoded_image4 = preproc.encoded_image4
encoded_image5 = preproc.encoded_image5

layout = html.Div([
    html.Div( 
            children = "Im Rahmen des ersten Workshops am 01.10.2021 konnten die Teilnehmenden zunächst über das 'Routenplanung-Dashboard' unterschiedliche kartographische Ansichten und relevante raumbezogene Daten visualisieren und die aktuelle lokale Angebots- und Nachfragesituation kennenlernen. Auf dieser Basis wurden Szenarien für eine Linienbus- bzw. DRT-Route partizipativ definiert."
        , style={'width': '49%', 'float': 'left', 'display': 'inline-block', 'color': colors['text'],'textAlign': 'center'}),
    html.Div(
            children = "Im Rahmen des zweiten Workshops am 08.10.2021 analysierten und verglichen die Teilnehmenden über das 'Szenario-Analyse-Dashboard' drei verschiedenen Szenarien. Unter anderen wurden sowohl die Qualität des Angebots im Hinblick auf Fahrzeiten nach Block und Tageszeit, als auch operative Indikatoren wie die Fahrzeugbelastung, die Anzahl der gefahrenen Kilometer und die Pausezeiten an der Endhaltestelle betrachtet "
        , style={'width': '49%', 'float': 'right', 'display': 'inline-block', 'color': colors['text'],'textAlign': 'center'}),  
    html.Br(),
    html.Div([
        html.Div( 
            children = "Das Tool wurde im Rahmen eines Reallabors, welches Teil eines breiteren Co-Creation-Ansatzes ist."
        , style={"margin-bottom": "5px",'justify-content': 'center'}),
        html.Br(),
        html.Img(src='data:image/png;base64,{}'.format(encoded_image5.decode()), style = {'width':'800px', 'heigth':'800px', 'border':'0px', 'margin':'auto'}),  
        ],style={"margin-top": "15px", 'width': '100%', 'text-align': 'center', 'display': 'inline-block', 'color': colors['text']})
    ], style = {'justify-content': 'center'}) 