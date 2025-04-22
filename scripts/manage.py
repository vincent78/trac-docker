#!/usr/bin/env python

import argparse
import os
import sys
import psycopg2

# Gets connection string from environment variable
TRAC_DB_STRING = os.getenv('TRAC_DB_STRING')

# Defines function for test connection
def db_test_connection(query):
    connection = None
    connection = psycopg2.connect(TRAC_DB_STRING)
    cursor = connection.cursor()
    cursor.execute(query)
    connection.close()
    return cursor.rowcount

# Parses CLI arguments
parser = argparse.ArgumentParser()
parser.add_argument('--dbexists', help='description for option1',
                    action="store_true")
parser.add_argument('--dbempty', help='description for option2',
                    action="store_true")
args = parser.parse_args()

# Tests if database is ready
if args.dbexists:
    try:
        rowcount = db_test_connection("SELECT version();")
        if rowcount > 0:
            print("DB exists")
        else:
            sys.exit("DB not found or connection issues")
    except (Exception, psycopg2.DatabaseError) as error:
        sys.exit(error)

# Tests if database is empty
if args.dbempty:
    try:
        rowcount = db_test_connection("SELECT * FROM pg_catalog.pg_stat_user_tables LIMIT 1;")
        if rowcount == 0:
            print("DB is empty")
        else:
            sys.exit("DB is not empty")
    except (Exception, psycopg2.DatabaseError) as error:
        sys.exit(error)
