
import json
from time import sleep
from threading import Thread
from os.path import join, exists
from traceback import print_exc
from random import random
from datetime import datetime, timedelta
import tensorflow as tf
import keras
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense
from tensorflow.keras.layers import Activation
from vol751s_client import dwx_client
import numpy as np

"""

Example dwxconnect client in python


This example client will subscribe to tick data and bar data. It will also request historic data. 
if open_test_trades=True, it will also open trades. Please only run this on a demo account. 

"""
def siggy(x):

    return (40/(1+pow(np.exp(1),(-0.1*x))))-20

keras.utils.get_custom_objects().update({'siggy': Activation(siggy)})


class tick_processor():

    def __init__(self, MT4_directory_path, 
                 sleep_delay=0.0,             # 5 ms for time.sleep()
                 max_retry_command_seconds=10,  # retry to send the commend for 10 seconds if not successful. 
                 verbose=True
                 ):

        # if true, it will randomly try to open and close orders every few seconds. 
        self.open_test_trades = False

        self.last_open_time = datetime.utcnow()
        self.last_modification_time = datetime.utcnow()

        self.dwx = dwx_client(self, MT4_directory_path, sleep_delay, 
                              max_retry_command_seconds, verbose=verbose)
        

        self.dwx.start()

        norm = tf.keras.initializers.RandomNormal(mean=0., stddev=1)
        
        self.amodel = tf.keras.Sequential()
        self.bmodel = tf.keras.Sequential()

        self.amodel.add(Dense(55, input_shape=(5,), activation='relu', use_bias=False, kernel_initializer=norm, bias_initializer=norm))
        self.bmodel.add(Dense(55, input_shape=(5,), activation='relu', use_bias=False, kernel_initializer=norm, bias_initializer=norm))

        for i in range(30):
            self.amodel.add(Dense(100, activation='relu', use_bias=True, kernel_initializer=norm, bias_initializer=norm))
            self.bmodel.add(Dense(100, activation='relu', use_bias=True, kernel_initializer=norm, bias_initializer=norm))

        self.amodel.add(Dense(1, activation='siggy'))
        self.bmodel.add(Dense(1, activation='siggy'))

        self.amodel.compile()
        self.bmodel.compile()

        self.amodel.load_weights('C:\\Users\\okuhlemadondo\\Downloads\\models\\ask_model_alpha_vol751s_weights.h5')
        self.bmodel.load_weights('C:\\Users\\okuhlemadondo\Downloads\\models\\bid_model_alpha_vol751s_weights.h5')
        
        # account information is stored in self.dwx.account_info.
        print("Account info:", self.dwx.account_info)

        # subscribe to tick data:
        self.dwx.subscribe_symbols(['Volatility 75 (1s) Index'])

        # subscribe to bar data:
        #self.dwx.subscribe_symbols_bar_data(['Volatility 75 (1s) Index', 'M1'])

        # request historic data:
        #end = datetime.utcnow()
        #start = end - timedelta(days=30)  # last 30 days
        #self.dwx.get_historic_data('EURUSD', 'D1', start.timestamp(), end.timestamp())
 

    def on_tick(self, symbol, bid, bf1, bf2, bf3, bf4, bf5, ask, af1, af2, af3, af4, af5):

        now = datetime.utcnow()

        ask_in = np.array([[af1, af2, af3, af4, af5]])
        bid_in = np.array([[bf1, bf2, bf3, bf4, bf5]])

        ask_out = self.amodel.predict_on_batch(ask_in)
        bid_out = self.bmodel.predict_on_batch(bid_in)

        self.dwx.ask_nn_output(ask_out[0][0])
        self.dwx.bid_nn_output(bid_out[0][0])
        self.dwx.ask(ask)
        self.dwx.bid(bid)
        self.dwx.tr(ask)
        
        print('on_tick:',ask, af1, af2, af3, af4, af5,ask_out[0][0], bid, bf1, bf2, bf3, bf4, bf5, bid_out[0][0])


    def on_bar_data(self, symbol, time_frame, time, open_price, high, low, close_price, tick_volume):
        
        print('on_bar_data:', symbol, time_frame, datetime.utcnow(), time, open_price, high, low, close_price)
    

    def on_message(self, message):

        if message['type'] == 'ERROR':
            print(message['type'], '|', message['error_type'], '|', message['description'])
        elif message['type'] == 'INFO':
            print(message['type'], '|', message['message'])


 



MT4_files_dir = 'C:\\Users\\okuhlemadondo\\AppData\\Roaming\\MetaQuotes\\Terminal\\D0E8209F77C8CF37AD8BF550E51FF075\\MQL5\\Files'

processor = tick_processor(MT4_files_dir)

while processor.dwx.ACTIVE:
    sleep(0.001)


