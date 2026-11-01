# IT Consumables Warehouse — Offline

Requires Python 3.9 or later. No package installs or internet connection are needed.

1. Extract this ZIP into a folder you can write to.
2. Open a terminal in that folder.
3. Run `python3 app.py` (Windows: `py app.py`).
4. Open http://localhost:8080 in your browser.

Use `python3 app.py --port 8081` if port 8080 is busy. Stop with Ctrl+C.

## Included
- `app.py`: local server using Python's standard library
- `index.html`: inventory, shipments, invoices, stock ledger, business analysis, search and CSV exports
- `schema.sql`: full SQLite schema
- `sql/ba.sql`: stock valuation and markup queries
- `excel/WarehouseExcel.bas`: the same two calculations for desktop Excel
- `warehouse.db`: empty ready-to-use SQLite database
- `start.bat` / `start.sh`: convenient launchers

Start with Inventory → Add consumable (include unit cost and markup when you know them), then Receive / issue to enter stock. Shipment references and invoice records can be linked to each movement. All data stays in `warehouse.db`. It persists when you close the browser or stop the app. It does not synchronise with the hosted version; this package starts empty.

Tracks SKU, unit cost, markup percent, container number/size/type/TEU, B/L, Customs DO, BACC#, import/export document references, domestic carrier/consignment, destination, and invoice amounts (GST-inclusive).

## Business analysis

Open Analysis in the app. It runs `sql/ba.sql` on `warehouse.db`.

- Valuation lists consumables whose unit cost is over 50. Total is unit cost times quantity on hand, highest total first.
- Price clean sets cleaned cost to unit cost × (1 + markup% / 100), and floors the result at 0. A markup of 20 means 20 percent. SKUs with no cost and no markup are left off this list.

Enter unit cost and markup when you add a consumable. Quantity still changes only through Receive / issue.

To run the same statements in a shell:

```bash
sqlite3 warehouse.db < sql/ba.sql
```

## Excel

`excel/WarehouseExcel.bas` repeats those two calculations in desktop Excel on Windows. Import the module in the VBA editor. The ACE provider has to match Excel's bitness, and the workbook has to be saved as xlsx, xlsm, xlsb, or xls.

- `QueryStockValue` reads sheet `Stock` with headers `SKU`, `Name`, `UnitCost`, `Quantity`. It writes sheet `Valuation` for rows with unit cost over 50.
- `CleanCostsOffline` reads sheet `Raw` from row 2: `SKU`, `Cost`, `Markup%`. It writes the marked-up cost onto sheet `Cleaned`. Blank rows stay blank. Values such as `$1,250.00` are accepted.

On the Analysis page, Export stock sheet and Export cost sheet use those headers. Paste each CSV into the matching sheet with the header on row 1. The Excel module does not open `warehouse.db`. The in-app figures come from SQLite.

Only this computer can access the server. No automatic carrier tracking, Customs/MPI submissions, or document uploads are included. Document fields store references. Shipment/invoice statuses are maintained manually. One bin/location is recorded per SKU. Keep quantities in the item's chosen unit.

## Backups
Stop the app and copy `warehouse.db` to a safe location. To restore, stop the app and replace `warehouse.db` with your backup. Keep a backup before editing the database with another SQL tool.
