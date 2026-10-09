# IT Consumables Warehouse — Offline

Requires Python 3.9 or later. No package installs or internet connection are needed.

1. Extract this ZIP into a folder you can write to.
2. Open a terminal in that folder.
3. Run `python3 app.py` (Windows: `py app.py`).
4. Open http://localhost:8080 in your browser.

Use `python3 app.py --port 8081` if port 8080 is busy. Stop with Ctrl+C.

## Included
- `app.py`: local server using Python's standard library
- `index.html`: inventory, shipments, invoices, stock ledger, search and CSV exports
- `schema.sql`: full SQLite schema
- `warehouse.db`: empty ready-to-use SQLite database
- `start.bat` / `start.sh`: convenient launchers

Start with Inventory → Add consumable, then Receive / issue to enter stock. Shipment references and invoice records can be linked to each movement. All data stays in `warehouse.db`. It persists when you close the browser or stop the app. It does not synchronise with the hosted version; this package starts empty.

Tracks SKU, container number/size/type/TEU, B/L, Customs DO, BACC#, import/export document references, domestic carrier/consignment, destination, and invoice amounts (GST-inclusive).

Only this computer can access the server. No automatic carrier tracking, Customs/MPI submissions, or document uploads are included. Document fields store references. Shipment/invoice statuses are maintained manually. One bin/location is recorded per SKU. Keep quantities in the item's chosen unit.

## Backups
Stop the app and copy `warehouse.db` to a safe location. To restore, stop the app and replace `warehouse.db` with your backup. Keep a backup before editing the database with another SQL tool.
