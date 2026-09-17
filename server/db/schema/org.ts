import {
  pgTable,
  uuid,
  varchar,
  text,
  boolean,
  integer,
  numeric,
  date,
  timestamp,
  jsonb,
  uniqueIndex,
  index,
  check
} from 'drizzle-orm/pg-core'
import { sql } from 'drizzle-orm'

// ==============================================================================
// 1. CURRENCIES (ISO 4217 Currency Master)
// Global reference master used across all companies and transactions
// ==============================================================================
export const currencies = pgTable(
  'currencies',
  {
    code: varchar('code', { length: 3 }).primaryKey(), // ISO 4217: 'IDR', 'USD', 'EUR', etc.
    name: varchar('name', { length: 100 }).notNull(),
    symbol: varchar('symbol', { length: 10 }).notNull(), // 'Rp', '$', '€', etc.
    decimalPlaces: integer('decimal_places').notNull().default(2),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow()
  },
  (table) => [
    check('chk_decimal_places', sql`${table.decimalPlaces} >= 0`)
  ]
)

// ==============================================================================
// 2. TENANTS (Top-level Multi-Tenant Isolation Entity, SaaS-Ready)
// Root isolation container for all organizational entities and transactions
// ==============================================================================
export const tenants = pgTable(
  'tenants',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    code: varchar('code', { length: 32 }).notNull().unique(),
    name: varchar('name', { length: 255 }).notNull(),
    plan: varchar('plan', { length: 32 }).notNull().default('standard'),
    isActive: boolean('is_active').notNull().default(true),
    settingsJson: jsonb('settings_json').notNull().default(sql`'{}'::jsonb`),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by'),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    deletedBy: uuid('deleted_by')
  },
  (table) => [
    check('chk_tenant_plan', sql`${table.plan} IN ('standard', 'professional', 'enterprise')`),
    index('idx_tenants_active').on(table.isActive).where(sql`deleted_at IS NULL`)
  ]
)

// ==============================================================================
// 3. ORGANIZATIONS (Top-Level Enterprise Entities)
// Group holding entity owning multiple legal companies
// ==============================================================================
export const organizations = pgTable(
  'organizations',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    taxId: varchar('tax_id', { length: 64 }), // Group NPWP
    baseCurrencyCode: varchar('base_currency_code', { length: 3 })
      .notNull()
      .default('IDR')
      .references(() => currencies.code),
    fiscalYearStartMonth: integer('fiscal_year_start_month').notNull().default(1),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by'),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    deletedBy: uuid('deleted_by')
  },
  (table) => [
    check(
      'chk_org_fiscal_month',
      sql`${table.fiscalYearStartMonth} BETWEEN 1 AND 12`
    ),
    uniqueIndex('uq_org_tenant_code').on(table.tenantId, table.code),
    index('idx_organizations_tenant').on(table.tenantId),
    index('idx_organizations_active')
      .on(table.tenantId, table.isActive)
      .where(sql`deleted_at IS NULL`)
  ]
)

// ==============================================================================
// 4. COMPANIES (Legal Entities / PT — Separate Tax Reporting Units)
// Operating companies with their own fiscal books and tax returns
// ==============================================================================
export const companies = pgTable(
  'companies',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    organizationId: uuid('organization_id')
      .notNull()
      .references(() => organizations.id, { onDelete: 'restrict' }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    legalName: varchar('legal_name', { length: 500 }), // Full legal registered name (e.g. 'PT GIL Accounting Indonesia')
    taxId: varchar('tax_id', { length: 64 }), // Corporate NPWP (16-digit standard)
    addressId: uuid('address_id'), // Optional FK to addresses
    baseCurrencyCode: varchar('base_currency_code', { length: 3 })
      .notNull()
      .default('IDR')
      .references(() => currencies.code),
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by'),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    deletedBy: uuid('deleted_by')
  },
  (table) => [
    uniqueIndex('uq_companies_tenant_org_code').on(
      table.tenantId,
      table.organizationId,
      table.code
    ),
    index('idx_companies_tenant').on(table.tenantId),
    index('idx_companies_org').on(table.organizationId),
    index('idx_companies_active')
      .on(table.tenantId, table.isActive)
      .where(sql`deleted_at IS NULL`)
  ]
)

