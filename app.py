#!/usr/bin/env python3
"""Offline warehouse tool; Python standard library only."""
import argparse, datetime, json, math, sqlite3, uuid
from pathlib import Path
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
ROOT = Path(__file__).resolve().parent
TABLES = ('products', 'shipments', 'invoices', 'movements')
DB_PATH = ROOT / 'warehouse.db'
def connect():
    c = sqlite3.connect(DB_PATH, timeout=15)
    c.row_factory = sqlite3.Row
    c.execute('PRAGMA foreign_keys=ON')
    return c
def initialise():
    with connect() as c:
        if not c.execute("SELECT 1 FROM sqlite_master WHERE name='products'").fetchone():
            c.executescript((ROOT / 'schema.sql').read_text())
def text(b, k, required=True):
    v = str(b.get(k) or '').strip()
    if len(v)>200 or (required and not v): raise ValueError('Enter a valid '+k.replace('_',' '))
    return v
def numeric(b,k,integer=False,minimum=0):
    try: v=float(b[k])
    except (KeyError,ValueError,TypeError): raise ValueError('Invalid '+k)
    if not math.isfinite(v) or v<minimum or (integer and not v.is_integer()): raise ValueError('Invalid '+k)
    return int(v) if integer else v
def choice(b,k,allowed):
    v=text(b,k)
    if v not in allowed: raise ValueError('Invalid '+k)
    return v
def date(b,k):
    v=text(b,k)
    datetime.date.fromisoformat(v)
    return v
def save(entity,b):
    identifier=str(uuid.uuid4())
    with connect() as c:
        if entity=='products':
            columns=['sku','name','category','unit','location','minimum','quantity']
            values=[text(b,k) for k in columns[:5]]+[numeric(b,'minimum',True),0]
        elif entity=='shipments':
            optional=['bl','customs_do','bacc','packing_list','origin_certificate','treatment_certificate','declaration','importer_code','carrier','consignment','destination','destination_country','customs_client_code','export_entry','export_certificate','market_access_reference']
            columns=['container','supplier','eta','direction','size','container_type','status','delivery_status']+optional
            values=[text(b,'container'),text(b,'supplier'),date(b,'eta'),choice(b,'direction',['Import','Export','Domestic']),choice(b,'size',['10','20','40','45']),choice(b,'container_type',['General purpose','High cube','Refrigerated','Open top','Side opening','Dangerous goods','Insulated']),choice(b,'status',['In transit','Awaiting clearance','Cleared','Received','Dispatched','Delivered']),choice(b,'delivery_status',['Not booked','Booked','Collected','In transit','Delivered'])]+[text(b,k,False) for k in optional]
        elif entity=='invoices':
            columns=['number','shipment_id','supplier','amount','currency','due','status']
            values=[text(b,'number'),text(b,'shipment_id',False) or None,text(b,'supplier'),numeric(b,'amount'),choice(b,'currency',['NZD','USD','AUD','EUR']),date(b,'due'),choice(b,'status',['Unpaid','Paid'])]
        elif entity=='movements':
            qty=numeric(b,'quantity',True,1);kind=choice(b,'kind',['Receive','Issue']);pid=text(b,'product_id');shipment=text(b,'shipment_id',False) or None;invoice=text(b,'invoice_id',False) or None;reference=text(b,'reference')
            c.execute('BEGIN IMMEDIATE')
            if invoice:
                inv=c.execute('SELECT shipment_id FROM invoices WHERE id=?',(invoice,)).fetchone()
                if not inv: raise ValueError('Invoice does not exist')
                if shipment and inv['shipment_id'] and inv['shipment_id']!=shipment: raise ValueError('Invoice belongs to a different shipment')
            delta=qty if kind=='Receive' else -qty
            update=c.execute('UPDATE products SET quantity=quantity+? WHERE id=? AND quantity+?>=0',(delta,pid,delta))
            if update.rowcount!=1: raise ValueError('Not enough stock, or consumable no longer exists')
            c.execute('INSERT INTO movements VALUES(?,?,?,?,?,?,?,?)',(identifier,pid,shipment,invoice,kind,qty,reference,datetime.datetime.now(datetime.timezone.utc).isoformat()))
            return {'id':identifier,'success':True}
        else: raise ValueError('Unknown operation')
        if b.get('id'):
            if entity=='products': raise ValueError('Record stock changes through the ledger')
            identifier=text(b,'id')
            result=c.execute('UPDATE '+entity+' SET '+','.join(k+'=?' for k in columns)+' WHERE id=?',values+[identifier])
            if not result.rowcount: raise ValueError('Record no longer exists')
        else:
            c.execute('INSERT INTO '+entity+' (id,'+','.join(columns)+') VALUES ('+','.join('?' for _ in range(len(values)+1))+')',[identifier]+values)
    return {'id':identifier,'success':True}
class Handler(BaseHTTPRequestHandler):
    def respond(self,data,status=200,content='application/json'):
        raw=json.dumps(data).encode() if content=='application/json' else data
        self.send_response(status);self.send_header('Content-Type',content);self.send_header('Cache-Control','no-store');self.send_header('Content-Length',str(len(raw)));self.end_headers();self.wfile.write(raw)
    def do_GET(self):
        path=self.path.split('?')[0]
        if path=='/api/data':
            try:
                with connect() as c:
                    data={t:[dict(r) for r in c.execute('SELECT * FROM '+t+' ORDER BY '+('created DESC' if t=='movements' else 'rowid DESC'))] for t in TABLES}
                self.respond(data)
            except sqlite3.Error: self.respond({'error':'Database unavailable'},503)
        elif path in ('/','/index.html','/schema.sql'):
            self.respond((ROOT/('schema.sql' if path=='/schema.sql' else 'index.html')).read_bytes(),content='text/plain' if path=='/schema.sql' else 'text/html; charset=utf-8')
        else: self.respond({'error':'Not found'},404)
    def do_POST(self):
        origin=self.headers.get('Origin')
        if origin and origin not in ('http://'+self.headers.get('Host',''),): return self.respond({'error':'Invalid origin'},403)
        if self.headers.get('Content-Type','').split(';')[0]!='application/json': return self.respond({'error':'JSON required'},415)
        try:
            length=int(self.headers.get('Content-Length',0))
            if not 0<length<=32768: raise ValueError('Invalid request size')
            b=json.loads(self.rfile.read(length))
            if not isinstance(b,dict): raise ValueError('Invalid request')
            self.respond(save(self.path.removeprefix('/api/'),b),201)
        except sqlite3.IntegrityError as e:
            self.respond({'error':'Duplicate SKU or invoice number.' if 'UNIQUE' in str(e) else 'Invalid linked record or quantity.'},400)
        except (ValueError,TypeError,KeyError) as e: self.respond({'error':str(e)},400)
        except sqlite3.Error: self.respond({'error':'Database operation failed. Please try again.'},503)
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--port',type=int,default=8080);args=parser.parse_args();initialise()
    print(f'Warehouse running at http://localhost:{args.port}\nDatabase: {DB_PATH}\nPress Ctrl+C to stop.',flush=True)
    try: ThreadingHTTPServer(('127.0.0.1',args.port),Handler).serve_forever()
    except KeyboardInterrupt: print('\nStopped.')
if __name__=='__main__': main()
