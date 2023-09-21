from flask import Flask, render_template, request
from urllib.request import urlopen
from urllib.parse import urlencode
import simplejson
import logging

app = Flask(__name__)
log = logging.getLogger('werkzeug')
log.disabled = True

BASE_PATH='http://solr:8983/solr/ohdsi-dcat/select?wt=json&'

@app.route('/', methods=["GET","POST"])
def index():
    collection = 'all'
    query, active = None, None
    query_parameters = {"q": "gdsc_collections:*"}
    q, qf = "", "gdsc_collections "
    numresults = 1
    results = []

    # get the search term if entered, and attempt
    # to gather results to be displayed
    if request.method == "POST":
        query = request.form["searchTerm"]
        collection = request.form["collection"]
        if 'active' in request.form:
            active = request.form["active"]

        #print ('collection:', collection)
        #print ('query:', query)
        #print ('active:', active)

        q = collection
        if collection == 'all' or collection == '*': 
            collection = '*'
            q = ""
        query_parameters = {"q": "gdsc_collections:*" + collection}
        if query is not None and query != "":
            qf += "dct_title dct_keywords dct_description gdsc_attributes"
            if len(q) > 0: q += " "
            q += query
        if active is not None:
            if qf != "gdsc_collections ": qf += " "
            qf += "gdsc_up"
            if len(q) > 0: q += " "
            q += "true"
        if qf != "gdsc_collections ":
            query_parameters = {
              "q.op": "AND",
              "defType": "dismax",
              "qf": qf,
              "q": q
            }

    # query for information and return results
    query_string  = urlencode(query_parameters)
    #print(query_string)
    while numresults > len(results): 
        connection = urlopen("{}{}".format(BASE_PATH, query_string))
        response = simplejson.load(connection)
        numresults = response['response']['numFound']
        results = response['response']['docs']
        query_parameters["rows"] = numresults
        query_string  = urlencode(query_parameters) 
        #print('loop:',query_string) 
    
    if results == None: results=[]
    return render_template('index.html', collection=collection, query=query, active=active, numresults=numresults, results=results)

@app.route('/detail/<name_id>', methods=["GET","POST"])
def detail(name_id):

    query_parameters = {"q": "gdsc_tablename:" + name_id}
    query_string  = urlencode(query_parameters)
    connection = urlopen("{}{}".format(BASE_PATH, query_string))
    response = simplejson.load(connection)
    document = response['response']['docs'][0]
    if 'gdsc_attributes' in document:                                                             
        document['gdsc_columns'] = [attr.split(';')[0] for attr in document['gdsc_attributes']]
        document['gdsc_attributes'] = [attr.split(';') for attr in document['gdsc_attributes']]   

    return render_template('detail.html', name_id=name_id, document=document, referrer=request.args)

if __name__ == '__main__':
    app.run(host='0.0.0.0',debug=True,use_reloader=True)/gdsc