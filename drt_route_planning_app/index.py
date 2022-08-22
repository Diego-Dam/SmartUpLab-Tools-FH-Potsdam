from dash import dcc
from dash import html
from dash.dependencies import Input, Output

# Connect to main app.py file
from app import app 

# Connect to your app pages

# Connect to your app pages
from apps import route_planning, scenario_analysis, home
from apps.dataprep import preproc, routing_api


colors = preproc.colors
encoded_image = preproc.encoded_image
encoded_image2 = preproc.encoded_image2
encoded_image3 = preproc.encoded_image3
borders_color = preproc.borders_color

server = app.server

app.layout = html.Div([
    html.H1("SmartUpLab Stadtmodell", style={'text-align': 'center', 'color': colors['text']}),
    dcc.Location(id='url', refresh=False),
     html.Div([
    html.A(html.Button('Startseite', className='row'),
        href='/'),
    # html.A(html.Button('Basisszenario', className='row'),
    #     href='/apps/basic_scenario'),
    html.A(html.Button('Routenplanung', className='row'),
        href='/apps/route_planning'),
    # html.A(html.Button('Szenario-Übersicht', className='row'),
    #     href='/apps/scenarios_overview'),
    # to restore the scenario analysis tab simply move the square bracket and the style after the round parenthesis of scenario_analysis')
    html.A(html.Button('Szenario-Analyse', className='row'),
         href='/apps/scenario_analysis')], style={'text-align': 'center', 'margin':'0 auto', 'width':'60%'}),
    html.Br(),
    html.Div(id='page-content', children=[]),
    html.Br(),
    html.Img(src='data:image/png;base64,{}'.format(encoded_image.decode()), style = {'float':'right', 'width':'200px', 'heigth':'100px', 'border':'0px', 'margin':'0px'}),
    html.Img(src='data:image/png;base64,{}'.format(encoded_image2.decode()), style = {'width':'200px', 'heigth':'100px', 'align': 'right', 'border':'0px', 'margin':'0px', 'clear':'both'})   
])


@app.callback(Output('page-content', 'children'),
              [Input('url', 'pathname')])
def display_page(pathname):
    if pathname == '/apps/route_planning':
        return route_planning.layout
    if pathname == '/apps/scenario_analysis':
        return scenario_analysis.layout
    if pathname == '/apps/basic_scenario':
        return basic_scenario.layout
    # if pathname == '/apps/scenarios_overview':
    #     return scenarios_overview.layout
    else:
        return home.layout


if __name__ == '__main__':
    options = {'workers': 1, 'preload': True}             
    app.run_server(debug=False)