// ==============================================================================
// 5. BRANCHES (Physical Operational Sites within a Company)
// Branches or plants reporting to a parent legal company
// ==============================================================================
export const branches = pgTable(
  'branches',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    isHeadOffice: boolean('is_head_office').notNull().default(false),
    addressId: uuid('address_id'), // Optional FK to addresses
    managerUserId: uuid('manager_user_id'), // Scoped branch manager
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by'),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    deletedBy: uuid('deleted_by')
  },
  (table) => [
    uniqueIndex('uq_branches_company_code').on(table.companyId, table.code),
    index('idx_branches_tenant').on(table.tenantId),
    index('idx_branches_company').on(table.companyId),
    index('idx_branches_active')
      .on(table.companyId, table.isActive)
      .where(sql`deleted_at IS NULL`)
  ]
)

// ==============================================================================
// 6. DEPARTMENTS (Hierarchical Departments for Budget Scope & Cost Centers)
// Recursive tree structure supporting department scoping and budget tracking
// ==============================================================================
export const departments = pgTable(
  'departments',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    companyId: uuid('company_id')
      .notNull()
      .references(() => companies.id, { onDelete: 'restrict' }),
    code: varchar('code', { length: 32 }).notNull(),
    name: varchar('name', { length: 255 }).notNull(),
    parentId: uuid('parent_id').references((): any => departments.id, {
      onDelete: 'restrict'
    }),
    headUserId: uuid('head_user_id'), // Department head
    costCenterId: uuid('cost_center_id'), // Optional link to cost center
    level: integer('level').notNull().default(0),
    path: text('path'), // Materialized hierarchy path (e.g. 'CORP.FIN.ACC')
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by'),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    deletedBy: uuid('deleted_by')
  },
  (table) => [
    check('chk_department_level', sql`${table.level} >= 0`),
    uniqueIndex('uq_departments_company_code').on(table.companyId, table.code),
    index('idx_departments_tenant').on(table.tenantId),
    index('idx_departments_company').on(table.companyId),
    index('idx_departments_parent').on(table.parentId),
    index('idx_departments_active')
      .on(table.companyId, table.isActive)
      .where(sql`deleted_at IS NULL`)
  ]
)

// ==============================================================================
// 7. EXCHANGE_RATES (Daily Exchange Rates with Type and Effective Period)
// Historical rate registry for multi-currency transactions and conversions
// ==============================================================================
export const exchangeRates = pgTable(
  'exchange_rates',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    tenantId: uuid('tenant_id')
      .notNull()
      .references(() => tenants.id, { onDelete: 'restrict' }),
    fromCurrency: varchar('from_currency', { length: 3 })
      .notNull()
      .references(() => currencies.code),
    toCurrency: varchar('to_currency', { length: 3 })
      .notNull()
      .references(() => currencies.code),
    rate: numeric('rate', { precision: 20, scale: 6 }).notNull(), // High-precision conversion factor
    effectiveDate: date('effective_date').notNull(),
    rateType: varchar('rate_type', { length: 32 }).notNull().default('spot'), // 'spot' | 'fiscal' | 'month_end' | 'average'
    isActive: boolean('is_active').notNull().default(true),
    createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp('updated_at', { withTimezone: true }).notNull().defaultNow(),
    createdBy: uuid('created_by'),
    updatedBy: uuid('updated_by'),
    deletedAt: timestamp('deleted_at', { withTimezone: true }),
    deletedBy: uuid('deleted_by')
  },
  (table) => [
    check('chk_rate_positive', sql`${table.rate} > 0`),
    uniqueIndex('uq_exchange_rates_daily').on(
      table.tenantId,
      table.fromCurrency,
      table.toCurrency,
      table.effectiveDate,
      table.rateType
    ),
    index('idx_exchange_rates_tenant').on(table.tenantId),
    index('idx_exchange_rates_lookup').on(
      table.fromCurrency,
      table.toCurrency,
      table.effectiveDate
    )
  ]
)
