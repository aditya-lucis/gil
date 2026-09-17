CREATE TABLE "branches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"is_head_office" boolean DEFAULT false NOT NULL,
	"address_id" uuid,
	"manager_user_id" uuid,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid
);
--> statement-breakpoint
CREATE TABLE "companies" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"organization_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"legal_name" varchar(500),
	"tax_id" varchar(64),
	"address_id" uuid,
	"base_currency_code" varchar(3) DEFAULT 'IDR' NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid
);
--> statement-breakpoint
CREATE TABLE "currencies" (
	"code" varchar(3) PRIMARY KEY NOT NULL,
	"name" varchar(100) NOT NULL,
	"symbol" varchar(10) NOT NULL,
	"decimal_places" integer DEFAULT 2 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "chk_decimal_places" CHECK ("currencies"."decimal_places" >= 0)
);
--> statement-breakpoint
CREATE TABLE "departments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"parent_id" uuid,
	"head_user_id" uuid,
	"cost_center_id" uuid,
	"level" integer DEFAULT 0 NOT NULL,
	"path" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid,
	CONSTRAINT "chk_department_level" CHECK ("departments"."level" >= 0)
);
--> statement-breakpoint
CREATE TABLE "exchange_rates" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"from_currency" varchar(3) NOT NULL,
	"to_currency" varchar(3) NOT NULL,
	"rate" numeric(20, 6) NOT NULL,
	"effective_date" date NOT NULL,
	"rate_type" varchar(32) DEFAULT 'spot' NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid,
	CONSTRAINT "chk_rate_positive" CHECK ("exchange_rates"."rate" > 0)
);
--> statement-breakpoint
CREATE TABLE "organizations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"tax_id" varchar(64),
	"base_currency_code" varchar(3) DEFAULT 'IDR' NOT NULL,
	"fiscal_year_start_month" integer DEFAULT 1 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid,
	CONSTRAINT "chk_org_fiscal_month" CHECK ("organizations"."fiscal_year_start_month" BETWEEN 1 AND 12)
);
--> statement-breakpoint
CREATE TABLE "tenants" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"plan" varchar(32) DEFAULT 'standard' NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"settings_json" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid,
	CONSTRAINT "tenants_code_unique" UNIQUE("code"),
	CONSTRAINT "chk_tenant_plan" CHECK ("tenants"."plan" IN ('standard', 'professional', 'enterprise'))
);
--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "branches" ADD CONSTRAINT "branches_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "companies" ADD CONSTRAINT "companies_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "companies" ADD CONSTRAINT "companies_organization_id_organizations_id_fk" FOREIGN KEY ("organization_id") REFERENCES "public"."organizations"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "companies" ADD CONSTRAINT "companies_base_currency_code_currencies_code_fk" FOREIGN KEY ("base_currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "departments" ADD CONSTRAINT "departments_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "departments" ADD CONSTRAINT "departments_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "departments" ADD CONSTRAINT "departments_parent_id_departments_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."departments"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "exchange_rates" ADD CONSTRAINT "exchange_rates_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "exchange_rates" ADD CONSTRAINT "exchange_rates_from_currency_currencies_code_fk" FOREIGN KEY ("from_currency") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "exchange_rates" ADD CONSTRAINT "exchange_rates_to_currency_currencies_code_fk" FOREIGN KEY ("to_currency") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "organizations" ADD CONSTRAINT "organizations_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "organizations" ADD CONSTRAINT "organizations_base_currency_code_currencies_code_fk" FOREIGN KEY ("base_currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "uq_branches_company_code" ON "branches" USING btree ("company_id","code");--> statement-breakpoint
CREATE INDEX "idx_branches_tenant" ON "branches" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_branches_company" ON "branches" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_branches_active" ON "branches" USING btree ("company_id","is_active") WHERE deleted_at IS NULL;--> statement-breakpoint
CREATE UNIQUE INDEX "uq_companies_tenant_org_code" ON "companies" USING btree ("tenant_id","organization_id","code");--> statement-breakpoint
CREATE INDEX "idx_companies_tenant" ON "companies" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_companies_org" ON "companies" USING btree ("organization_id");--> statement-breakpoint
CREATE INDEX "idx_companies_active" ON "companies" USING btree ("tenant_id","is_active") WHERE deleted_at IS NULL;--> statement-breakpoint
CREATE UNIQUE INDEX "uq_departments_company_code" ON "departments" USING btree ("company_id","code");--> statement-breakpoint
CREATE INDEX "idx_departments_tenant" ON "departments" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_departments_company" ON "departments" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_departments_parent" ON "departments" USING btree ("parent_id");--> statement-breakpoint
CREATE INDEX "idx_departments_active" ON "departments" USING btree ("company_id","is_active") WHERE deleted_at IS NULL;--> statement-breakpoint
CREATE UNIQUE INDEX "uq_exchange_rates_daily" ON "exchange_rates" USING btree ("tenant_id","from_currency","to_currency","effective_date","rate_type");--> statement-breakpoint
CREATE INDEX "idx_exchange_rates_tenant" ON "exchange_rates" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_exchange_rates_lookup" ON "exchange_rates" USING btree ("from_currency","to_currency","effective_date");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_org_tenant_code" ON "organizations" USING btree ("tenant_id","code");--> statement-breakpoint
CREATE INDEX "idx_organizations_tenant" ON "organizations" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_organizations_active" ON "organizations" USING btree ("tenant_id","is_active") WHERE deleted_at IS NULL;--> statement-breakpoint
CREATE INDEX "idx_tenants_active" ON "tenants" USING btree ("is_active") WHERE deleted_at IS NULL;