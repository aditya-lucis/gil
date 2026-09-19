CREATE TABLE "customer_contacts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"customer_id" uuid NOT NULL,
	"name" varchar(180) NOT NULL,
	"title" varchar(100),
	"email" varchar(255),
	"phone" varchar(64),
	"is_primary" boolean DEFAULT false NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid
);
--> statement-breakpoint
CREATE TABLE "customer_groups" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid
);
--> statement-breakpoint
CREATE TABLE "customer_pricings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"customer_id" uuid NOT NULL,
	"item_id" uuid NOT NULL,
	"special_price" numeric(18, 2) NOT NULL,
	"currency_code" varchar(3) DEFAULT 'IDR' NOT NULL,
	"valid_from" date,
	"valid_to" date,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	CONSTRAINT "chk_customer_pricing_price" CHECK ("customer_pricings"."special_price" >= 0),
	CONSTRAINT "chk_customer_pricing_dates" CHECK ("customer_pricings"."valid_to" IS NULL OR "customer_pricings"."valid_from" IS NULL OR "customer_pricings"."valid_to" >= "customer_pricings"."valid_from")
);
--> statement-breakpoint
CREATE TABLE "customers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"group_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"tax_id" varchar(64),
	"credit_limit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"term_id" uuid,
	"ar_account_id" uuid,
	"currency_code" varchar(3) DEFAULT 'IDR' NOT NULL,
	"email" varchar(255),
	"phone" varchar(64),
	"address" text,
	"notes" text,
	"is_blocked" boolean DEFAULT false NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid,
	CONSTRAINT "chk_customers_credit_limit" CHECK ("customers"."credit_limit" >= 0)
);
--> statement-breakpoint
CREATE TABLE "discount_rules" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(180) NOT NULL,
	"discount_type" varchar(20) DEFAULT 'percentage' NOT NULL,
	"discount_value" numeric(18, 2) DEFAULT '0' NOT NULL,
	"min_order_amount" numeric(18, 2) DEFAULT '0',
	"customer_group_id" uuid,
	"valid_from" date,
	"valid_to" date,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	CONSTRAINT "chk_discount_rules_type" CHECK ("discount_rules"."discount_type" IN ('percentage', 'fixed_amount', 'tiered')),
	CONSTRAINT "chk_discount_rules_value" CHECK ("discount_rules"."discount_value" >= 0),
	CONSTRAINT "chk_discount_rules_min_order" CHECK ("discount_rules"."min_order_amount" >= 0),
	CONSTRAINT "chk_discount_rules_dates" CHECK ("discount_rules"."valid_to" IS NULL OR "discount_rules"."valid_from" IS NULL OR "discount_rules"."valid_to" >= "discount_rules"."valid_from")
);
--> statement-breakpoint
CREATE TABLE "payment_terms" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(100) NOT NULL,
	"days" integer DEFAULT 0 NOT NULL,
	"discount_days" integer DEFAULT 0,
	"discount_percentage" numeric(5, 2) DEFAULT '0',
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	CONSTRAINT "chk_payment_terms_days" CHECK ("payment_terms"."days" >= 0),
	CONSTRAINT "chk_payment_terms_disc_days" CHECK ("payment_terms"."discount_days" >= 0),
	CONSTRAINT "chk_payment_terms_disc_pct" CHECK ("payment_terms"."discount_percentage" >= 0)
);
--> statement-breakpoint
CREATE TABLE "price_list_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"price_list_id" uuid NOT NULL,
	"item_id" uuid NOT NULL,
	"unit_price" numeric(18, 2) DEFAULT '0' NOT NULL,
	"min_quantity" numeric(18, 4) DEFAULT '1' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	CONSTRAINT "chk_price_list_items_price" CHECK ("price_list_items"."unit_price" >= 0),
	CONSTRAINT "chk_price_list_items_min_qty" CHECK ("price_list_items"."min_quantity" > 0)
);
--> statement-breakpoint
CREATE TABLE "price_lists" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(180) NOT NULL,
	"currency_code" varchar(3) DEFAULT 'IDR' NOT NULL,
	"description" text,
	"is_default" boolean DEFAULT false NOT NULL,
	"valid_from" date,
	"valid_to" date,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	CONSTRAINT "chk_price_lists_valid_dates" CHECK ("price_lists"."valid_to" IS NULL OR "price_lists"."valid_from" IS NULL OR "price_lists"."valid_to" >= "price_lists"."valid_from")
);
--> statement-breakpoint
CREATE TABLE "salespersons" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"user_id" uuid,
	"department_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(180) NOT NULL,
	"email" varchar(255),
	"phone" varchar(64),
	"commission_rate" numeric(5, 2) DEFAULT '0',
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid,
	CONSTRAINT "chk_salesperson_commission" CHECK ("salespersons"."commission_rate" >= 0)
);
--> statement-breakpoint
CREATE TABLE "supplier_contacts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"supplier_id" uuid NOT NULL,
	"name" varchar(180) NOT NULL,
	"title" varchar(100),
	"email" varchar(255),
	"phone" varchar(64),
	"is_primary" boolean DEFAULT false NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid
);
--> statement-breakpoint
CREATE TABLE "supplier_groups" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid
);
--> statement-breakpoint
CREATE TABLE "suppliers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"group_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"tax_id" varchar(64),
	"term_id" uuid,
	"ap_account_id" uuid,
	"currency_code" varchar(3) DEFAULT 'IDR' NOT NULL,
	"email" varchar(255),
	"phone" varchar(64),
	"bank_name" varchar(100),
	"bank_account_no" varchar(64),
	"bank_account_name" varchar(180),
	"address" text,
	"notes" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid
);
--> statement-breakpoint
ALTER TABLE "customer_contacts" ADD CONSTRAINT "customer_contacts_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customer_contacts" ADD CONSTRAINT "customer_contacts_customer_id_customers_id_fk" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customer_groups" ADD CONSTRAINT "customer_groups_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customer_groups" ADD CONSTRAINT "customer_groups_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customer_pricings" ADD CONSTRAINT "customer_pricings_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customer_pricings" ADD CONSTRAINT "customer_pricings_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customer_pricings" ADD CONSTRAINT "customer_pricings_customer_id_customers_id_fk" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customer_pricings" ADD CONSTRAINT "customer_pricings_currency_code_currencies_code_fk" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customers" ADD CONSTRAINT "customers_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customers" ADD CONSTRAINT "customers_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customers" ADD CONSTRAINT "customers_group_id_customer_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."customer_groups"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customers" ADD CONSTRAINT "customers_term_id_payment_terms_id_fk" FOREIGN KEY ("term_id") REFERENCES "public"."payment_terms"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customers" ADD CONSTRAINT "customers_ar_account_id_accounts_id_fk" FOREIGN KEY ("ar_account_id") REFERENCES "public"."accounts"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "customers" ADD CONSTRAINT "customers_currency_code_currencies_code_fk" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "discount_rules" ADD CONSTRAINT "discount_rules_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "discount_rules" ADD CONSTRAINT "discount_rules_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "discount_rules" ADD CONSTRAINT "discount_rules_customer_group_id_customer_groups_id_fk" FOREIGN KEY ("customer_group_id") REFERENCES "public"."customer_groups"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "payment_terms" ADD CONSTRAINT "payment_terms_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "payment_terms" ADD CONSTRAINT "payment_terms_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "price_list_items" ADD CONSTRAINT "price_list_items_price_list_id_price_lists_id_fk" FOREIGN KEY ("price_list_id") REFERENCES "public"."price_lists"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "price_lists" ADD CONSTRAINT "price_lists_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "price_lists" ADD CONSTRAINT "price_lists_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "price_lists" ADD CONSTRAINT "price_lists_currency_code_currencies_code_fk" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "salespersons" ADD CONSTRAINT "salespersons_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "salespersons" ADD CONSTRAINT "salespersons_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "salespersons" ADD CONSTRAINT "salespersons_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "salespersons" ADD CONSTRAINT "salespersons_department_id_departments_id_fk" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "supplier_contacts" ADD CONSTRAINT "supplier_contacts_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "supplier_contacts" ADD CONSTRAINT "supplier_contacts_supplier_id_suppliers_id_fk" FOREIGN KEY ("supplier_id") REFERENCES "public"."suppliers"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "supplier_groups" ADD CONSTRAINT "supplier_groups_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "supplier_groups" ADD CONSTRAINT "supplier_groups_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "suppliers" ADD CONSTRAINT "suppliers_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "suppliers" ADD CONSTRAINT "suppliers_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "suppliers" ADD CONSTRAINT "suppliers_group_id_supplier_groups_id_fk" FOREIGN KEY ("group_id") REFERENCES "public"."supplier_groups"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "suppliers" ADD CONSTRAINT "suppliers_term_id_payment_terms_id_fk" FOREIGN KEY ("term_id") REFERENCES "public"."payment_terms"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "suppliers" ADD CONSTRAINT "suppliers_ap_account_id_accounts_id_fk" FOREIGN KEY ("ap_account_id") REFERENCES "public"."accounts"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "suppliers" ADD CONSTRAINT "suppliers_currency_code_currencies_code_fk" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_customer_contacts_customer" ON "customer_contacts" USING btree ("customer_id");--> statement-breakpoint
CREATE INDEX "idx_customer_contacts_tenant" ON "customer_contacts" USING btree ("tenant_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_customer_groups_tenant_company_code" ON "customer_groups" USING btree ("tenant_id","company_id","code");--> statement-breakpoint
CREATE INDEX "idx_customer_groups_tenant" ON "customer_groups" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_customer_groups_company" ON "customer_groups" USING btree ("company_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_customer_pricing_key" ON "customer_pricings" USING btree ("customer_id","item_id","valid_from");--> statement-breakpoint
CREATE INDEX "idx_customer_pricing_tenant" ON "customer_pricings" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_customer_pricing_company" ON "customer_pricings" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_customer_pricing_customer" ON "customer_pricings" USING btree ("customer_id");--> statement-breakpoint
CREATE INDEX "idx_customer_pricing_item" ON "customer_pricings" USING btree ("item_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_customers_tenant_company_code" ON "customers" USING btree ("tenant_id","company_id","code");--> statement-breakpoint
CREATE INDEX "idx_customers_tenant" ON "customers" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_customers_company" ON "customers" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_customers_group" ON "customers" USING btree ("group_id");--> statement-breakpoint
CREATE INDEX "idx_customers_ar_account" ON "customers" USING btree ("ar_account_id");--> statement-breakpoint
CREATE INDEX "idx_customers_active" ON "customers" USING btree ("company_id","is_active") WHERE deleted_at IS NULL;--> statement-breakpoint
CREATE UNIQUE INDEX "uq_discount_rules_company_code" ON "discount_rules" USING btree ("company_id","code");--> statement-breakpoint
CREATE INDEX "idx_discount_rules_tenant" ON "discount_rules" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_discount_rules_company" ON "discount_rules" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_discount_rules_group" ON "discount_rules" USING btree ("customer_group_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_payment_terms_tenant_code" ON "payment_terms" USING btree ("tenant_id","company_id","code");--> statement-breakpoint
CREATE INDEX "idx_payment_terms_tenant" ON "payment_terms" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_payment_terms_company" ON "payment_terms" USING btree ("company_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_price_list_items_key" ON "price_list_items" USING btree ("price_list_id","item_id","min_quantity");--> statement-breakpoint
CREATE INDEX "idx_price_list_items_list" ON "price_list_items" USING btree ("price_list_id");--> statement-breakpoint
CREATE INDEX "idx_price_list_items_item" ON "price_list_items" USING btree ("item_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_price_lists_company_code" ON "price_lists" USING btree ("company_id","code");--> statement-breakpoint
CREATE INDEX "idx_price_lists_tenant" ON "price_lists" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_price_lists_company" ON "price_lists" USING btree ("company_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_salespersons_company_code" ON "salespersons" USING btree ("company_id","code");--> statement-breakpoint
CREATE INDEX "idx_salespersons_tenant" ON "salespersons" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_salespersons_company" ON "salespersons" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_salespersons_department" ON "salespersons" USING btree ("department_id");--> statement-breakpoint
CREATE INDEX "idx_salespersons_user" ON "salespersons" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_supplier_contacts_supplier" ON "supplier_contacts" USING btree ("supplier_id");--> statement-breakpoint
CREATE INDEX "idx_supplier_contacts_tenant" ON "supplier_contacts" USING btree ("tenant_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_supplier_groups_tenant_company_code" ON "supplier_groups" USING btree ("tenant_id","company_id","code");--> statement-breakpoint
CREATE INDEX "idx_supplier_groups_tenant" ON "supplier_groups" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_supplier_groups_company" ON "supplier_groups" USING btree ("company_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_suppliers_tenant_company_code" ON "suppliers" USING btree ("tenant_id","company_id","code");--> statement-breakpoint
CREATE INDEX "idx_suppliers_tenant" ON "suppliers" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_suppliers_company" ON "suppliers" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_suppliers_group" ON "suppliers" USING btree ("group_id");--> statement-breakpoint
CREATE INDEX "idx_suppliers_ap_account" ON "suppliers" USING btree ("ap_account_id");--> statement-breakpoint
CREATE INDEX "idx_suppliers_active" ON "suppliers" USING btree ("company_id","is_active") WHERE deleted_at IS NULL;