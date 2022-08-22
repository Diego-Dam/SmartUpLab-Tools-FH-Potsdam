import pandas as pd
import dash
from flask import Flask
from sqlalchemy import create_engine
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.pool import NullPool


server = Flask(__name__)
app = dash.Dash(__name__, server=server, suppress_callback_exceptions=True)
app.server.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
# erase after testing - end

############################
##  Import and clean data ##
############################

app.server.config["SQLALCHEMY_DATABASE_URI"] = "postgresql://postgres:root@localhost:5432/Neuruppin_Data"

with open('save_string.txt', 'r') as file:
    save_string = file.read().replace('\n', '')

with open('save_parking_string.txt', 'r') as file:
    save_parking_string = file.read().replace('\n', '')
    
db = SQLAlchemy(app.server)

conn = db.engine

with conn.connect() as connection:
     setting_names = pd.read_sql('select * from "overview_simulations"',con=connection)
     query = 'select * from ' + save_string
     temp_df = pd.read_sql(query,con=connection)
     query_parking = 'select * from ' + save_parking_string
     temp_parking_df = pd.read_sql(query_parking,con=connection)
     connection.close()
     
app.server.config["SQLALCHEMY_DATABASE_URI"] = "postgresql://plevhbxenvzenx:b645ff865ccb413985559f8175e0f8452a4a80dda16eef4f3a2a3ef29bcd67a2@ec2-52-30-67-143.eu-west-1.compute.amazonaws.com:5432/dcq4cqnbn3nar0"

db2 = SQLAlchemy(app.server)

conn2 = db.engine

setting_names.to_sql('overview_simulations', conn2, if_exists='replace')
temp_df.to_sql(save_string, conn2, if_exists='replace')
temp_parking_df.to_sql(save_parking_string, conn2, if_exists='replace')