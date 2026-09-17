CREATE TABLE "account_groups" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"account_type_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "account_groups_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "account_types" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(100) NOT NULL,
	"normal_balance" varchar(10) DEFAULT 'debit' NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "account_types_code_unique" UNIQUE("code"),
	CONSTRAINT "chk_account_type_normal_balance" CHECK ("account_types"."normal_balance" IN ('debit', 'credit'))
);
--> statement-breakpoint
CREATE TABLE "accounts" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"account_type_id" uuid NOT NULL,
	"account_group_id" uuid,
	"parent_id" uuid,
	"level" integer DEFAULT 0 NOT NULL,
	"is_postable" boolean DEFAULT true NOT NULL,
	"is_control_account" boolean DEFAULT false NOT NULL,
	"currency_code" varchar(3) DEFAULT 'IDR' NOT NULL,
	"default_department_id" uuid,
	"is_sensitive" boolean DEFAULT false NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid,
	CONSTRAINT "chk_account_level" CHECK ("accounts"."level" >= 0)
);
--> statement-breakpoint
CREATE TABLE "cost_centers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"department_id" uuid,
	"parent_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid
);
--> statement-breakpoint
CREATE TABLE "currency_revaluations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"period_id" uuid NOT NULL,
	"currency_code" varchar(3) NOT NULL,
	"rate_used" numeric(20, 6) NOT NULL,
	"unrealized_gain_loss" numeric(18, 2) DEFAULT '0' NOT NULL,
	"journal_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid
);
--> statement-breakpoint
CREATE TABLE "dimension_members" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"dimension_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "dimensions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "fiscal_periods" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"fiscal_year_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"name" varchar(32) NOT NULL,
	"period_number" integer NOT NULL,
	"start_date" date NOT NULL,
	"end_date" date NOT NULL,
	"status" varchar(16) DEFAULT 'open' NOT NULL,
	"soft_closed_at" timestamp with time zone,
	"soft_closed_by" uuid,
	"hard_closed_at" timestamp with time zone,
	"hard_closed_by" uuid,
	"adjustment_period" boolean DEFAULT false NOT NULL,
	CONSTRAINT "chk_fp_period_number" CHECK ("fiscal_periods"."period_number" BETWEEN 1 AND 13),
	CONSTRAINT "chk_fp_dates" CHECK ("fiscal_periods"."end_date" > "fiscal_periods"."start_date"),
	CONSTRAINT "chk_fp_status" CHECK ("fiscal_periods"."status" IN ('open', 'soft_closed', 'hard_closed', 'reopened'))
);
--> statement-breakpoint
CREATE TABLE "fiscal_years" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"company_id" uuid NOT NULL,
	"name" varchar(32) NOT NULL,
	"start_date" date NOT NULL,
	"end_date" date NOT NULL,
	"status" varchar(16) DEFAULT 'open' NOT NULL,
	"is_adjustment" boolean DEFAULT false NOT NULL,
	CONSTRAINT "chk_fy_status" CHECK ("fiscal_years"."status" IN ('open', 'closed')),
	CONSTRAINT "chk_fy_dates" CHECK ("fiscal_years"."end_date" > "fiscal_years"."start_date")
);
--> statement-breakpoint
CREATE TABLE "journal_batches" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"batch_number" varchar(64) NOT NULL,
	"description" text,
	"status" varchar(16) DEFAULT 'open' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	CONSTRAINT "journal_batches_batch_number_unique" UNIQUE("batch_number"),
	CONSTRAINT "chk_batch_status" CHECK ("journal_batches"."status" IN ('open', 'posted', 'cancelled'))
);
--> statement-breakpoint
CREATE TABLE "journal_categories" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	CONSTRAINT "journal_categories_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "journal_lines" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"journal_id" uuid NOT NULL,
	"line_number" integer NOT NULL,
	"account_id" uuid NOT NULL,
	"department_id" uuid,
	"cost_center_id" uuid,
	"project_id" uuid,
	"dimension_member_id" uuid,
	"debit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"credit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"debit_foreign" numeric(18, 2),
	"credit_foreign" numeric(18, 2),
	"currency_code" varchar(3),
	"exchange_rate" numeric(20, 6),
	"description" text,
	"budget_line_id" uuid,
	"source_doc_type" varchar(64),
	"source_doc_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	CONSTRAINT "chk_debit_or_credit" CHECK (("journal_lines"."debit" > 0 AND "journal_lines"."credit" = 0) OR ("journal_lines"."credit" > 0 AND "journal_lines"."debit" = 0))
);
--> statement-breakpoint
CREATE TABLE "journal_sources" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	CONSTRAINT "journal_sources_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "journals" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"branch_id" uuid,
	"journal_number" varchar(64) NOT NULL,
	"source_id" uuid NOT NULL,
	"category_id" uuid,
	"batch_id" uuid,
	"period_id" uuid NOT NULL,
	"entry_date" date NOT NULL,
	"description" text,
	"status" varchar(16) DEFAULT 'draft' NOT NULL,
	"is_reversing" boolean DEFAULT false NOT NULL,
	"reverses_journal_id" uuid,
	"is_recurring" boolean DEFAULT false NOT NULL,
	"recurring_template_id" uuid,
	"is_closing" boolean DEFAULT false NOT NULL,
	"currency_code" varchar(3) DEFAULT 'IDR' NOT NULL,
	"exchange_rate" numeric(20, 6) DEFAULT '1' NOT NULL,
	"total_debit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"total_credit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"posted_at" timestamp with time zone,
	"posted_by" uuid,
	"approval_request_id" uuid,
	"is_reopened_period" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	CONSTRAINT "journals_journal_number_unique" UNIQUE("journal_number"),
	CONSTRAINT "chk_journal_status" CHECK ("journals"."status" IN ('draft', 'posted', 'reversed', 'cancelled')),
	CONSTRAINT "chk_journal_exchange_rate" CHECK ("journals"."exchange_rate" > 0),
	CONSTRAINT "chk_journal_balanced" CHECK ("journals"."total_debit" = "journals"."total_credit")
);
--> statement-breakpoint
CREATE TABLE "opening_balances" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"fiscal_year_id" uuid NOT NULL,
	"balance_debit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"balance_credit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"currency_code" varchar(3) DEFAULT 'IDR' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "projects" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"department_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"description" text,
	"status" varchar(32) DEFAULT 'active' NOT NULL,
	"start_date" date,
	"end_date" date,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid,
	CONSTRAINT "chk_project_dates" CHECK ("projects"."end_date" IS NULL OR "projects"."start_date" IS NULL OR "projects"."end_date" >= "projects"."start_date")
);
--> statement-breakpoint
CREATE TABLE "recurring_journal_templates" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"frequency" varchar(32) DEFAULT 'monthly' NOT NULL,
	"description" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid
);
--> statement-breakpoint
CREATE TABLE "trial_balance_snapshots" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"company_id" uuid NOT NULL,
	"period_id" uuid NOT NULL,
	"account_id" uuid NOT NULL,
	"opening_debit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"opening_credit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"period_debit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"period_credit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"closing_debit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"closing_credit" numeric(18, 2) DEFAULT '0' NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "account_groups" ADD CONSTRAINT "account_groups_account_type_id_account_types_id_fk" FOREIGN KEY ("account_type_id") REFERENCES "public"."account_types"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_account_type_id_account_types_id_fk" FOREIGN KEY ("account_type_id") REFERENCES "public"."account_types"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_account_group_id_account_groups_id_fk" FOREIGN KEY ("account_group_id") REFERENCES "public"."account_groups"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_parent_id_accounts_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."accounts"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_currency_code_currencies_code_fk" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "accounts" ADD CONSTRAINT "accounts_default_department_id_departments_id_fk" FOREIGN KEY ("default_department_id") REFERENCES "public"."departments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "cost_centers" ADD CONSTRAINT "cost_centers_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "cost_centers" ADD CONSTRAINT "cost_centers_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "cost_centers" ADD CONSTRAINT "cost_centers_department_id_departments_id_fk" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "cost_centers" ADD CONSTRAINT "cost_centers_parent_id_cost_centers_id_fk" FOREIGN KEY ("parent_id") REFERENCES "public"."cost_centers"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "currency_revaluations" ADD CONSTRAINT "currency_revaluations_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "currency_revaluations" ADD CONSTRAINT "currency_revaluations_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "currency_revaluations" ADD CONSTRAINT "currency_revaluations_period_id_fiscal_periods_id_fk" FOREIGN KEY ("period_id") REFERENCES "public"."fiscal_periods"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "currency_revaluations" ADD CONSTRAINT "currency_revaluations_currency_code_currencies_code_fk" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "currency_revaluations" ADD CONSTRAINT "currency_revaluations_journal_id_journals_id_fk" FOREIGN KEY ("journal_id") REFERENCES "public"."journals"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "dimension_members" ADD CONSTRAINT "dimension_members_dimension_id_dimensions_id_fk" FOREIGN KEY ("dimension_id") REFERENCES "public"."dimensions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "dimensions" ADD CONSTRAINT "dimensions_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fiscal_periods" ADD CONSTRAINT "fiscal_periods_fiscal_year_id_fiscal_years_id_fk" FOREIGN KEY ("fiscal_year_id") REFERENCES "public"."fiscal_years"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fiscal_periods" ADD CONSTRAINT "fiscal_periods_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fiscal_periods" ADD CONSTRAINT "fiscal_periods_soft_closed_by_users_id_fk" FOREIGN KEY ("soft_closed_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fiscal_periods" ADD CONSTRAINT "fiscal_periods_hard_closed_by_users_id_fk" FOREIGN KEY ("hard_closed_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "fiscal_years" ADD CONSTRAINT "fiscal_years_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_batches" ADD CONSTRAINT "journal_batches_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_batches" ADD CONSTRAINT "journal_batches_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_lines" ADD CONSTRAINT "journal_lines_journal_id_journals_id_fk" FOREIGN KEY ("journal_id") REFERENCES "public"."journals"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_lines" ADD CONSTRAINT "journal_lines_account_id_accounts_id_fk" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_lines" ADD CONSTRAINT "journal_lines_department_id_departments_id_fk" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_lines" ADD CONSTRAINT "journal_lines_cost_center_id_cost_centers_id_fk" FOREIGN KEY ("cost_center_id") REFERENCES "public"."cost_centers"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_lines" ADD CONSTRAINT "journal_lines_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_lines" ADD CONSTRAINT "journal_lines_dimension_member_id_dimension_members_id_fk" FOREIGN KEY ("dimension_member_id") REFERENCES "public"."dimension_members"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journal_lines" ADD CONSTRAINT "journal_lines_currency_code_currencies_code_fk" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_branch_id_branches_id_fk" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_source_id_journal_sources_id_fk" FOREIGN KEY ("source_id") REFERENCES "public"."journal_sources"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_category_id_journal_categories_id_fk" FOREIGN KEY ("category_id") REFERENCES "public"."journal_categories"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_batch_id_journal_batches_id_fk" FOREIGN KEY ("batch_id") REFERENCES "public"."journal_batches"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_period_id_fiscal_periods_id_fk" FOREIGN KEY ("period_id") REFERENCES "public"."fiscal_periods"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_reverses_journal_id_journals_id_fk" FOREIGN KEY ("reverses_journal_id") REFERENCES "public"."journals"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_recurring_template_id_recurring_journal_templates_id_fk" FOREIGN KEY ("recurring_template_id") REFERENCES "public"."recurring_journal_templates"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_currency_code_currencies_code_fk" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "journals" ADD CONSTRAINT "journals_posted_by_users_id_fk" FOREIGN KEY ("posted_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "opening_balances" ADD CONSTRAINT "opening_balances_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "opening_balances" ADD CONSTRAINT "opening_balances_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "opening_balances" ADD CONSTRAINT "opening_balances_account_id_accounts_id_fk" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "opening_balances" ADD CONSTRAINT "opening_balances_fiscal_year_id_fiscal_years_id_fk" FOREIGN KEY ("fiscal_year_id") REFERENCES "public"."fiscal_years"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "opening_balances" ADD CONSTRAINT "opening_balances_currency_code_currencies_code_fk" FOREIGN KEY ("currency_code") REFERENCES "public"."currencies"("code") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "projects" ADD CONSTRAINT "projects_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "projects" ADD CONSTRAINT "projects_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "projects" ADD CONSTRAINT "projects_department_id_departments_id_fk" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_journal_templates" ADD CONSTRAINT "recurring_journal_templates_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "recurring_journal_templates" ADD CONSTRAINT "recurring_journal_templates_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "trial_balance_snapshots" ADD CONSTRAINT "trial_balance_snapshots_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "trial_balance_snapshots" ADD CONSTRAINT "trial_balance_snapshots_company_id_companies_id_fk" FOREIGN KEY ("company_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "trial_balance_snapshots" ADD CONSTRAINT "trial_balance_snapshots_period_id_fiscal_periods_id_fk" FOREIGN KEY ("period_id") REFERENCES "public"."fiscal_periods"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "trial_balance_snapshots" ADD CONSTRAINT "trial_balance_snapshots_account_id_accounts_id_fk" FOREIGN KEY ("account_id") REFERENCES "public"."accounts"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_account_groups_type" ON "account_groups" USING btree ("account_type_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_accounts_tenant_company_code" ON "accounts" USING btree ("tenant_id","company_id","code");--> statement-breakpoint
CREATE INDEX "idx_accounts_tenant" ON "accounts" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_accounts_company_code" ON "accounts" USING btree ("company_id","code");--> statement-breakpoint
CREATE INDEX "idx_accounts_type" ON "accounts" USING btree ("account_type_id");--> statement-breakpoint
CREATE INDEX "idx_accounts_parent" ON "accounts" USING btree ("parent_id");--> statement-breakpoint
CREATE INDEX "idx_accounts_active" ON "accounts" USING btree ("tenant_id","company_id","is_active") WHERE deleted_at IS NULL;--> statement-breakpoint
CREATE UNIQUE INDEX "uq_cost_centers_company_code" ON "cost_centers" USING btree ("company_id","code");--> statement-breakpoint
CREATE INDEX "idx_cost_centers_tenant" ON "cost_centers" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_cost_centers_company" ON "cost_centers" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_cost_centers_department" ON "cost_centers" USING btree ("department_id");--> statement-breakpoint
CREATE INDEX "idx_currency_revaluations_company" ON "currency_revaluations" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_currency_revaluations_period" ON "currency_revaluations" USING btree ("period_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_dimension_members_dim_code" ON "dimension_members" USING btree ("dimension_id","code");--> statement-breakpoint
CREATE INDEX "idx_dimension_members_dim" ON "dimension_members" USING btree ("dimension_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_dimensions_tenant_code" ON "dimensions" USING btree ("tenant_id","code");--> statement-breakpoint
CREATE INDEX "idx_dimensions_tenant" ON "dimensions" USING btree ("tenant_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_fiscal_periods_company_name" ON "fiscal_periods" USING btree ("company_id","name");--> statement-breakpoint
CREATE INDEX "idx_fiscal_periods_company_start" ON "fiscal_periods" USING btree ("company_id","start_date");--> statement-breakpoint
CREATE INDEX "idx_fiscal_periods_company_status" ON "fiscal_periods" USING btree ("company_id","status");--> statement-breakpoint
CREATE INDEX "idx_fiscal_periods_year" ON "fiscal_periods" USING btree ("fiscal_year_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_fiscal_years_company_name" ON "fiscal_years" USING btree ("company_id","name");--> statement-breakpoint
CREATE INDEX "idx_fiscal_years_company" ON "fiscal_years" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_journal_batches_company" ON "journal_batches" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_journal_lines_journal" ON "journal_lines" USING btree ("journal_id");--> statement-breakpoint
CREATE INDEX "idx_journal_lines_account" ON "journal_lines" USING btree ("account_id");--> statement-breakpoint
CREATE INDEX "idx_journal_lines_journal_account" ON "journal_lines" USING btree ("journal_id","account_id");--> statement-breakpoint
CREATE INDEX "idx_journal_lines_account_dept" ON "journal_lines" USING btree ("account_id","department_id");--> statement-breakpoint
CREATE INDEX "idx_journal_lines_cost_center" ON "journal_lines" USING btree ("cost_center_id");--> statement-breakpoint
CREATE INDEX "idx_journal_lines_project" ON "journal_lines" USING btree ("project_id");--> statement-breakpoint
CREATE INDEX "idx_journals_tenant" ON "journals" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_journals_company_period" ON "journals" USING btree ("company_id","period_id");--> statement-breakpoint
CREATE INDEX "idx_journals_company_status" ON "journals" USING btree ("company_id","status");--> statement-breakpoint
CREATE INDEX "idx_journals_period_status" ON "journals" USING btree ("period_id","status");--> statement-breakpoint
CREATE INDEX "idx_journals_entry_date" ON "journals" USING btree ("entry_date");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_opening_balances_account_year" ON "opening_balances" USING btree ("company_id","account_id","fiscal_year_id");--> statement-breakpoint
CREATE INDEX "idx_opening_balances_company" ON "opening_balances" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_opening_balances_account" ON "opening_balances" USING btree ("account_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_projects_company_code" ON "projects" USING btree ("company_id","code");--> statement-breakpoint
CREATE INDEX "idx_projects_tenant" ON "projects" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_projects_company" ON "projects" USING btree ("company_id");--> statement-breakpoint
CREATE INDEX "idx_projects_department" ON "projects" USING btree ("department_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_recurring_templates_company_code" ON "recurring_journal_templates" USING btree ("company_id","code");--> statement-breakpoint
CREATE INDEX "idx_recurring_templates_company" ON "recurring_journal_templates" USING btree ("company_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_tb_snapshots_period_account" ON "trial_balance_snapshots" USING btree ("company_id","period_id","account_id");--> statement-breakpoint
CREATE INDEX "idx_tb_snapshots_period" ON "trial_balance_snapshots" USING btree ("period_id");--> statement-breakpoint
CREATE INDEX "idx_tb_snapshots_company" ON "trial_balance_snapshots" USING btree ("company_id");