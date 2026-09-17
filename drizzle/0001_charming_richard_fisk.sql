CREATE TABLE "permissions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"code" varchar(128) NOT NULL,
	"module" varchar(64) NOT NULL,
	"action" varchar(64) NOT NULL,
	"description" text,
	"is_sensitive" boolean DEFAULT false NOT NULL,
	CONSTRAINT "permissions_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "role_permissions" (
	"role_id" uuid NOT NULL,
	"permission_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	CONSTRAINT "role_permissions_role_id_permission_id_pk" PRIMARY KEY("role_id","permission_id")
);
--> statement-breakpoint
CREATE TABLE "roles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid,
	"code" varchar(32) NOT NULL,
	"name" varchar(255) NOT NULL,
	"description" text,
	"is_system" boolean DEFAULT false NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "roles_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "user_roles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"role_id" uuid NOT NULL,
	"department_scope_id" uuid,
	"branch_scope_id" uuid,
	"company_scope_id" uuid,
	"valid_from" date,
	"valid_to" date,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	CONSTRAINT "chk_user_roles_valid_range" CHECK ("user_roles"."valid_to" IS NULL OR "user_roles"."valid_from" IS NULL OR "user_roles"."valid_to" >= "user_roles"."valid_from")
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"tenant_id" uuid NOT NULL,
	"email" varchar(255) NOT NULL,
	"password_hash" varchar(255) NOT NULL,
	"name" varchar(255) NOT NULL,
	"primary_department_id" uuid,
	"primary_company_id" uuid,
	"is_active" boolean DEFAULT true NOT NULL,
	"is_locked" boolean DEFAULT false NOT NULL,
	"locked_until" timestamp with time zone,
	"failed_login_count" integer DEFAULT 0 NOT NULL,
	"last_login_at" timestamp with time zone,
	"password_changed_at" timestamp with time zone,
	"mfa_enabled" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"created_by" uuid,
	"updated_by" uuid,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid,
	CONSTRAINT "chk_users_failed_login_count" CHECK ("users"."failed_login_count" >= 0)
);
--> statement-breakpoint
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_role_id_roles_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "role_permissions" ADD CONSTRAINT "role_permissions_permission_id_permissions_id_fk" FOREIGN KEY ("permission_id") REFERENCES "public"."permissions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "roles" ADD CONSTRAINT "roles_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_role_id_roles_id_fk" FOREIGN KEY ("role_id") REFERENCES "public"."roles"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_department_scope_id_departments_id_fk" FOREIGN KEY ("department_scope_id") REFERENCES "public"."departments"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_branch_scope_id_branches_id_fk" FOREIGN KEY ("branch_scope_id") REFERENCES "public"."branches"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "user_roles" ADD CONSTRAINT "user_roles_company_scope_id_companies_id_fk" FOREIGN KEY ("company_scope_id") REFERENCES "public"."companies"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_tenant_id_tenants_id_fk" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_primary_department_id_departments_id_fk" FOREIGN KEY ("primary_department_id") REFERENCES "public"."departments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "users" ADD CONSTRAINT "users_primary_company_id_companies_id_fk" FOREIGN KEY ("primary_company_id") REFERENCES "public"."companies"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "idx_permissions_module" ON "permissions" USING btree ("module");--> statement-breakpoint
CREATE INDEX "idx_role_permissions_perm" ON "role_permissions" USING btree ("permission_id");--> statement-breakpoint
CREATE INDEX "idx_roles_tenant" ON "roles" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_roles_active" ON "roles" USING btree ("is_active");--> statement-breakpoint
CREATE INDEX "idx_user_roles_user" ON "user_roles" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "idx_user_roles_role" ON "user_roles" USING btree ("role_id");--> statement-breakpoint
CREATE INDEX "idx_user_roles_dept_scope" ON "user_roles" USING btree ("user_id","department_scope_id");--> statement-breakpoint
CREATE INDEX "idx_user_roles_company_scope" ON "user_roles" USING btree ("user_id","company_scope_id");--> statement-breakpoint
CREATE UNIQUE INDEX "uq_users_email" ON "users" USING btree ("email");--> statement-breakpoint
CREATE INDEX "idx_users_tenant" ON "users" USING btree ("tenant_id");--> statement-breakpoint
CREATE INDEX "idx_users_primary_dept" ON "users" USING btree ("primary_department_id");--> statement-breakpoint
CREATE INDEX "idx_users_primary_company" ON "users" USING btree ("primary_company_id");--> statement-breakpoint
CREATE INDEX "idx_users_active" ON "users" USING btree ("tenant_id","is_active") WHERE deleted_at IS NULL;