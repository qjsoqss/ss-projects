import os
import paramiko
from pymongo import MongoClient
from collections import defaultdict

my_dns = os.getenv('MY_DNS', '192.168.56.9')
mongo_uri = os.getenv('MONGO_URI', 'mongodb://root:example@localhost:27017/')
private_key_path = os.getenv('PRIVATE_KEY_PATH', 'id_ed25519')
number_of_vms = int(os.getenv('NUMBER_OF_VMS', 3))

private_key = paramiko.Ed25519Key.from_private_key_file(private_key_path)

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

mongo_client = MongoClient(mongo_uri)
db = mongo_client["logs_db"]
collection = db["logs"]


def get_ip(hostname):
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(hostname=my_dns, port=22, username='student', pkey=private_key)
        command = f"nslookup {hostname} 127.0.0.1"
        stdin, stdout, stderr = client.exec_command(command)
        
        output = stdout.read().decode()
        client.close()

        ip_address = None
        found_answer = False
        for line in output.splitlines():
            if 'Name:' in line:
                found_answer = True
            elif found_answer and 'Address:' in line:
                ip_address = line.split()[-1]
                break

        if not ip_address:
            raise Exception(f"Hostname {hostname} not resolved")

        return ip_address

    except Exception as e:
        print(f"Failed to resolve {hostname}: {e}")
        try:
            client.close()
        except:
            pass
        return None

def scanVms():
    logs_data = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    for i in range(1, number_of_vms + 1):
        hostname = f"vm{i}.vmnet"
        ip_address = get_ip(hostname)
        print(f"VM {i}: {ip_address}")
        try:
            print(f"Connecting to {hostname} at {ip_address}...")
            client.connect(hostname=ip_address, port=22, username='vagrant', pkey=private_key)
            unzip_logs(client)
            paths_to_search = [
                '/srv/sftpuser/data',
                '/tmp/unzipped_logs'
            ]
            for path in paths_to_search:
                stdin, stdout, stderr = client.exec_command(f'find {path} -name "log_by*.txt"')
                log_files = stdout.read().decode().splitlines()
                for file_path in log_files:
                    stdin, stdout, stderr = client.exec_command(f'cat {file_path}')
                    lines = stdout.read().decode().splitlines()

                    sender_vm = file_path.split('/')[-1].split('_')[2]  
                    date = file_path.split('/')[-1].split('_')[3].split('.')[0]  
                    for line in lines:
                        try:
                            parts = line.split()
                            sender_vm = parts[2]  
                            timestamp = parts[4]  
                            receiver_vm = hostname.split('.')[0]  
                            logs_data[date][receiver_vm][sender_vm].append(timestamp)
                        except Exception as e:
                            print(f"Failed to parse line '{line}': {e}")
        except Exception as e:
            print(f"Failed to connect to {hostname}: {e}")
        finally:
            client.close()

    insert_logs_to_mongo(logs_data)

def insert_logs_to_mongo(logs_data):
    for date, receivers in logs_data.items():
        existing_doc = collection.find_one({"date": date})
        
        if not existing_doc:
            document = {"date": date, "vms": dict(receivers)}
            collection.insert_one(document)
        else:
            updated_vms = existing_doc.get("vms", {})
            for receiver_vm, senders in receivers.items():
                if receiver_vm not in updated_vms:
                    updated_vms[receiver_vm] = {}
                for sender_vm, timestamps in senders.items():
                    if sender_vm not in updated_vms[receiver_vm]:
                        updated_vms[receiver_vm][sender_vm] = []
                    for ts in timestamps:
                        if ts not in updated_vms[receiver_vm][sender_vm]:
                            updated_vms[receiver_vm][sender_vm].append(ts)
            collection.update_one({"date": date}, {"$set": {"vms": updated_vms}})

def unzip_logs(client):
    stdin, stdout, stderr = client.exec_command('test -f ~/logs_arch.zip && echo "Found" || echo "Not Found"')
    result = stdout.read().decode().strip()
    if result == "Found":
        print("Found logs_arch.zip, extracting...")
        client.exec_command('mkdir -p /tmp/unzipped_logs')
        client.exec_command('unzip -o ~/logs_arch.zip -d /tmp/unzipped_logs')
    else:
        print("No archive found, skipping extraction.")

if __name__ == "__main__":
    scanVms()
