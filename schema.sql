CREATE TABLE `invoices` (
	`id` text PRIMARY KEY NOT NULL,
	`number` text NOT NULL,
	`shipment_id` text,
	`supplier` text NOT NULL,
	`amount` real NOT NULL,
	`currency` text NOT NULL,
	`due` text NOT NULL,
	`status` text NOT NULL,
	FOREIGN KEY (`shipment_id`) REFERENCES `shipments`(`id`) ON UPDATE no action ON DELETE no action,
	CONSTRAINT "positive_amount" CHECK("invoices"."amount" >= 0)
);
--> statement-breakpoint
CREATE UNIQUE INDEX `invoices_number_unique` ON `invoices` (`number`);--> statement-breakpoint
CREATE INDEX `idx_invoices_shipment` ON `invoices` (`shipment_id`);--> statement-breakpoint
CREATE TABLE `movements` (
	`id` text PRIMARY KEY NOT NULL,
	`product_id` text NOT NULL,
	`shipment_id` text,
	`invoice_id` text,
	`kind` text NOT NULL,
	`quantity` integer NOT NULL,
	`reference` text NOT NULL,
	`created` text NOT NULL,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`shipment_id`) REFERENCES `shipments`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`invoice_id`) REFERENCES `invoices`(`id`) ON UPDATE no action ON DELETE no action,
	CONSTRAINT "movement_positive" CHECK("movements"."quantity" > 0)
);
--> statement-breakpoint
CREATE INDEX `idx_movements_product` ON `movements` (`product_id`);--> statement-breakpoint
CREATE TABLE `products` (
	`id` text PRIMARY KEY NOT NULL,
	`sku` text NOT NULL,
	`name` text NOT NULL,
	`category` text NOT NULL,
	`unit` text NOT NULL,
	`location` text NOT NULL,
	`minimum` integer DEFAULT 0 NOT NULL,
	`quantity` integer DEFAULT 0 NOT NULL,
	CONSTRAINT "positive_stock" CHECK("products"."quantity" >= 0),
	CONSTRAINT "positive_minimum" CHECK("products"."minimum" >= 0)
);
--> statement-breakpoint
CREATE UNIQUE INDEX `products_sku_unique` ON `products` (`sku`);--> statement-breakpoint
CREATE TABLE `shipments` (
	`id` text PRIMARY KEY NOT NULL,
	`container` text NOT NULL,
	`size` text DEFAULT '20' NOT NULL,
	`container_type` text DEFAULT 'General purpose' NOT NULL,
	`bl` text NOT NULL,
	`customs_do` text NOT NULL,
	`bacc` text NOT NULL,
	`supplier` text NOT NULL,
	`eta` text NOT NULL,
	`status` text NOT NULL
);

ALTER TABLE `shipments` ADD `packing_list` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `origin_certificate` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `treatment_certificate` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `declaration` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `importer_code` text DEFAULT '' NOT NULL;
ALTER TABLE `shipments` ADD `carrier` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `consignment` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `destination` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `delivery_status` text DEFAULT 'Not booked' NOT NULL;
ALTER TABLE `shipments` ADD `direction` text DEFAULT 'Import' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `destination_country` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `customs_client_code` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `export_entry` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `export_certificate` text DEFAULT '' NOT NULL;--> statement-breakpoint
ALTER TABLE `shipments` ADD `market_access_reference` text DEFAULT '' NOT NULL;