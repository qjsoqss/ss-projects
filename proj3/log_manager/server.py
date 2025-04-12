from flask import Flask, render_template, request
import os
from pymongo import MongoClient
from collections import defaultdict
from math import ceil
from logs_manager import scanVms
from logs_manager import get_ip

app = Flask(__name__)

my_dns = os.getenv('MY_DNS', '192.168.56.9')
mongo_uri = os.getenv('MONGO_URI', 'mongodb://root:example@localhost:27017/')
mongo_client = MongoClient(mongo_uri)
db = mongo_client["logs_db"]
collection = db["logs"]


@app.route('/report', methods=['GET'])
def generate_report():
    page = int(request.args.get('page', 1))
    per_page = 10

    all_logs = collection.find()
    report = defaultdict(lambda: {"ip": "", "total_records": 0})

    for log in all_logs:
        vms = log.get('vms', {})
        for receiver_name, senders in vms.items():
            for sender_vm, timestamps in senders.items():
                report[sender_vm]["total_records"] += len(timestamps)
                if not report[sender_vm]["ip"]:
                    report[sender_vm]["ip"] = get_ip(sender_vm + ".vmnet")

    final_report = dict(report)
    total_records = len(final_report)

    start = (page - 1) * per_page
    end = start + per_page
    paginated_report = dict(list(final_report.items())[start:end])
    total_pages = ceil(total_records / per_page)

    return render_template(
        'report.html',
        report=paginated_report,
        logs_by_day=None,
        available_dates=None,
        selected_date=None,
        page=page,
        total_pages=total_pages
    )

@app.route('/refresh', methods=['GET'])
def refresh_logs():
    scanVms()
    return generate_report()

@app.route('/logs_by_day', methods=['GET'])
def logs_by_day():
    selected_date = request.args.get('date')
    sort_order = request.args.get('sort', 'asc')
    all_logs_cursor = sort_logs(sort_order)

    logs_by_day = {}
    available_dates = []

    for log in all_logs_cursor:
        date = log.get('date')
        available_dates.append(date)
        vms = log.get('vms', {})

        if not selected_date or date == selected_date:
            logs_by_day[date] = vms

    available_dates = sorted(set(available_dates))

    return render_template(
        'report.html',
        report=None,
        logs_by_day=logs_by_day,
        available_dates=available_dates,
        selected_date=selected_date,
        page=1,
        total_pages=1
    )

def sort_logs(sort_order='asc'):
    if sort_order == 'asc':
        return collection.find().sort('date', 1)
    else:
        return collection.find().sort('date', -1)

@app.route('/', methods=['GET'])
def home():
    return generate_report()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
