import dash
from flask import Flask

server = Flask(__name__)
app = dash.Dash(__name__, server=server, suppress_callback_exceptions=True)
app.server.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# local PostgreSQL
# app.server.config["SQLALCHEMY_DATABASE_URI"] = "postgresql://postgres:your_password@localhost/test"

# # live Heroku PostgreSQL database
# app.server.config["SQLALCHEMY_DATABASE_URI"] = "postgresql://fggyrzatbgvjwu:3996c50a4739bf57123b29a3aaeb6fa78ab285cc3b76a90f026834c52ecedb37@ec2-34-205-46-149.compute-1.amazonaws.com:5432/dea9nll494l1du"
# maybe try with postgresql

# meta_tags are required for the app layout to be mobile responsive
external_stylesheets = ['offline_style.css']

# app = dash.Dash(__name__, external_stylesheets=external_stylesheets, suppress_callback_exceptions=True,
#                 meta_tags=[{'name': 'viewport',
#                             'content': 'width=device-width, initial-scale=1.0'}]
#                 )
