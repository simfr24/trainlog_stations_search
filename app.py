from flask import Flask, request, jsonify
import psycopg2

app = Flask(__name__)

@app.route('/search', methods=['GET'])
def search():
    search_pattern = request.args.get('q', '')
    search_pattern_start = search_pattern + '%'
    search_pattern_anywhere = '%' + search_pattern + '%'

    conn = psycopg2.connect(host='postgres', user='postgres', password='baagzunkykivccqnvcbotadwsz', dbname='postgres')
    cur = conn.cursor()

    query = """
        SELECT * FROM train_stations 
        WHERE 
            name %% %(searchPattern)s
            OR latin_name %% %(searchPattern)s
            OR city %% %(searchPattern)s
            OR latin_city %% %(searchPattern)s
            OR processed_name %% %(searchPattern)s
        ORDER BY 
            CASE 
                WHEN processed_name LIKE %(searchPatternStart)s THEN 1
                WHEN processed_name %% %(searchPattern)s THEN 2
                WHEN name LIKE %(searchPatternStart)s THEN 3
                WHEN name %% %(searchPattern)s THEN 4
                WHEN latin_city LIKE %(searchPatternStart)s THEN 5
                WHEN latin_city %% %(searchPattern)s THEN 6
                WHEN city LIKE %(searchPatternStart)s THEN 7
                WHEN city %% %(searchPattern)s THEN 8
                ELSE 10
            END,
            processed_name <-> %(searchPattern)s,
            name <-> %(searchPattern)s,
            latin_city <-> %(searchPattern)s,
            city <-> %(searchPattern)s
        LIMIT 10;
        """

    params = {
        'searchPattern': search_pattern_anywhere,
        'searchPatternStart': search_pattern_start
    }

    cur.execute(query, params)


    
    results = cur.fetchall()
    columns = [desc[0] for desc in cur.description]
    data = [dict(zip(columns, row)) for row in results]

    cur.close()
    conn.close()

    return jsonify(data)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')
