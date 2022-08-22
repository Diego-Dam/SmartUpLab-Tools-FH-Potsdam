import dash  # (version 1.12.0) pip install dash
from dash import dcc
from dash import html
from dash.dependencies import Input, Output
from dash.exceptions import PreventUpdate
from app import app

from .dataprep import preproc

colors = preproc.colors
encoded_image5 = preproc.encoded_image5
black = preproc.black
borders_color = preproc.borders_color

layout = html.Div([
    html.Div( 
            children = "Das Parkraummanagement in der Neuruppiner Innenstadt gestaltet sich als ein komplexes Thema. Die mögliche Umwidmung von Flächen für den ruhenden Verkehr in Grün- und Freiflächen sowie Flächen für den Umweltverbund kann auf der einen Seite die Aufenthaltsqualität in der Innenstadt erhöhen und Anreize schaffen, auf klimafreundliche Verkehrsmittel umzusteigen. Auf der anderen Seite ist die Umstellung auf eine restriktivere Parkraumbewirtschaftung häufig mit Konflikten verbunden. Um die Akteur*innen der Stadtplanung bei dieser Herausforderung zu unterstützen, hat SmartUpLab ein digitales Planungstool zur Unterstützung von Entscheidungsfindung im Bereich des Parkraummanagements entwickelt. Mithilfe des Planungstools können auf Grundlage komplexer Daten Szenarien rund um das Thema Parken modelliert und visualisiert werden. Das Planungstool basiert auf einem digitalen Stadtmodell und soll Entscheidungsträger*innen der Stadt bei der Erarbeitung eines neuen Konzepts für Parkraummanagement in der Altstadt unterstützen."
        , style={'width': '100%', 'float': 'center', 'display': 'inline-block', 'color': colors['text'],'textAlign': 'center'}),
    html.Br(),
    html.Br(),
    html.Br(),
    html.Div([
    html.Div(
            children = "Das Online-Dashboard des Planungstool bietet folgende Funktionen:"
        , style={'width': '100%', 'float': 'left', 'display': 'inline-block', 'color': colors['text'],'textAlign': 'left'}),  
    html.Div(
            html.Ul([
            html.Li("Auswahl von Settings zum Thema Parken in der Innenstadt"),
            html.Li("Aufzeigen der Parkplatzauslastung im Tagesverlauf zur Settinganalyse"),
            html.Li("Direktvergleich von Settings durch Anzeige der Parkraumauslastung auf Blockebene"),
            ], style={'border-bottom': 'solid 3px', 'border-color':borders_color,'padding-top': '6px', 'width': '100%', 'float': 'left', 'display': 'inline-block', 'color': colors['text'],'textAlign': 'left'}
            ))], style={'margin': 'auto','width': '50%', 'float': 'center', 'color': colors['text'],'textAlign': 'center'}),
    html.Br(),
    html.Div([
        html.Div( 
            children = "Das Tool wurde im Rahmen eines Reallabors, welches Teil eines breiteren Co-Creation-Ansatzes ist."
        , style={"margin-bottom": "5px",'justify-content': 'center'}),
        html.Br(),
        html.Img(src='data:image/png;base64,{}'.format(encoded_image5.decode()), style = {'width':'800px', 'heigth':'800px', 'border':'0px', 'margin':'auto'}),  
        ],style={"margin-top": "15px", 'width': '100%', 'text-align': 'center', 'display': 'inline-block', 'color': colors['text']})
    ], style = {'justify-content': 'center'}) 